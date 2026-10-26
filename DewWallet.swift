import Foundation
import Observation

/// 時間減衰（Time Decay）の半減期モード
enum DecayMode: String, CaseIterable, Codable, Identifiable {
    /// デモモード（半減期: 180秒 = 3分）
    case demo
    /// リアルモード（半減期: 86,400秒 = 24時間）
    case real

    var id: String { rawValue }

    /// 半減期（秒）
    var halfLifeSeconds: TimeInterval {
        switch self {
        case .demo:
            return 180.0
        case .real:
            return 86_400.0
        }
    }

    var title: String {
        switch self {
        case .demo:
            return "デモ (半減期 3分)"
        case .real:
            return "リアル (半減期 24時間)"
        }
    }

    var subtitle: String {
        switch self {
        case .demo:
            return "180秒で価値が半分に蒸発"
        case .real:
            return "24時間(86,400秒)で価値が半分に蒸発"
        }
    }
}

/// 指数減衰するローカル通貨「Dew（朝露）」のウォレット管理クラス
@Observable
final class DewWallet {
    private enum StorageKey {
        static let baseBalance = "dew.wallet.baseBalance"
        static let lastUpdated = "dew.wallet.lastUpdated"
        static let lastMintDate = "dew.wallet.lastMintDate"
        static let decayMode = "dew.wallet.decayMode"
        static let hasInitialized = "dew.wallet.hasInitialized"
    }

    /// 最終更新時の基準残高
    private(set) var baseBalance: Double

    /// 最終更新時刻
    private(set) var lastUpdated: Date

    /// 最終発行（Morning Mint）日時（1日1回制限の判定用）
    private(set) var lastMintDate: Date?

    /// 現在の減衰モード（デモ3分 / リアル24時間）
    private(set) var decayMode: DecayMode

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let initialized = defaults.bool(forKey: StorageKey.hasInitialized)
        if initialized {
            self.baseBalance = max(0.0, defaults.double(forKey: StorageKey.baseBalance))
            let savedTimestamp = defaults.double(forKey: StorageKey.lastUpdated)
            self.lastUpdated = savedTimestamp > 0 ? Date(timeIntervalSince1970: savedTimestamp) : .now

            let mintTimestamp = defaults.double(forKey: StorageKey.lastMintDate)
            self.lastMintDate = mintTimestamp > 0 ? Date(timeIntervalSince1970: mintTimestamp) : nil

            if let modeRaw = defaults.string(forKey: StorageKey.decayMode),
               let savedMode = DecayMode(rawValue: modeRaw) {
                self.decayMode = savedMode
            } else {
                self.decayMode = .demo
            }
        } else {
            // 初回起動時は蒸発アニメーションをすぐ体験できるよう初期値 100.0 DEW をセット
            self.baseBalance = 100.0
            self.lastUpdated = .now
            self.lastMintDate = nil
            self.decayMode = .demo
            defaults.set(true, forKey: StorageKey.hasInitialized)
            persist()
        }
    }

    /// 指定時刻 `date` における指数減衰後の現在残高を算出
    /// 式: `baseBalance * pow(0.5, t / halfLife)`
    func currentBalance(at date: Date = .now) -> Double {
        guard baseBalance > 0 else { return 0.0 }
        let elapsed = max(0.0, date.timeIntervalSince(lastUpdated))
        let halfLife = decayMode.halfLifeSeconds
        let decayed = baseBalance * pow(0.5, elapsed / halfLife)
        return max(0.0, decayed)
    }

    /// 1秒あたりの現在蒸発スピード（DEW/sec）
    func decayRatePerSecond(at date: Date = .now) -> Double {
        let current = currentBalance(at: date)
        // d/dt [B * 0.5^(t/T)] = B * 0.5^(t/T) * ln(2) / T
        return current * log(2.0) / decayMode.halfLifeSeconds
    }

    /// 基準残高からの残存率（0.0 ... 1.0）
    func retentionRatio(at date: Date = .now) -> Double {
        guard baseBalance > 0 else { return 0.0 }
        let elapsed = max(0.0, date.timeIntervalSince(lastUpdated))
        return pow(0.5, elapsed / decayMode.halfLifeSeconds)
    }

    /// 減衰モード（デモ / リアル）を切り替える
    /// 切り替え時点の減衰後残高を確定させてから新しい半減期を適用する
    func setDecayMode(_ newMode: DecayMode, at date: Date = .now) {
        guard newMode != decayMode else { return }
        let snapshot = currentBalance(at: date)
        baseBalance = snapshot
        lastUpdated = date
        decayMode = newMode
        persist()
    }

    /// 残高を加算し、`lastUpdated` を現在時刻に更新する
    func add(_ amount: Double, at date: Date = .now) {
        guard amount > 0 else { return }
        let current = currentBalance(at: date)
        baseBalance = current + amount
        lastUpdated = date
        persist()
    }

    /// 送金などで残高を減算し、`lastUpdated` を現在時刻に更新する
    @discardableResult
    func deduct(_ amount: Double, at date: Date = .now) -> Bool {
        guard amount > 0 else { return false }
        let current = currentBalance(at: date)
        guard current >= amount else { return false }
        baseBalance = max(0.0, current - amount)
        lastUpdated = date
        persist()
        return true
    }

    /// 本日の Morning Mint が可能かどうか
    func canMintToday(at date: Date = .now) -> Bool {
        guard let lastMintDate else { return true }
        return !Calendar.current.isDate(lastMintDate, inSameDayAs: date)
    }

    /// 生体認証成功時に +100.0 DEW を発行して記録する
    func recordMorningMint(amount: Double = 100.0, at date: Date = .now) {
        let current = currentBalance(at: date)
        baseBalance = current + amount
        lastUpdated = date
        lastMintDate = date
        persist()
    }

    /// プロトタイプ検証用：1日1回の発行制限をリセットする
    func resetDailyMintLimit() {
        lastMintDate = nil
        defaults.removeObject(forKey: StorageKey.lastMintDate)
    }

    private func persist() {
        defaults.set(baseBalance, forKey: StorageKey.baseBalance)
        defaults.set(lastUpdated.timeIntervalSince1970, forKey: StorageKey.lastUpdated)
        if let lastMintDate {
            defaults.set(lastMintDate.timeIntervalSince1970, forKey: StorageKey.lastMintDate)
        } else {
            defaults.removeObject(forKey: StorageKey.lastMintDate)
        }
        defaults.set(decayMode.rawValue, forKey: StorageKey.decayMode)
    }
}
