import Foundation
import MultipeerConnectivity
import Observation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// P2P 送金時に送受信される JSON ペイロード構造体
struct DewTransferPayload: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let senderDeviceName: String
    let amount: Double
    let timestamp: Date

    init(
        id: UUID = UUID(),
        senderDeviceName: String,
        amount: Double,
        timestamp: Date = .now
    ) {
        self.id = id
        self.senderDeviceName = senderDeviceName
        self.amount = amount
        self.timestamp = timestamp
    }
}

/// 検出された近隣ピアの状態モデル
struct DewPeerInfo: Identifiable, Equatable {
    let peerID: MCPeerID
    var state: MCSessionState
    var platformHint: String?

    var id: String { peerID.displayName }
    var displayName: String { peerID.displayName }

    var stateLabel: String {
        switch state {
        case .connected:
            return "接続済み"
        case .connecting:
            return "接続中..."
        case .notConnected:
            return "検出済み"
        @unknown default:
            return "不明"
        }
    }

    var isConnected: Bool {
        state == .connected
    }
}

/// MultipeerConnectivity を用いた P2P 自動検出・直接送金マネージャ
@Observable
final class DewP2PManager: NSObject {
    static let serviceType = "dew-p2p"

    /// 自デバイスの表示名
    let localDeviceName: String

    /// 検出されたピア一覧（接続済み・接続中を含む）
    private(set) var discoveredPeers: [DewPeerInfo] = []

    /// 現在接続が完了しているピア一覧
    var connectedPeers: [MCPeerID] {
        discoveredPeers.filter(\.isConnected).map(\.peerID)
    }

    /// 選択中の送金先ピア（nil の場合は接続中の全ピアへ送信）
    var selectedPeerID: MCPeerID?

    /// P2P 探索・アドバタイズ稼働中フラグ
    private(set) var isNetworkingActive: Bool = false

    /// 最新の送受信ステータスメッセージ
    private(set) var lastStatusMessage: String = "近くのデバイスを自動探索中..."

    /// 受信時に画面上部に表示するアニメーション通知ペイロード
    private(set) var receivedBannerPayload: DewTransferPayload?

    /// 直近の送受信ログ（UI表示用）
    private(set) var recentTransfers: [DewTransferPayload] = []

    private let myPeerID: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser
    private var browser: MCNearbyServiceBrowser
    private weak var wallet: DewWallet?
    private var bannerDismissTask: Task<Void, Never>?

    init(wallet: DewWallet? = nil) {
        self.wallet = wallet

        let resolvedName = Self.resolveDeviceName()
        self.localDeviceName = resolvedName
        let peerID = MCPeerID(displayName: resolvedName)
        self.myPeerID = peerID

        let session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        self.session = session

        let discoveryInfo: [String: String] = [
            "platform": Self.platformName(),
            "app": "Dew"
        ]
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: discoveryInfo,
            serviceType: Self.serviceType
        )
        self.browser = MCNearbyServiceBrowser(
            peer: peerID,
            serviceType: Self.serviceType
        )

        super.init()

        self.session.delegate = self
        self.advertiser.delegate = self
        self.browser.delegate = self

