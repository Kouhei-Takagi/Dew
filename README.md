# 💧 Dew (朝露コイン)
**Human-Minted, Time-Decaying P2P Currency Protocol (PoC)**  
*Next Style: “P2P × Time-Decay Coin × Human Device” Saves the World.*

[![License](https://img.shields.io/badge/License-Apache_2.0-teal.svg)](https://opensource.org/licenses/Apache-2.0)
[![Platform](https://img.shields.io/badge/Platform-iOS_17%2B_%7C_iPadOS_17%2B_%7C_macOS_14%2B-cyan.svg)]()
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)]()

[English](#english) | [日本語](#japanese)

---

<a name="english"></a>
## 🌍 Philosophy: Why "Dew"?

The combination of **“Expanding Capital × Centralized Currency × AI (the 24/365 worker)”** is bringing our world to a dead end. As AI replaces human labor and capital compounds infinitely ($r > g$), wealth converges into the hands of a few winners. Worse, no one can opt out of this centralized game until they lose everything.

**Dew** is a working Proof-of-Concept (PoC) designed as an open exit hatch—a blueprint for the next economic paradigm based on three pillars:

| Element | Current Model (Ends the World) | Next Style: **Dew** (Saves the World) | Essence of the Shift |
| :--- | :--- | :--- | :--- |
| **Currency** | Expanding Capital (Interest & Hoarding) | **Time-Decay Coin** (Evaporating Value) | From *Monopoly* to *Circulation & Gifting* |
| **Network** | Centralized (Banks & Big Tech) | **Local P2P** (Serverless Mesh) | From *Control* to *Direct Trust & Autonomy* |
| **Value Source** | AI (Infinite 24/365 Compute) | **Human Device** (Proof of Humanity) | From *Productivity* to *Human Existence Itself* |

Like morning dew forming on a leaf, **100 DEW** is minted onto your personal device once a day simply by proving you are a living, breathing human being. If you hoard it, it evaporates as the sun rises (exponential time decay). The most rational action is to share it with someone nearby before it disappears.

---

## ✨ Key Features (MVP)

1. **⏳ Continuous Exponential Time Decay (`DewWallet.swift`)**
   - No central server or cron job needed. Balance decays purely mathematically based on elapsed time:
     $$B(t) = B_0 \times \left(\frac{1}{2}\right)^{\frac{t}{T_{1/2}}}$$
   - Includes a real-time high-precision countdown ticker (`.monospacedDigit()`) and instant toggle between **Demo Mode** ($T_{1/2} = 180\text{s}$ / 3 mins) and **Real Mode** ($T_{1/2} = 86,400\text{s}$ / 24 hours).
2. **🌱 Proof of Humanity Minting (`BiometricMinter.swift`)**
   - Powered by `LocalAuthentication` (Face ID / Touch ID).
   - Every human can mint **+100.0 DEW** once per day directly from their hardware without relying on any central issuer.
3. **📡 Zero-Server P2P Transfer (`DewP2PManager.swift`)**
   - Built on Apple's `MultipeerConnectivity` (`serviceType: "dew-p2p"`).
   - Automatically discovers and connects to nearby iPhones, iPads, and Macs over Bluetooth and peer-to-peer Wi-Fi—even in Airplane Mode with zero internet connection.

---

## 📂 Architecture

```text
Dew/
├── MyApp.swift             # App entry point
├── ContentView.swift       # Glassmorphism UI & real-time decay visualizer
├── DewWallet.swift         # Exponential time-decay calculation engine
├── BiometricMinter.swift   # Face ID / Touch ID Proof-of-Humanity minter
└── DewP2PManager.swift     # Serverless P2P discovery & payload transfer
```

🚀 Getting Started (Build Instructions)
Create a new Multiplatform or iOS App project in Xcode 15+ (SwiftUI).
Drag and drop the 5 .swift files into your project.
Add the following keys to your Info.plist (Target > Info > Custom iOS Target Properties):

<key>NSFaceIDUsageDescription</key>
<string>Used to verify Proof of Humanity and mint your daily Dew.</string>
<key>NSLocalNetworkUsageDescription</key>
<string>Used to discover nearby devices and transfer Dew directly via P2P.</string>
<key>NSBonjourServices</key>
<array>
    <string>_dew-p2p._tcp</string>
    <string>_dew-p2p._udp</string>
</array>

Build and run on two or more devices (e.g., iPhone + iPad, or Mac + Simulator) to test real-time evaporation and P2P transfers.
⚠️ Disclaimer
Dew is a conceptual, educational, and philosophical Proof-of-Concept (PoC) software experiment.
The "DEW" units displayed within this application have zero monetary value, cannot be exchanged for fiat currencies or crypto-assets, and do not constitute a financial instrument, security, or prepaid payment instrument under any jurisdiction.

🇯🇵 思想と背景：なぜ「Dew（朝露）」なのか？
「増殖を前提とした資本 × 中央集権通貨 × AI（24時間365日働く労働者）」 の掛け合わせは、世界を行き詰まらせます。AIが人間の労働を代替し、資本が複利で自己増殖し続ければ、富はごく一部の勝者に極限まで集中し、その他大勢は資産をすべて失うまでこのゲームから降りることができません。
Dew（朝露コイン） は、人々が既存のシステムの限界に気づいたとき、すぐ隣に置いてある「非常口（代替プロトコル）」として設計された概念実証（PoC）実装です。
① Time Decay Coin（時間減衰型通貨）： 時間が経つにつれて価値が蒸発（指数減衰）するため、「貯め込むこと」が損になり、「今すぐ誰かのために使う・贈与する」ことが最も合理的になります。
② P2P（自律分散ネットワーク）： 銀行や巨大テック企業のサーバーを介さず、近くにあるiPhone・iPad・Mac同士が直接つながり、インターネットすら不要で価値を交換します。   
③ Human Device（生身の人間証明）： AIには決して複製できない「生身の人間が今日という1日を生きている事実」をFace ID / Touch IDで証明し、毎日個人の端末から直接 100 DEW が湧き出ます。   

🛠 ビルドと実行手順
Xcodeで新規のSwiftUIプロジェクトを作成し、5つの .swift ファイルを配置します。   

ターゲットの Info.plist 設定に以下の3項目を追加します：
Privacy - Face ID Usage Description (NSFaceIDUsageDescription): 生身の人間であることを証明し、本日のDew（朝露コイン）を発行するために使用します。
Privacy - Local Network Usage Description (NSLocalNetworkUsageDescription): 近くのデバイスと直接P2PでDewを送受信するためにローカルネットワークを使用します。
Bonjour services (NSBonjourServices): Item 0 に _dew-p2p._tcp、Item 1 に _dew-p2p._udp を追加。
iPhoneやiPad、Macにビルドして起動すると、自動的に近くの端末を検出（service: dew-p2p）し、リアルタイムに蒸発していく朝露コインの発行とP2P送受信を体験できます。   

## Antigravity用プロンプト
```text
プロジェクト「Dew」のMVP（最小限のプロトタイプ）をSwiftUIで実装してください。
「Dew（朝露）」は、中央サーバーを介さず（P2P）、生体認証（Human Device）によって1日1回発行され、時間経過とともに価値が蒸発・減衰する（Time Decay Coin）ローカル通貨アプリです。
iPhone、iPad、Mac（Apple Silicon）間で、インターネット接続なしでも直接コインを送受信できる構成にします。

以下の4つの要件とファイル構成に従って、警告やエラーが出ないモダンなSwiftコード（Swift 5.9+ / iOS 17+ / macOS 14+ 想定）を生成・実装してください。

## 1. コア要件と仕様
1. **Time Decay（時間減衰）ロジック (`DewWallet.swift`)**
   - 残高は固定値ではなく、`baseBalance: Double`（最終更新時の残高）と `lastUpdated: Date`（最終更新時刻）で管理し、`UserDefaults` に永続化する。
   - 現在残高 `currentBalance` は、経過時間 `t` と半減期 `halfLife` を用いた指数減衰 `baseBalance * pow(0.5, t / halfLife)` でリアルタイム算出する。
   - **重要（デモ用機能）**: 画面上で「朝露が蒸発していく感覚」を視覚的にテストできるよう、半減期を「デモモード（半減期: 180秒＝3分）」と「リアルモード（半減期: 86400秒＝24時間）」でワンタップ切り替えできるようにし、画面表示は `TimelineView(.animation)` または 0.1秒周期の `Timer` で小数点以下4桁（例: `99.8421 DEW`）までリアルタイムにカウントダウン表示する。

2. **Human Device 証明による発行 (`BiometricMinter.swift`)**
   - `LocalAuthentication` フレームワークを使用。
   - 「Morning Mint (100 DEW)」ボタンを押すと Face ID / Touch ID（またはパスコード）認証を要求し、成功すると現在の減衰後残高に `+100.0 DEW` を加算して `lastUpdated` を現在時刻に更新する。
   - （プロトタイプ検証のため、1日1回制限をリセットできるデバッグボタンも用意すること）

3. **P2P 直接通信 (`DewP2PManager.swift`)**
   - `MultipeerConnectivity` フレームワークを使用（`serviceType = "dew-p2p"`）。
   - アプリ起動時に自動で `MCNearbyServiceAdvertiser` と `MCNearbyServiceBrowser` を開始し、近くにあるiPhone / iPad / Macを自動検出・自動接続する。
   - 送金データ構造 `DewTransferPayload: Codable`（送信元デバイス名、送金額 `amount: Double`、タイムスタンプ、UUID）をJSONエンコードして選択したピア（または接続中の全ピア）へ送信する。
   - 送信側は自分の残高から `amount` を即座に引き、受信側は受け取った `amount` を自分の残高に加算し、画面に「💧 Received X DEW from [Device]!」とアニメーション通知を出す。

4. **UIデザイン (`ContentView.swift`)**
   - 「朝露（Dew）」をテーマにした、透明感のある美しいグラスモーフィズム＆シアン・エメラルド系のグラデーションUI。
   - 上部：リアルタイムで減衰し続ける現在残高（大きく等幅フォント `.monospacedDigit()` で表示）と、蒸発スピード（デモ3分 / リアル24時間）の切り替えトグル。
   - 中央：「🌱 Proof of Humanity (Mint 100 DEW)」ボタン（生体認証トリガー）。
   - 下部：近くで見つかったP2Pデバイス（iPhone / iPad等）のリストと、ワンタップで「10 DEW 送る」「50 DEW 送る」を実行できる送金ボタン。

## 2. 必ず確認・設定してほしい項目（Info.plist / Entitlements）
`MultipeerConnectivity` と `Face ID` が実機でクラッシュせずに動くよう、プロジェクト設定（または `Info.plist`）に以下のキーを必ず追加・案内してください。
- `NSFaceIDUsageDescription`: "生身の人間であることを証明し、本日のDew（朝露コイン）を発行するために使用します。"
- `NSLocalNetworkUsageDescription`: "近くのデバイスと直接P2PでDewを送受信するためにローカルネットワークを使用します。"
- `NSBonjourServices`: `["_dew-p2p._tcp", "_dew-p2p._udp"]`

まずはファイル構成を作成し、すべてのコードを実装してください。
```

⚠️ 免責事項（Disclaimer）
本リポジトリのコードおよびアプリケーションは、社会思想・トークノミクス・P2P通信技術の検証を目的とした純粋な概念実証（PoC）および教育・実験用プロトタイプです。アプリ内の数値（DEW）は法定通貨や暗号資産との換金性・財産的価値を一切持たず、資金決済法上の暗号資産や前払式支払手段等には該当しません。

📜 License
Licensed under the Apache License, Version 2.0.
You may freely use, modify, and distribute this code to build autonomous communities, while patent retaliation clauses protect this concept from corporate monopolization.

#### 🤝 Acknowledgments / 謝辞
* **Conceptualization & Architecture Design:** Co-created through philosophical and technical brainstorming with **Google Gemini**.
* **Code Generation (MVP):** Implemented via **Antigravity**.

本プロトコルの思想（デュアルエコノミーの概念や時間減衰モデル）およびシステム要件は、**Google Gemini** との壁打ち（対話）の中から生まれ、**Antigravity** を通じて実装されました。「AI時代における人間のための非常口」をAIとの共創によって設計・放流した、ひとつの思考実験の記録としてここに記します。
