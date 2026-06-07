# TetsuLog ビルド・実機検証トラブル予測集

> Xcodeでプロジェクトを組んで実機/シミュレータで動かす際に、ほぼ確実に踏む落とし穴と対処。
> 個人開発・無料運用・SwiftData+CloudKit前提。

---

## 1. SwiftData + CloudKit の初期化で落ちる

### 症状
`fatalError("ModelContainer の初期化に失敗")` でクラッシュ、または同期されない。

### 原因と対処
- **全プロパティにデフォルト値が必須**。CloudKitは「必須プロパティ」を許さない。
  本プロジェクトは全 `@Model` にデフォルト値を付与済み。新規プロパティ追加時も必ずデフォルト値を。
- **リレーションは optional & inverse 指定**。`@Relationship(... inverse:)` を付け、配列リレーションは `[T]?`。
- **`@Attribute(.unique)` は CloudKit と併用不可**。本プロジェクトは未使用。追加しないこと。
- **iCloudにサインインした実機 or シミュレータ**で動かす。未サインインだとPrivate DBが使えず同期しない（ローカルは動く）。
- CloudKitコンテナID `iCloud.com.yourname.tetsulog` を**実IDに置換**し、Signing & Capabilities の iCloud→CloudKit で同名コンテナを作成。

### スキーマ初期化
- 初回は CloudKit Dashboard でスキーマが自動生成されない場合がある。
  **開発環境(Development)で一度アプリを動かしてレコードを作る**→ Dashboard で "Deploy Schema to Production"。

---

## 2. App Group が見つからず SharedStore が nil

### 症状
ウィジェットが「データなし」表示。`SharedStore.container` が nil。

### 対処
- 本体・Widget Extension **両方**に App Groups capability を追加し、IDを `group.com.yourname.tetsulog` に統一。
- `SharedStore.appGroupID` を実IDに合わせる。
- App Group内の store URL と CloudKit を併用する場合、**両ターゲットのentitlementsにiCloud+App Groups両方**が必要。

---

## 3. ウィジェットがビルドできない / 型が見つからない

### 症状
`Cannot find 'Sighting' in scope`、`RideAttributes` 未定義。

### 対処
- **共有ファイルの Target Membership** を確認。以下をWidgetターゲットにもチェック：
  - `Models/Models.swift`
  - `Models/SharedStore.swift`
  - `Features/RideActivityAttributes.swift`
- Widget内で SwiftData を使うため、Widgetターゲットにも SwiftData が import 可能であること（標準で可）。

---

## 4. ライブアクティビティが表示されない

### 症状
`Activity.request` してもDynamic Islandに出ない。

### 対処
- `Info.plist` に `NSSupportsLiveActivities = YES`。
- 設定アプリ→該当アプリ→「ライブアクティビティ」がオンか。
- **実機必須級**。シミュレータはDynamic Island対応機種(iPhone 15 Pro等)を選ぶ。
- `ActivityAuthorizationInfo().areActivitiesEnabled` を起動時に確認。

---

## 5. `.sheet(item:)` に SwiftData モデルを渡すと型エラー

### 症状
`Instance method 'sheet(item:onDismiss:content:)' requires that 'Sighting' conform to 'Identifiable'`

### 対処
- `PersistentModel` は `Identifiable`（`persistentModelID`）に準拠しているため**基本は通る**。
- 通らない場合は Xcode/Swiftバージョン差。`Sighting: Identifiable` を明示はしない（二重準拠エラーになる）。
  代わりに `.sheet(isPresented:)＋選択state` 方式へ切替。

---

## 6. VisionKit DataScanner がシミュレータで動かない

### 症状
スキャン画面が真っ黒、`isSupported == false`。

### 対処
- **DataScannerはカメラ実機必須**。シミュレータ不可。
- `FormationScannerView.isSupported` で分岐済み。シミュレータでは手入力にフォールバックする実装になっている。
- 実機で `NSCameraUsageDescription` が無いと即クラッシュ → InfoPlist.xcstrings の文言を設定。

---

## 7. PhotosPicker / EXIF 取得の注意

### 症状
`loadTransferable(type: Data.self)` が nil、EXIF位置が取れない。

### 対処
- スクショ等はEXIFにGPSが無いのが正常（nilで問題なし、手入力フォールバック）。
- iCloud写真が「最適化」されていると一旦ダウンロードが走る。失敗時は再試行。
- 写真の位置情報は **設定→プライバシー→写真→位置情報** の許可が要る場合がある。

---

## 8. CoreLocation ジオフェンス（接近アラート）

### 症状
`didEnterRegion` が呼ばれない。

### 対処
- `requestWhenInUseAuthorization` 後、**監視できるリージョン数は最大20**。超過分は無視される（撮影地が多い場合は近い順に絞る実装が将来必要）。
- バックグラウンド通知には "Always" 権限が要る場面あり。本アプリは When in Use 前提＝アプリ起動中/近接時の通知に留まる旨を文言で明記済み。
- シミュレータは Features→Location で位置を擬似設定。

---

## 9. SwiftData マイグレーション（フィールド追加）

### 症状
v1.5でSightingにフィールドを追加した後、既存データで落ちる。

### 対処
- **デフォルト値付きプロパティの追加は軽量マイグレーションで自動対応**（本プロジェクトは全てデフォルト値付き）。
- プロパティの**削除・リネーム・型変更**は `SchemaMigrationPlan` が必要。安易にやらない。
- CloudKit併用時、**プロパティ削除は本番スキーマと不整合**を起こす。追加は安全、削除は慎重に。

---

## 10. App Intents / Siri が候補に出ない

### 対処
- `AppShortcutsProvider` を実装したら**一度アプリを起動**するとショートカットが登録される。
- フレーズに `\(.applicationName)` を含めること（必須）。
- `openAppWhenRun = true` のIntentは前面化。ライブアクティビティ起動系はこれが要る。

---

## 11. プレビューがクラッシュする

### 対処
- 全Previewは `PreviewData.container`（インメモリ）を使用。CloudKitは使わない。
- `RideManager` を使う画面は `.environment(RideManager())` を付与（付与済み）。

---

## 12. 文字列ローカライズが効かない

### 対処
- `Localizable.xcstrings` をプロジェクトに追加し、ビルドターゲットに含める。
- `Text("図鑑")` のキーは日本語そのもの。xcstringsの sourceLanguage=ja と一致。
- 言語確認はスキーム→Run→Options→App Language で切替。

---

## ビルド前 最終チェック

- [ ] `yourname` を含む文字列を全置換（`SharedStore.swift` / `TetsuLogApp.swift`）
- [ ] `example.github.io` の法務ページURLを実URLに置換（`SettingsView.swift`）
- [ ] iCloud / App Groups / Push（CloudKit同期用）/ Live Activities を Capabilities に追加
- [ ] InfoPlist.xcstrings の権限文言を Info.plist に反映（またはxcstringsを使用）
- [ ] seed_vehicles.json をバンドルに含める（Copy Bundle Resources）
- [ ] Localizable.xcstrings / InfoPlist.xcstrings をターゲットに含める
- [ ] Widget Extension に共有ファイルの Membership を付与
- [ ] 実機（iCloudサインイン済み）で同期とカメラとライブアクティビティを確認
