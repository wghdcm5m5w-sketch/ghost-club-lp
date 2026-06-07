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

## ファイル構成

```
TetsuLog/
├── TetsuLogApp.swift          エントリ・ModelContainer(CloudKit)
├── Models/
│   ├── Models.swift           SwiftData @Model 定義
│   └── SeedData.swift         初回起動シード
├── Views/
│   ├── RootTabView.swift      4タブ
│   ├── CollectionView.swift   図鑑
│   ├── LogView.swift          記録タイムライン
│   ├── MapTabView.swift       地図
│   ├── SettingsView.swift     設定・同期状態
│   └── AddSightingView.swift  遭遇記録入力シート
└── Features/
    ├── SunCalculator.swift    順光/逆光計算（NOAA）
    ├── RideActivityAttributes.swift  ActivityKit属性
    └── ApproachMonitor.swift  接近アラート（GPS×ダイヤ）
```

## ロードマップ上の現在地

このコードは **v1.0 MVP + 一部 v1.2 機能の骨格**。OCR(DataScanner)・ウィジェット・Siri・Watchは v1.1以降に各ファイルを追加していく。
