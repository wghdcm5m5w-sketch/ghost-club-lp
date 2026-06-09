# TetsuLog

> 鉄道の、すべてを、図鑑にする。
> Apple純正技術だけで作る、完全無料運用・プライバシー第一のガチ鉄向けライフログ。

このリポジトリは、鉄道趣味アプリ **TetsuLog** の企画・調査・LP・設計・実装骨格・法務・ストア素材を一式管理しています。「最強の鉄オタが作る、鉄オタのための最高品質アプリ」を、個人開発・追加コストゼロ（Apple Developer年会費のみ）で形にするための全資産です。

---

## 🎯 コンセプト

| 原則 | 内容 |
|---|---|
| **完全無料運用** | 開発者の固定費は Apple Developer 年会費(11,800円)のみ。サーバーを持たず、データはユーザーのiCloudへ |
| **プライバシー第一** | 運営者はユーザーデータにアクセスできない設計。広告・追跡・サブスクなし |
| **Apple純正で高品質** | SwiftUI / SwiftData / CloudKit / VisionKit / MapKit / ActivityKit で大手も真似しにくいOS統合体験 |

キャッチコピー: **「キャラを買うんじゃなく、自分の鉄道人生を記録する」**

---

## 📂 リポジトリ構成

```
ghost-club-lp/
├── README.md                      ← このファイル（プロジェクト全体の入口）
│
├── tetsulog.html                  ← ランディングページ（11機能・完成）
├── tetsulog-privacy.html          ← プライバシーポリシー
├── tetsulog-terms.html            ← 利用規約
├── tetsulog-tokushoho.html        ← 特定商取引法に基づく表記
│
├── docs/
│   ├── HANDOFF.md                 ← ★ プロジェクト全体の到達点とハンドオフ
│   ├── release-checklist.md       ← ★ リリース全工程の決定版チェックリスト
│   ├── run-on-device.md           ← 実機インストール手順（無料ID〜本番）
│   ├── build-troubleshooting.md   ← ビルド時の落とし穴と対処
│   ├── market-analysis.md         ← App Store鉄道アプリ市場分析（企画根拠）
│   ├── tetsulog-spec.md           ← 技術設計書（実装の青写真）
│   ├── app-store-assets.md        ← ストア掲載素材（説明文・キーワード・申告）
│   ├── accessibility-audit.md     ← WCAGコントラスト監査と是正
│   ├── critical-review*.md        ← 3次にわたる辛口レビューと是正記録
│   └── final-integrity-review.md  ← 整合性総点検の記録
│
└── app/                           ← iOSアプリ実装（Swift・52ファイル / 約6,200行）
    ├── TetsuLog.xcodeproj         Xcodeプロジェクト同梱（最小構成・本体のみ）
    ├── project.yml                xcodegen用（Widget/Watch/Tests込み）
    ├── README.md                  Xcodeセットアップ手順
    ├── TetsuLog/                  本体ターゲット
    │   ├── Models/                SwiftData モデル・シード・共有ストア
    │   ├── Views/                 5タブUI・記録入力・乗車セッション・課金・硬券
    │   ├── Features/              OCR・順光・ライブ・接近・Siri・音鉄・CSV・課金
    │   ├── Design/                Theme・PaperCard・FormStyle・ProGate
    │   ├── Resources/             多言語(.xcstrings)・形式/撮影地JSON
    │   ├── Configuration/         StoreKit テスト設定
    │   └── PrivacyInfo.xcprivacy  プライバシーマニフェスト
    ├── TetsuLogWidgets/           ウィジェット・ライブアクティビティ（国鉄レトロ）
    ├── TetsuLogWatch/             Apple Watch コンパニオン
    └── TetsuLogTests/             ユニットテスト35件（純粋関数）

（※ index.html / privacy.html 等は本リポジトリの前身 GHOST CLUB LP の資産）
```

---

## 🚆 機能（LP掲載の11本柱・すべて骨格実装済み）