        startNetworking()
    }

    /// ウォレット参照を紐付ける
    func bind(wallet: DewWallet) {
        self.wallet = wallet
    }

    /// P2P アドバタイズとブラウジングを開始する
    func startNetworking() {
        guard !isNetworkingActive else { return }
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
        isNetworkingActive = true
        lastStatusMessage = "P2Pレーダー稼働中 (\(localDeviceName))"
    }

    /// P2P 通信を停止する
    func stopNetworking() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        isNetworkingActive = false
        lastStatusMessage = "P2P通信を停止しました"
    }

    /// P2P セッションを再起動して再探索する
    func restartNetworking() {
        stopNetworking()
        discoveredPeers.removeAll()
        selectedPeerID = nil
        startNetworking()
    }

    /// 未接続のピアへ手動で再招待を送る
    func connect(to peer: MCPeerID) {
        guard peer != myPeerID else { return }
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 15)
        updatePeerState(peer, state: .connecting)
    }

    /// 指定したピア（または接続中の全ピア）へ Dew を直接送金する
    @discardableResult
    func sendDew(amount: Double, to targetPeer: MCPeerID? = nil, using wallet: DewWallet) -> Bool {
        guard amount > 0 else { return false }

        let recipients: [MCPeerID]
        if let targetPeer {
            guard session.connectedPeers.contains(targetPeer) else {
                lastStatusMessage = "\(targetPeer.displayName) はまだ接続が完了していません。"
                connect(to: targetPeer)
                return false
            }
            recipients = [targetPeer]
        } else if let selectedPeerID, session.connectedPeers.contains(selectedPeerID) {
            recipients = [selectedPeerID]
        } else {
            recipients = session.connectedPeers
        }

        guard !recipients.isEmpty else {
            lastStatusMessage = "送信先のP2Pデバイスが接続されていません。"
            return false
        }

        // 送信側の残高から即座に差し引く
        guard wallet.deduct(amount) else {
            lastStatusMessage = "残高不足のため \(Int(amount)) DEW を送金できません。"
            return false
        }

        let payload = DewTransferPayload(
            senderDeviceName: localDeviceName,
            amount: amount,
            timestamp: .now
        )

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(payload)
            try session.send(data, toPeers: recipients, with: .reliable)

            let targetNames = recipients.map(\.displayName).joined(separator: ", ")
            let formatted = String(format: "%.1f", amount)
            lastStatusMessage = "✨ \(targetNames) へ \(formatted) DEW を送信しました！"
            return true
        } catch {
            // 送信失敗時は差し引いた残高をロールバック
            wallet.add(amount)
            lastStatusMessage = "送信エラー: \(error.localizedDescription)"
            return false
        }
    }

    /// デモ・単体検証用：近隣デバイスからの着金演出と残高加算をシミュレートする
    func simulateIncomingDew(amount: Double = 10.0, from senderName: String = "Nearby iPhone", into wallet: DewWallet) {
        let payload = DewTransferPayload(
            senderDeviceName: senderName,
            amount: amount,
            timestamp: .now
        )
        handleIncomingPayload(payload, wallet: wallet)
    }

    /// 受信通知バナーを手動で閉じる
    func dismissBanner() {
        bannerDismissTask?.cancel()
        receivedBannerPayload = nil
    }

    // MARK: - Internal Helpers

    private func handleIncomingPayload(_ payload: DewTransferPayload, wallet: DewWallet?) {
        let targetWallet = wallet ?? self.wallet
        targetWallet?.add(payload.amount)

        recentTransfers.insert(payload, at: 0)
        if recentTransfers.count > 10 {
            recentTransfers.removeLast()
        }

        let formatted = payload.amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", payload.amount)
            : String(format: "%.2f", payload.amount)
        lastStatusMessage = "💧 Received \(formatted) DEW from \(payload.senderDeviceName)!"
        receivedBannerPayload = payload

        bannerDismissTask?.cancel()
        bannerDismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(4.0))
            guard !Task.isCancelled else { return }
            if self?.receivedBannerPayload?.id == payload.id {
                self?.receivedBannerPayload = nil
            }
        }
    }

    private func updatePeerState(_ peerID: MCPeerID, state: MCSessionState, platformHint: String? = nil) {
        if let index = discoveredPeers.firstIndex(where: { $0.peerID == peerID }) {
            discoveredPeers[index].state = state
            if let platformHint {
                discoveredPeers[index].platformHint = platformHint
            }
        } else {
            discoveredPeers.append(
                DewPeerInfo(peerID: peerID, state: state, platformHint: platformHint)
            )
        }

        if selectedPeerID == nil, state == .connected {
            selectedPeerID = peerID
        } else if selectedPeerID == peerID, state == .notConnected {
            selectedPeerID = connectedPeers.first
        }
    }

    private func removePeer(_ peerID: MCPeerID) {
        discoveredPeers.removeAll { $0.peerID == peerID }
        if selectedPeerID == peerID {
            selectedPeerID = connectedPeers.first
        }
    }

    private static func resolveDeviceName() -> String {
        let shortTagKey = "dew.p2p.deviceShortTag"
        let shortTag: String
        if let saved = UserDefaults.standard.string(forKey: shortTagKey), !saved.isEmpty {
            shortTag = saved
        } else {
            let generated = String(UUID().uuidString.prefix(4)).uppercased()
            UserDefaults.standard.set(generated, forKey: shortTagKey)
            shortTag = generated
        }

        #if canImport(UIKit)
        let baseName = UIDevice.current.name
        return "\(baseName) • \(shortTag)"
        #elseif canImport(AppKit)
        let host = Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        return "\(host) • \(shortTag)"
        #else
        return "Apple Device • \(shortTag)"
        #endif
    }

    private static func platformName() -> String {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return "iPad"
        }
        return "iPhone"
        #elseif os(macOS)
        return "Mac"
        #elseif os(visionOS)
        return "Vision Pro"
        #else
        return "Apple Device"
        #endif
    }
}

// MARK: - MCSessionDelegate
extension DewP2PManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            self.updatePeerState(peerID, state: state)
            switch state {
            case .connected:
                self.lastStatusMessage = "🔗 \(peerID.displayName) とP2P接続しました"
            case .connecting:
                self.lastStatusMessage = "⏳ \(peerID.displayName) と接続中..."
            case .notConnected:
                self.lastStatusMessage = "\(peerID.displayName) との接続が解除されました"
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let payload = try decoder.decode(DewTransferPayload.self, from: data)
                self.handleIncomingPayload(payload, wallet: self.wallet)
            } catch {
                self.lastStatusMessage = "受信データの解析に失敗しました: \(error.localizedDescription)"
            }
        }
    }

    nonisolated func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {}

    nonisolated func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {}

    nonisolated func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: (any Error)?
    ) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension DewP2PManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Task { @MainActor in
            self.updatePeerState(peerID, state: .connecting)
            invitationHandler(true, self.session)
        }
    }

    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: any Error
    ) {
        let errorDescription = error.localizedDescription
        Task { @MainActor in
            self.lastStatusMessage = "P2P発信エラー: \(errorDescription)"
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension DewP2PManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        let platform = info?["platform"]
        Task { @MainActor in
            guard peerID != self.myPeerID else { return }
            let alreadyConnected = self.session.connectedPeers.contains(peerID)
            self.updatePeerState(
                peerID,
                state: alreadyConnected ? .connected : .connecting,
                platformHint: platform
            )
            if !alreadyConnected {
                browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 15)
            }
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            if !self.session.connectedPeers.contains(peerID) {
                self.removePeer(peerID)
            }
        }
    }

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: any Error
    ) {
        let errorDescription = error.localizedDescription
        Task { @MainActor in
            self.lastStatusMessage = "P2P探索エラー: \(errorDescription)"
        }
    }
}
