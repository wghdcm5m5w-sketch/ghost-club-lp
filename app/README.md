# TetsuLog アプリ ソースコード

設計書 [`../docs/tetsulog-spec.md`](../docs/tetsulog-spec.md) に基づく実装の骨格。

## これは何か

Xcodeで新規プロジェクトを作り、ここの Swift ファイルを取り込めば **v1.0 の土台がそのまま動く** ように構成したソース一式です。`.xcodeproj` は環境依存で壊れやすいため同梱せず、下記手順でプロジェクトを生成します。

## セットアップ手順

1. Xcode 16+ で **新規プロジェクト** → iOS → App
   - Product Name: `TetsuLog`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData**（「Host in CloudKit」にチェック）
2. 生成された `ContentView.swift` と `TetsuLogApp.swift` を削除
3. この `TetsuLog/` 配下のファイルをすべてプロジェクトにドラッグ＆ドロップ（Copy items if needed）
4. **Signing & Capabilities** で以下を追加:
   - iCloud → CloudKit（コンテナ `iCloud.com.yourname.tetsulog`）
   - Background Modes → Remote notifications（SwiftData+CloudKit同期用）
   - Push Notifications（CloudKit同期トリガ用。ユーザーデータのプッシュではない）
5. `Info.plist` に用途文言を追加（下記）
6. ライブアクティビティを使うため、別ターゲットで **Widget Extension** を追加し
   `RideActivityAttributes.swift` を共有、`RideLiveActivity.swift` を実装

## Info.plist に必要なキー

```xml
<key>NSCameraUsageDescription</key>
<string>編成番号を読み取って記録するためにカメラを使用します。画像は端末内でのみ処理されます。</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>撮影地の記録と、狙いの編成の接近アラートに位置情報を使用します。位置情報が外部に送信されることはありません。</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>記録に写真を添付するためにフォトライブラリへアクセスします。</string>
<key>NSSupportsLiveActivities</key>
<true/>
```

## App Group / Widget の追加設定

ウィジェットとライブアクティビティのため Widget Extension を追加する：

1. File → New → Target → **Widget Extension**（名前: `TetsuLogWidgets`、Include Live Activity にチェック）
2. `TetsuLogWidgets/` 配下のファイルをこのターゲットに追加
3. **共有ファイル**（Target Membership を本体＋Widget の両方に付ける）:
   - `Models/Models.swift`
   - `Models/SharedStore.swift`
   - `Features/RideActivityAttributes.swift`
4. 両ターゲットに **App Groups** capability を追加し、ID を `group.com.yourname.tetsulog` に統一
5. `SharedStore.swift` / `TetsuLogApp.swift` / `RideActivityAttributes.swift` 内の
   `yourname` を自分の Bundle ID 接頭辞に置換

## ファイル構成

```
TetsuLog/                          （本体ターゲット）
├── TetsuLogApp.swift              エントリ・共有ModelContainer
├── Models/
│   ├── Models.swift               SwiftData @Model 定義 ★Widgetと共有
│   ├── SharedStore.swift          App Group 共有コンテナ ★Widgetと共有
│   ├── SeedData.swift             初回起動シード
│   └── PreviewData.swift          プレビュー用インメモリDB
├── Views/
│   ├── RootTabView.swift          4タブ
│   ├── CollectionView.swift       図鑑
│   ├── LogView.swift              記録タイムライン
│   ├── MapTabView.swift           地図（廃線オーバーレイ込み）
│   ├── SettingsView.swift         設定・ウォッチリスト
│   ├── AddSightingView.swift      遭遇記録入力（OCR統合済み）
│   └── RideSessionView.swift      乗車セッション（開始/乗車中、ライブ起動）
└── Features/
    ├── SunCalculator.swift        順光/逆光計算（NOAA）
    ├── FormationNumberParser.swift 編成番号抽出（純粋ロジック・テスト可）
    ├── FormationScannerView.swift  VisionKit DataScanner ラッパー
    ├── PolylineCodec.swift         廃線軌跡のエンコード/デコード
    ├── RideActivityAttributes.swift ActivityKit属性 ★Widgetと共有
    └── ApproachMonitor.swift      接近アラート（GPS×ダイヤ）

TetsuLogWidgets/                   （Widget Extension ターゲット）
├── TetsuLogWidgetBundle.swift     エントリ
├── CollectionWidget.swift         ホーム/ロック画面ウィジェット
└── RideLiveActivity.swift         ライブアクティビティ/Dynamic Island
```

## 単体テスト（任意）

`FormationNumberParser` は副作用のない純粋関数なので、テストターゲットで検証できる：

```swift
func testCarNumber() {
    let c = FormationNumberParser.candidates(from: ["クハE235-1247"])
    XCTAssertEqual(c.first?.kind, .carNumber)
    XCTAssertEqual(c.first?.classHint, "E2351247".isEmpty ? nil : "E235") // hint=E235
}
func testFormationCode() {
    let c = FormationNumberParser.candidates(from: ["トウ47"])
    XCTAssertTrue(c.contains { $0.raw == "トウ47" && $0.kind == .formationCode })
}
```

## ロードマップ上の現在地

このコードは **v1.0 MVP + v1.1(OCR/ウィジェット) + v1.2(順光/ライブアクティビティ/接近アラート) の骨格**。
残りは Siri(App Intents)・Apple Watch・多言語(String Catalog)・廃線GeoJSON表示。
