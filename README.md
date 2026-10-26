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

⚠️ 免責事項（Disclaimer）
本リポジトリのコードおよびアプリケーションは、社会思想・トークノミクス・P2P通信技術の検証を目的とした純粋な概念実証（PoC）および教育・実験用プロトタイプです。アプリ内の数値（DEW）は法定通貨や暗号資産との換金性・財産的価値を一切持たず、資金決済法上の暗号資産や前払式支払手段等には該当しません。

📜 License
Licensed under the Apache License, Version 2.0.
You may freely use, modify, and distribute this code to build autonomous communities, while patent retaliation clauses protect this concept from corporate monopolization.
