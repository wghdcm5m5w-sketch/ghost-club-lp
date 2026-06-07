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
├── tetsulog.html                  ← ランディングページ（10機能・完成）
├── tetsulog-privacy.html          ← プライバシーポリシー
├── tetsulog-terms.html            ← 利用規約
├── tetsulog-tokushoho.html        ← 特定商取引法に基づく表記
│
├── docs/
│   ├── market-analysis.md         ← App Store鉄道アプリ市場分析（企画根拠）
│   ├── tetsulog-spec.md           ← 技術設計書（実装の青写真）
│   └── app-store-assets.md        ← ストア掲載素材（説明文・キーワード・申告）
│
└── app/                           ← iOSアプリ実装骨格（Swift）
    ├── README.md                  ← Xcodeセットアップ手順
    ├── TetsuLog/                  本体ターゲット
    │   ├── Models/                SwiftData モデル・シード・共有ストア
    │   ├── Views/                 4タブUI・記録入力・乗車セッション
    │   ├── Features/              OCR・順光計算・ライブ・接近アラート・Siri
    │   └── Resources/             多言語(.xcstrings)・形式データ(JSON)
    └── TetsuLogWidgets/           ウィジェット・ライブアクティビティ

（※ index.html / privacy.html 等は本リポジトリの前身 GHOST CLUB LP の資産）
```

---

## 🚆 機能（LP掲載の10本柱・すべて骨格実装済み）

| # | 機能 | 概要 | 実装 |
|---|---|---|---|
| 1 | 図鑑 | 編成番号レベルで車両を個体収集（編成/号機/車番を区別） | `CollectionView` |
| 2 | OCR | 写真から編成番号を端末内で自動読み取り | `FormationScannerView` / `FormationNumberParser` |
| 3 | 地図 | 遭遇地点・撮影地・廃線オーバーレイ | `MapTabView` |
| 4 | 順光計算 | 太陽方位から順光/逆光を判定 | `SunCalculator`（NOAA算法）/ `SpotDetailView` |
| 5 | タイムライン | 記録から鉄道人生を年表化（編集・削除可） | `LogView` |
| 6 | 廃線 | 過去の路線を地図に重ね合わせ | `PolylineCodec` + `MapTabView` |
| 7 | ライブアクティビティ | 乗車中をDynamic Island/ロック画面に | `RideActivityAttributes` / `RideLiveActivity` |
| 8 | 接近アラート | 狙いの編成をGPS×位置で思い出させる | `ApproachMonitor` |
| 9 | 統計 | 累計距離/Top形式・路線・駅/月別推移/ラストラン集計 | `StatsView` / `Statistics` |
| 10 | 音鉄 | 走行音・駅メロ・車内放送を遭遇に添付（端末内） | `AudioRecorderView` / `AudioPlayerView` / `AudioStore` |

加えて: 記録の編集・削除 / 検索 / 形式・編成のユーザー追加 / JSON書き出し・読み込み / **CSV取り込み（他サービスから移行）** /
ウィジェット / Spotlight / Siri(App Intents) / Apple Watch / 多言語(日英中韓)。

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
| v1.0 | 図鑑・記録・地図・タイムライン・CloudKit同期 | 骨格実装済み |
| v1.1 | OCR・ウィジェット・Spotlight・共有シート | 骨格実装済み |
| v1.2 | 順光計算・廃線・Siri・ライブアクティビティ | 骨格実装済み |
| v1.3 | 接近アラート・Apple Watch・多言語 | 骨格実装済み |
| 公開 | 実機ビルド・スクショ・課金登録・審査 | 準備中 |

---

## ✅ 公開前チェックリスト（要差し替え）

- [ ] 連絡先メール・事業者情報を実値に（法務3ページ・`docs/app-store-assets.md`）
- [ ] Bundle ID / CloudKit / App Group ID を確定し全コードの `yourname` を置換
- [ ] GitHub Pages を有効化し法務ページの公開URLを確定（`SettingsView` のリンク）
- [ ] スクリーンショット撮影（6.7" / 6.1" / iPad 12.9"）
- [ ] App内課金「TetsuLog Pro」を登録
- [ ] App Privacy を「Data Not Collected」で申告

---

## 🛠 はじめかた（開発者向け）

1. `app/README.md` の手順で Xcode プロジェクトを生成
2. SwiftData + CloudKit、App Group、Widget Extension を設定
3. `Info.plist` 用途文言は `Resources/InfoPlist.xcstrings` を利用
4. ビルド → シミュレータで4タブが動作、記録追加で図鑑が埋まる

詳細な設計判断は [`docs/tetsulog-spec.md`](docs/tetsulog-spec.md) を参照。

---

© 2026 TetsuLog · あなたのデータは、あなたのものです。
