import Foundation
import LocalAuthentication
import Observation

/// 生体認証（Human Device 証明）によって1日1回 Dew を発行するクラス
@Observable
final class BiometricMinter {
    enum MintStatus: Equatable {
        case idle
        case authenticating
        case minted(amount: Double, date: Date)
        case alreadyMintedToday
        case failed(String)
    }

    /// 1回あたりの発行量（100.0 DEW）
    static let morningMintAmount: Double = 100.0

    private(set) var status: MintStatus = .idle
    private(set) var biometryLabel: String = "Face ID / Touch ID"
    private(set) var biometrySymbol: String = "faceid"

    init() {
        refreshBiometryCapability()
    }

    /// デバイスが対応している生体認証の種類を判定してUI表示用ラベルを更新する
    func refreshBiometryCapability() {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        switch context.biometryType {
        case .faceID:
            biometryLabel = "Face ID"
            biometrySymbol = "faceid"
        case .touchID:
            biometryLabel = "Touch ID"
            biometrySymbol = "touchid"
        case .opticID:
            biometryLabel = "Optic ID"
            biometrySymbol = "opticid"
        case .none:
            biometryLabel = "Device Auth"
            biometrySymbol = "lock.shield"
        @unknown default:
            biometryLabel = "Biometrics"
            biometrySymbol = "faceid"
        }
    }

    /// Face ID / Touch ID（またはパスコード）認証を実行し、成功時に +100.0 DEW を発行する
    @discardableResult
    func morningMint(into wallet: DewWallet) async -> Bool {
        guard wallet.canMintToday() else {
            status = .alreadyMintedToday
            return false
        }

        status = .authenticating
        let context = LAContext()
        context.localizedCancelTitle = "キャンセル"

        let reason = "生身の人間であることを証明し、本日のDew（朝露コイン 100 DEW）を発行します。"
        var authError: NSError?

        // 生体認証（またはパスコードフォールバック）が利用可能か確認
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        if context.canEvaluatePolicy(policy, error: &authError) {
            do {
                let success = try await context.evaluatePolicy(policy, localizedReason: reason)
                if success {
                    let now = Date.now
                    wallet.recordMorningMint(amount: Self.morningMintAmount, at: now)
                    status = .minted(amount: Self.morningMintAmount, date: now)
                    return true
                } else {
                    status = .failed("認証が完了しませんでした。")
                    return false
                }
            } catch let error as LAError {
                // 生体認証がロックアウトや未登録で失敗した場合、パスコード認証へフォールバックを試みる
                if policy == .deviceOwnerAuthenticationWithBiometrics,
                   error.code != .userCancel && error.code != .systemCancel && error.code != .appCancel {
                    return await fallbackToDevicePasscode(reason: reason, wallet: wallet)
                }
                status = .failed(localizedErrorMessage(for: error))
                return false
            } catch {
                status = .failed(error.localizedDescription)
                return false
            }
        } else {
            #if targetEnvironment(simulator)
            // シミュレータで Face ID が未Enroll かつパスコード未設定の場合でもプロトタイプ検証できるようフォールバック
            try? await Task.sleep(for: .milliseconds(350))
            let now = Date.now
            wallet.recordMorningMint(amount: Self.morningMintAmount, at: now)
            status = .minted(amount: Self.morningMintAmount, date: now)
            return true
            #else
            let message = authError?.localizedDescription ?? "このデバイスでは生体認証またはパスコードが設定されていません。"
            status = .failed(message)
            return false
            #endif
        }
    }

    /// プロトタイプ検証用：1日1回制限をリセットする
    func resetDailyLimit(for wallet: DewWallet) {
        wallet.resetDailyMintLimit()
        status = .idle
    }

    private func fallbackToDevicePasscode(reason: String, wallet: DewWallet) async -> Bool {
        let fallbackContext = LAContext()
        var error: NSError?
        guard fallbackContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            status = .failed(error?.localizedDescription ?? "認証を利用できません。")
            return false
        }

        do {
            let success = try await fallbackContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if success {
                let now = Date.now
                wallet.recordMorningMint(amount: Self.morningMintAmount, at: now)
                status = .minted(amount: Self.morningMintAmount, date: now)
                return true
            } else {
                status = .failed("認証がキャンセルされました。")
                return false
            }
        } catch let laError as LAError {
            status = .failed(localizedErrorMessage(for: laError))
            return false
        } catch {
            status = .failed(error.localizedDescription)
            return false
        }
    }

    private func localizedErrorMessage(for error: LAError) -> String {
        switch error.code {
        case .userCancel, .appCancel, .systemCancel:
            return "認証がキャンセルされました。"
        case .biometryNotEnrolled:
            return "生体認証（Face ID / Touch ID）が登録されていません。"
        case .biometryNotAvailable:
            return "このデバイスでは生体認証を利用できません。"
        case .biometryLockout:
            return "生体認証がロックされています。パスコードで解除してください。"
        case .passcodeNotSet:
            return "デバイスのパスコードが設定されていません。"
        default:
            return error.localizedDescription
        }
    }
}
