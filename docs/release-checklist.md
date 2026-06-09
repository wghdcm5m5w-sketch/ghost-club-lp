# TetsuLog リリースチェックリスト（決定版）

App Store 提出までの全工程。プレースホルダ置換・ターゲット追加・IAP登録・審査素材を網羅。
このリポジトリは最小構成の `.xcodeproj` を同梱（本体アプリのみ）。Watch/Tests/Widget は下記で追加する。

---

## フェーズ 0: 開発環境

- [ ] Mac に Xcode 16 以降
- [ ] 有料 Apple Developer Program 登録済み（CloudKit/Push/IAP に必須）
- [ ] `app/TetsuLog.xcodeproj` を開く、または `cd app && xcodegen generate`

---

## フェーズ 1: 識別子の確定と置換

自分の Bundle ID 接頭辞（例 `jp.yourcompany`）を決め、以下を**全置換**する。

| プレースホルダ | 置換後（例） | 出現ファイル |
|---|---|---|
| `iCloud.com.yourname.tetsulog` | `iCloud.jp.yourcompany.tetsulog` | `TetsuLogApp.swift`, `SharedStore.swift`, `TetsuLogWatchApp.swift` |
| `group.com.yourname.tetsulog` | `group.jp.yourcompany.tetsulog` | `SharedStore.swift`, Watch README |
| `com.example.tetsulog` | `jp.yourcompany.tetsulog` | `project.yml`, `.xcodeproj`（Signing） |
| `com.example.tetsulog.pro` | `jp.yourcompany.tetsulog.pro` | `TetsuLog.storekit`, `PurchaseManager.swift`（`proProductID`） |
| `https://example.github.io/ghost-club-lp/...` | 実際の公開URL | `SettingsView.swift`（法務リンク3つ） |
| `support@example.com` | 実サポートアドレス | `tetsulog-privacy/terms/tokushoho.html` |
| 事業者氏名・住所 | 実情報（請求時開示可） | `tetsulog-tokushoho.html` |

> `PurchaseManager.proProductID` と `.storekit` の `productID` は**完全一致**させること。

---

## フェーズ 2: ターゲットと Capabilities

### 本体 TetsuLog
- [ ] Signing & Capabilities → Team を選択
- [ ] iCloud → **CloudKit**、コンテナ `iCloud.jp.yourcompany.tetsulog` を作成
- [ ] **App Groups** → `group.jp.yourcompany.tetsulog`
- [ ] **Push Notifications**（CloudKit同期トリガ）
- [ ] **Background Modes** → Remote notifications
- [ ] Info.plist の権限文言（カメラ/位置/マイク/写真）を確認（同梱済み）
- [ ] `NSSupportsLiveActivities = YES` を確認（同梱済み）

### Widget Extension（任意・推奨）
- [ ] File → New → Target → Widget Extension（Include Live Activity）
- [ ] `app/TetsuLogWidgets/` の4ファイルを追加（Bundle/WidgetTheme/Collection/RideLiveActivity）
- [ ] 共有: `Models.swift` / `SharedStore.swift` / `RideActivityAttributes.swift` の Membership
- [ ] iCloud + App Groups を同IDで付与

### Apple Watch（任意）
- [ ] File → New → Target → watchOS App（`TetsuLogWatch`）
- [ ] `app/TetsuLogWatch/` の4ファイルを追加
- [ ] 共有: `Models.swift` / `SharedStore.swift`
- [ ] iCloud + App Groups を同IDで付与

### Tests（任意・推奨）
- [ ] Unit Testing Bundle `TetsuLogTests` を追加し `app/TetsuLogTests/` を取込
- [ ] `⌘U` で 35件のテストが通ることを確認

---

## フェーズ 3: 課金（IAP）

- [ ] スキーマ → Options → StoreKit Configuration に `TetsuLog.storekit` を指定（Sandbox購入テスト）
- [ ] シミュレータ/実機で「購入」「復元」「Pro解放」「OCR/順光/録音のゲート解除」を確認
- [ ] App Store Connect → App内課金 → **Non-Consumable** を `...tetsulog.pro` で登録
- [ ] 価格を ¥980（Tier）に、ja/en の表示名・説明を入力
- [ ] 税・銀行・契約（Paid Apps Agreement）を完了

---

## フェーズ 4: CloudKit スキーマ

- [ ] 実機（iCloudサインイン済み）で一度起動し、レコードを作成
- [ ] CloudKit Dashboard で Development スキーマを確認
- [ ] **Deploy Schema to Production**

---

## フェーズ 5: 審査素材（`docs/app-store-assets.md` 参照）

- [ ] アプリ名 / サブタイトル / キーワード（日英）
- [ ] 説明文（日英）／プロモーションテキスト
- [ ] スクリーンショット（6.7" 必須、6.1"/iPad 任意）
      → `app/appstore-screenshots/` の7枚を実機キャプチャに差し替え推奨
- [ ] App アイコン（`Assets.xcassets/AppIcon` 同梱済み）
- [ ] **App Privacy = Data Not Collected** で申告
- [ ] **プライバシーマニフェスト**（`PrivacyInfo.xcprivacy` 同梱済み）がターゲットに含まれているか確認
      - 本体は同梱済み。Widget/Watchを追加した場合は**各ターゲットにも**配置すること
      - 宣言内容: トラッキングなし／収集データなし／UserDefaults(CA92.1)・FileTimestamp(C617.1)
- [ ] サポートURL / マーケティングURL（LP公開先）
- [ ] 年齢レーティング 4+

---

## フェーズ 6: 法務ページの公開

- [ ] `tetsulog-privacy/terms/tokushoho.html` を GitHub Pages 等で公開
- [ ] 公開URLを `SettingsView` の3リンクと App Store Connect に設定

---

## フェーズ 7: ビルド & 提出

- [ ] Release ビルドが通る（警告の棚卸し）
- [ ] 実機で主要動線（記録追加→図鑑反映→統計→エクスポート→購入）を確認
- [ ] Archive → Validate → App Store Connect へアップロード
- [ ] TestFlight 内部テスト
- [ ] 審査提出（審査メモは `docs/app-store-assets.md` に用意済み）

---

## 公開後

- [ ] 形式マスタ・撮影地・廃線データの拡充（ユーザー要望を反映）
- [ ] レビュー返信の運用
- [ ] v2.0 候補: 音鉄アーカイブ共有 / リアルタイム在線 / 外部CSVフォーマット追加対応