| # | 機能 | 概要 | 実装 |
|---|---|---|---|
| 1 | 図鑑 | 編成番号レベルで車両を個体収集（編成/号機/車番を区別） | `CollectionView` |
| 2 | OCR (Pro) | 写真から編成番号を端末内で自動読み取り | `FormationScannerView` / `FormationNumberParser` |
| 3 | 地図 | 遭遇地点・撮影地・廃線オーバーレイ | `MapTabView` |
| 4 | 順光計算 (Pro) | 太陽方位から順光/逆光を判定 | `SunCalculator`（NOAA算法）/ `SpotDetailView` |
| 5 | タイムライン | 記録から鉄道人生を年表化（編集・削除可） | `LogView` |
| 6 | 廃線 | 過去の路線を地図に重ね合わせ | `PolylineCodec` + `MapTabView` |
| 7 | ライブアクティビティ | 乗車中をDynamic Island/ロック画面に | `RideActivityAttributes` / `RideLiveActivity` |
| 8 | 接近リマインダー | 狙いの編成をGPS×位置で思い出させる | `ApproachMonitor` |
| 9 | 統計 | 累計距離/Top形式・路線・駅/月別推移/ラストラン集計 | `StatsView` / `Statistics` |
| 10 | 音鉄 (Pro) | 走行音・駅メロ・車内放送を遭遇に添付（端末内） | `AudioRecorderView` / `AudioPlayerView` / `AudioStore` |
| 11 | 硬券シェア | 遭遇記録を厚紙きっぷ風画像でSNS共有 | `ShareCardView` / `TicketCard` |

加えて: 記録の編集・削除 / 検索 / 形式・編成のユーザー追加 / JSON書き出し・読み込み / **CSV取り込み（他サービスから移行）** /
ウィジェット / Spotlight / Siri(App Intents) / **Apple Watchコンパニオン**（今週遭遇数・最後の遭遇・クイック記録） /
**全国20有名撮影地のプリセット**（東十条S字・函南鉄橋・下灘駅・姨捨スイッチバック等、座標＋順光方位入り） / 多言語(日英中韓) /
**StoreKit 2 課金**（無料層 + Pro ¥980 買い切り）/ **プライバシーマニフェスト**（Data Not Collected）。

---

## 🧭 意図的に「作らない」もの

無料運用・個人開発・プライバシー第一の3制約を守るため、以下は実装しない：

- ユーザー間SNS・マッチング（モデレーション負荷）
- 走行音アップロード・共有（権利処理）
- リアルタイム在線監視・全国列車位置（サーバー必須・公式API非公開）
- ライブカメラ統合（配信契約）
- 広告・行動解析SDK（プライバシー方針と矛盾）

---

## 🗺 開発ロードマップ

| Ver | スコープ | 状態 |
|---|---|---|
| v1.0 | 図鑑・記録・地図・タイムライン・CloudKit同期 | ✅ 実装済み |
| v1.1 | OCR・ウィジェット・Spotlight・共有シート | ✅ 実装済み |
| v1.2 | 順光計算・廃線・Siri・ライブアクティビティ | ✅ 実装済み |
| v1.3 | 接近アラート・Apple Watch・多言語 | ✅ 実装済み |
| v1.4 | 音鉄録音・CSV移行・撮影地プリセット・記録編集 | ✅ 実装済み |
| v1.5 | 国鉄レトロUI全面刷新・紙テクスチャ・経年表現 | ✅ 実装済み |
| v1.6 | StoreKit課金・Pro/無料ゲート・プライバシーマニフェスト | ✅ 実装済み |
| v1.7 | 硬券シェア・WCAG準拠コントラスト | ✅ 実装済み |
| 公開 | 実機ビルド・識別子置換・スクショ・審査提出 | 準備完了 |

---

## ✅ 公開前チェックリスト

詳細な全工程は **[`docs/release-checklist.md`](docs/release-checklist.md)** を真実として参照。
最低限のサマリ：

- [ ] 全プレースホルダを実値に（`yourname` / `com.example` / `example.github.io` / `support@example.com` / 事業者情報）
- [ ] Widget / Watch / Tests ターゲットをXcodeで追加（同梱フォルダから）
- [ ] iCloud / CloudKit / App Groups / Push の Capabilities 設定
- [ ] App Store Connect で `...pro` を Non-Consumable ¥980 で登録
- [ ] CloudKitスキーマを Production へ Deploy
- [ ] 法務3ページを GitHub Pages で公開
- [ ] スクリーンショット差し替え（仮素材は `app/appstore-screenshots/`）
- [ ] App Privacy「Data Not Collected」で申告

---

## 🛠 はじめかた（開発者向け）

1. `app/TetsuLog.xcodeproj` を開く（同梱・生成不要）
2. Team を選択・Bundle ID を一意に変更
3. iPhoneをUSB接続→▶（無料Apple IDでも最小構成で動作）
4. 初回起動でオンボーディング→52形式入り図鑑＋20撮影地が登場

トラブルは [`docs/build-troubleshooting.md`](docs/build-troubleshooting.md)、
実機ビルドの詳細は [`docs/run-on-device.md`](docs/run-on-device.md) を参照。
全体像は [`docs/HANDOFF.md`](docs/HANDOFF.md)、設計判断は [`docs/tetsulog-spec.md`](docs/tetsulog-spec.md)。

---

© 2026 TetsuLog · あなたのデータは、あなたのものです。
