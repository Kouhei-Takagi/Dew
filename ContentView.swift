import SwiftUI
import MultipeerConnectivity

struct ContentView: View {
    @State private var wallet = DewWallet()
    @State private var minter = BiometricMinter()
    @State private var p2pManager = DewP2PManager()
    @State private var pulseAnimation = false
    @State private var mintRipple = false

    var body: some View {
        ZStack(alignment: .top) {
            // 背景：朝露（Dew）のシアン＆エメラルド系ディープグラデーション＋光彩オーブ
            dewBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 22) {
                    headerBar

                    // 1. 上部：リアルタイム減衰する現在残高 ＆ 半減期切り替えトグル
                    TimelineView(.animation(minimumInterval: 0.05)) { timeline in
                        balanceCard(at: timeline.date)
                    }

                    // 2. 中央：🌱 Proof of Humanity (Mint 100 DEW) 生体認証発行セクション
                    proofOfHumanityCard

                    // 3. 下部：近くのP2Pデバイスリスト ＆ ワンタップ送金ボタン
                    p2pTransferCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 36)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }

            // 受信時のアニメーション通知バナー ("💧 Received X DEW from [Device]!")
            if let payload = p2pManager.receivedBannerPayload {
                receivedNotificationBanner(payload: payload)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.92)))
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: p2pManager.receivedBannerPayload)
        .onAppear {
            p2pManager.bind(wallet: wallet)
            minter.refreshBiometryCapability()
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Ambient Dew Background

    private var dewBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.11, blue: 0.16),
                    Color(red: 0.03, green: 0.20, blue: 0.24),
                    Color(red: 0.02, green: 0.14, blue: 0.18),
                    Color(red: 0.01, green: 0.07, blue: 0.11)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 朝露の光の滲み（シアン＆エメラルド）
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.cyan.opacity(0.32),
                            Color.teal.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 220
                    )
                )
                .frame(width: 420, height: 420)
                .offset(x: pulseAnimation ? -90 : -130, y: pulseAnimation ? -180 : -220)
                .blur(radius: 20)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.mint.opacity(0.28),
                            Color.green.opacity(0.06),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 240
                    )
                )
                .frame(width: 440, height: 440)
                .offset(x: pulseAnimation ? 120 : 150, y: pulseAnimation ? 180 : 130)
                .blur(radius: 24)
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)
                    .shadow(color: .cyan.opacity(0.45), radius: 10, y: 3)

                Image(systemName: "drop.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Dew")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("朝露コイン")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.cyan.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.cyan.opacity(0.45), lineWidth: 1)
                                )
                        )
                        .foregroundStyle(.cyan)
                }

                Text("Human-Minted • Time-Decaying P2P Currency")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            // P2P 稼働インジケータ
            HStack(spacing: 6) {
                Circle()
                    .fill(p2pManager.connectedPeers.isEmpty ? Color.cyan : Color.mint)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulseAnimation ? 1.25 : 0.85)

                Text(p2pManager.connectedPeers.isEmpty ? "P2P 探索中" : "\(p2pManager.connectedPeers.count)台 接続中")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - 1. Time Decay Balance Card

    private func balanceCard(at date: Date) -> some View {
        let balance = wallet.currentBalance(at: date)
        let decayPerSec = wallet.decayRatePerSecond(at: date)
        let retention = wallet.retentionRatio(at: date)
        let elapsedSeconds = max(0, Int(date.timeIntervalSince(wallet.lastUpdated)))

        return VStack(spacing: 18) {
            HStack {
                Label("リアルタイム残高 (Time Decay)", systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.cyan)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption2)
                    Text("経過 \(formatElapsed(elapsedSeconds))")
                        .font(.caption2.monospacedDigit())
                }
                .foregroundStyle(.white.opacity(0.7))
            }

            // 小数点以下4桁・等幅フォントのリアルタイム減衰カウンター
            VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(String(format: "%.4f", balance))
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 0.72, green: 0.98, blue: 0.95)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .cyan.opacity(0.35), radius: 12, y: 4)
                        .contentTransition(.numericText(countsDown: true))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    Text("DEW")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(.mint)
                }

                HStack(spacing: 14) {
                    Label(
                        String(format: "-%.5f DEW/s 蒸発中", decayPerSec),
                        systemImage: "humidity.fill"
                    )
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.mint.opacity(0.9))

                    Text("•")
                        .foregroundStyle(.white.opacity(0.35))

                    Text(String(format: "残存率 %.2f%%", retention * 100.0))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(.vertical, 6)

            // 蒸発ゲージ
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.10))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .mint, .teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * min(1.0, max(0.0, retention))))
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("基準残高: \(String(format: "%.2f", wallet.baseBalance)) DEW")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.6))

                    Spacer()

                    Text(wallet.decayMode.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.cyan.opacity(0.85))
                }
            }

            Divider()
                .overlay(.white.opacity(0.15))

            // 蒸発スピード（デモ3分 / リアル24時間）ワンタップ切り替えトグル
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .foregroundStyle(.cyan)
                    Text("蒸発スピード（半減期モード切替）")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                }

                HStack(spacing: 10) {
                    ForEach(DecayMode.allCases) { mode in
                        let isSelected = wallet.decayMode == mode
                        Button {
                            withAnimation(.snappy) {
                                wallet.setDecayMode(mode)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: mode == .demo ? "bolt.fill" : "sun.horizon.fill")
                                    .font(.caption.weight(.bold))
                                Text(mode.title)
                                    .font(.caption.weight(.bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        isSelected
                                            ? LinearGradient(
                                                colors: [.cyan.opacity(0.85), .mint.opacity(0.75)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            : LinearGradient(
                                                colors: [.white.opacity(0.08), .white.opacity(0.04)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(
                                        isSelected ? Color.white.opacity(0.6) : Color.white.opacity(0.15),
                                        lineWidth: 1
                                    )
                            )
                            .foregroundStyle(isSelected ? Color(red: 0.01, green: 0.12, blue: 0.15) : .white.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(22)
        .background(glassCardBackground)
    }

    // MARK: - 2. Proof of Humanity (Biometric Mint) Card

    private var proofOfHumanityCard: some View {
        let canMint = wallet.canMintToday()

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Human Device 証明発行", systemImage: minter.biometrySymbol)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)

                Spacer()

                Text(canMint ? "本日未発行 (利用可能)" : "本日発行済み ✓")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(canMint ? Color.mint.opacity(0.22) : Color.white.opacity(0.12))
                    )
                    .foregroundStyle(canMint ? .mint : .white.opacity(0.7))
            }

            Text("生身の人間であることを \(minter.biometryLabel) で証明し、1日1回 100.0 DEW の朝露を受け取ります。")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))

            // メイン発行ボタン：「🌱 Proof of Humanity (Mint 100 DEW)」
            Button {
                Task {
                    let succeeded = await minter.morningMint(into: wallet)
                    if succeeded {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            mintRipple.toggle()
                        }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    if minter.status == .authenticating {
                        ProgressView()
                            .tint(Color(red: 0.01, green: 0.14, blue: 0.16))
                    } else {
                        Image(systemName: canMint ? minter.biometrySymbol : "checkmark.seal.fill")
                            .font(.title3.weight(.bold))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("🌱 Proof of Humanity (Mint 100 DEW)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Text(canMint ? "Morning Mint: \(minter.biometryLabel) で +100.0 DEW を発行" : "本日の Morning Mint は完了しています")
                            .font(.caption2.weight(.medium))
                            .opacity(0.85)
                    }

                    Spacer()

                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            canMint
                                ? LinearGradient(
                                    colors: [
                                        Color(red: 0.20, green: 0.94, blue: 0.82),
                                        Color(red: 0.12, green: 0.80, blue: 0.92)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.14), Color.white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .shadow(color: canMint ? .mint.opacity(0.38) : .clear, radius: 12, y: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(canMint ? 0.55 : 0.18), lineWidth: 1)
                )
                .foregroundStyle(canMint ? Color(red: 0.01, green: 0.13, blue: 0.16) : .white.opacity(0.6))
            }
            .buttonStyle(.plain)
            .disabled(!canMint || minter.status == .authenticating)

            // ステータスメッセージ＆プロトタイプ検証用リセットボタン
            HStack(spacing: 10) {
                statusBadgeView

                Spacer()

                // 1日1回制限をリセットできるデバッグボタン
                Button {
                    withAnimation(.snappy) {
                        minter.resetDailyLimit(for: wallet)
                    }
                } label: {
                    Label("1日1回制限をリセット (Debug)", systemImage: "arrow.counterclockwise")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.10))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.cyan.opacity(0.4), lineWidth: 1)
                                )
                        )
                        .foregroundStyle(.cyan)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(glassCardBackground)
    }

    @ViewBuilder
    private var statusBadgeView: some View {
        switch minter.status {
        case .idle:
            if let lastMint = wallet.lastMintDate {
                Text("最終発行: \(lastMint.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.65))
            } else {
                Text("生体認証で即時発行可能")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.65))
            }
        case .authenticating:
            Text("生体認証を確認中...")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.cyan)
        case .minted(let amount, _):
            Text("✨ +\(Int(amount)) DEW 発行完了！")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.mint)
        case .alreadyMintedToday:
            Text("本日は発行済みです（右のボタンでリセット可）")
                .font(.caption2)
                .foregroundStyle(.yellow.opacity(0.9))
        case .failed(let message):
            Text(message)
                .font(.caption2)
                .foregroundStyle(.orange)
                .lineLimit(2)
        }
    }

    // MARK: - 3. P2P Direct Transfer Card

    private var p2pTransferCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("近くのP2Pデバイス (Multipeer)", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    p2pManager.restartNetworking()
                } label: {
                    Label("再スキャン", systemImage: "arrow.clockwise")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.10), in: Capsule())
                        .foregroundStyle(.cyan)
                }
                .buttonStyle(.plain)
            }

            // 自デバイス情報 & 最新P2Pステータス
            HStack(spacing: 8) {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .foregroundStyle(.mint)
                Text("このデバイス: \(p2pManager.localDeviceName)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Text("service: \(DewP2PManager.serviceType)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white.opacity(0.06))
            )

            // 検出されたデバイス一覧
            if p2pManager.discoveredPeers.isEmpty {
                emptyPeerPlaceholder
            } else {
                VStack(spacing: 10) {
                    ForEach(p2pManager.discoveredPeers) { peerInfo in
                        peerRow(peerInfo)
                    }
                }
            }

            Divider()
                .overlay(.white.opacity(0.15))

            // 選択したピア（または接続中の全ピア）へのワンタップ送金ボタン
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(targetRecipientDescription)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))

                    Spacer()

                    if p2pManager.selectedPeerID != nil {
                        Button("全ピア対象に戻す") {
                            p2pManager.selectedPeerID = nil
                        }
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 12) {
                    quickSendButton(amount: 10, icon: "drop.fill")
                    quickSendButton(amount: 50, icon: "drop.circle.fill")
                }

                // ステータス & 1台でも受信通知アニメーションを確認できるデモボタン
                HStack {
                    Text(p2pManager.lastStatusMessage)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(2)

                    Spacer()

                    Button {
                        p2pManager.simulateIncomingDew(
                            amount: 10.0,
                            from: "Dew Peer (Demo)",
                            into: wallet
                        )
                    } label: {
                        Label("受信テスト (+10)", systemImage: "sparkles.tv")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.mint.opacity(0.16))
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.mint.opacity(0.45), lineWidth: 1)
                                    )
                            )
                            .foregroundStyle(.mint)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(glassCardBackground)
    }

    private var emptyPeerPlaceholder: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(.cyan)
                Text("近くの iPhone / iPad / Mac を自動検出・自動接続しています...")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Text("Wi-Fi または Bluetooth をオンにした状態で、別デバイスの Dew アプリを開くと自動接続されます。")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                )
        )
    }

    private func peerRow(_ peerInfo: DewPeerInfo) -> some View {
        let isSelected = p2pManager.selectedPeerID == peerInfo.peerID

        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    if peerInfo.isConnected {
                        p2pManager.selectedPeerID = (isSelected ? nil : peerInfo.peerID)
                    } else {
                        p2pManager.connect(to: peerInfo.peerID)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: iconName(for: peerInfo.platformHint))
                            .font(.title3)
                            .foregroundStyle(peerInfo.isConnected ? .mint : .cyan)
                            .frame(width: 34, height: 34)
                            .background(.white.opacity(0.10), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(peerInfo.displayName)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(peerInfo.isConnected ? Color.mint : Color.orange)
                                    .frame(width: 6, height: 6)
                                Text(peerInfo.stateLabel)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.7))
                                if isSelected {
                                    Text("• 選択中")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.cyan)
                                }
                            }
                        }

                        Spacer()
                    }
                }
                .buttonStyle(.plain)

                if peerInfo.isConnected {
                    HStack(spacing: 6) {
                        Button {
                            p2pManager.sendDew(amount: 10, to: peerInfo.peerID, using: wallet)
                        } label: {
                            Text("10 DEW 送る")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(Color.cyan.opacity(0.25))
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(Color.cyan.opacity(0.6), lineWidth: 1)
                                        )
                                )
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)

                        Button {
                            p2pManager.sendDew(amount: 50, to: peerInfo.peerID, using: wallet)
                        } label: {
                            Text("50 DEW 送る")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(Color.mint.opacity(0.28))
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(Color.mint.opacity(0.65), lineWidth: 1)
                                        )
                                )
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button {
                        p2pManager.connect(to: peerInfo.peerID)
                    } label: {
                        Text("接続")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.14), in: Capsule())
                            .foregroundStyle(.cyan)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? Color.cyan.opacity(0.16) : Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.cyan.opacity(0.65) : Color.white.opacity(0.15),
                            lineWidth: 1
                        )
                )
        )
    }

    private func quickSendButton(amount: Double, icon: String) -> some View {
        let hasConnectedPeer = !p2pManager.connectedPeers.isEmpty

        return Button {
            p2pManager.sendDew(amount: amount, to: p2pManager.selectedPeerID, using: wallet)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                Text("\(Int(amount)) DEW 送る")
                    .font(.subheadline.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        hasConnectedPeer
                            ? LinearGradient(
                                colors: [
                                    Color.cyan.opacity(0.80),
                                    Color.teal.opacity(0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.10), Color.white.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(hasConnectedPeer ? 0.5 : 0.15), lineWidth: 1)
            )
            .foregroundStyle(hasConnectedPeer ? .white : .white.opacity(0.45))
        }
        .buttonStyle(.plain)
        .disabled(!hasConnectedPeer)
    }

    private var targetRecipientDescription: String {
        if let selected = p2pManager.selectedPeerID {
            return "送金先: \(selected.displayName)"
        } else if !p2pManager.connectedPeers.isEmpty {
            return "送金先: 接続中の全ピア (\(p2pManager.connectedPeers.count)台)"
        } else {
            return "送金先: P2Pピア接続待ち"
        }
    }

    // MARK: - Received Notification Banner

    private func receivedNotificationBanner(payload: DewTransferPayload) -> some View {
        let formattedAmount = payload.amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", payload.amount)
            : String(format: "%.2f", payload.amount)

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)

                Image(systemName: "drop.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("💧 Received \(formattedAmount) DEW from \(payload.senderDeviceName)!")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)

                Text("P2P Direct Transfer • 残高へ即時加算されました")
                    .font(.caption2)
                    .foregroundStyle(.mint)
            }

            Spacer()

            Button {
                p2pManager.dismissBanner()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.28), Color.mint.opacity(0.22)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.7), .cyan.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: .cyan.opacity(0.35), radius: 18, y: 8)
        )
    }

    // MARK: - Shared Styling & Helpers

    private var glassCardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.10),
                                Color.cyan.opacity(0.05),
                                Color.mint.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.38),
                                Color.cyan.opacity(0.22),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
    }

    private func formatElapsed(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return String(format: "%d分%02d秒", minutes, seconds)
        } else {
            return String(format: "%d秒", seconds)
        }
    }

    private func iconName(for platformHint: String?) -> String {
        switch platformHint {
        case "iPad":
            return "ipad.gen2"
        case "Mac":
            return "macbook"
        case "Vision Pro":
            return "visionpro"
        default:
            return "iphone.gen3"
        }
    }
}

#Preview {
    ContentView()
}
