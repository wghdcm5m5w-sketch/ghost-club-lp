# TetsuLog ビルド整合性 静的監査

Xcode/Swiftコンパイラが使えない環境で、54 Swiftファイルを多セッションで実装してきたため、
実機ビルド前にコンパイル阻害要因を静的に網羅監査した記録。

実施日: 2026-06-08（Ultracode 網羅監査）

---

## 検出して修正した「確実なビルドブロッカー」

UIKit型を使用しているのに `import UIKit` が無い4ファイル（`import SwiftUI` だけでは
`UIScreen`/`UIImage`/`UITabBar`/`UIActivityViewController` は解決されない）:

| ファイル | 使用UIKit型 | 修正 |
|---|---|---|
| `RootTabView.swift` | UITabBarAppearance, UITabBar, UIColor | `import UIKit` 追加 |
| `SettingsView.swift` | UIActivityViewController | `import UIKit` 追加 |
| `ShareCardView.swift` | UIImage, UIScreen | `import UIKit` 追加 |
| `AddSightingView.swift` | UIImage | `import UIKit` 追加 |

> Haptics.swift / PhotoStore.swift は元から `import UIKit` 済み。

---

## 検証して「問題なし」を確認した項目

### import 充足
- 全54ファイルの import を使用APIと突合。上記4件以外に不足なし。
- `Haptics`(UIKit) は watchOS で使われていない（Watchは WKInterfaceDevice）。

### クロスターゲットの型漏れ
- Widget/Watch は本体専用型（`Theme`/`PaperCard`/`NavyBackground`/`Haptics` 等）を**一切参照していない**。
  それぞれ `WidgetTheme` / `WatchTheme`+`WatchPaperCard`+`WatchNavyBackground` を独立保有。

### カラートークンの定義＝参照一致
- `Theme.Palette`: 定義14個 == 参照14個（過不足なし）
- `WidgetTheme`: 参照7種すべて定義済み
- `WatchTheme.Palette`: 定義7個 == 参照7個

### 環境注入（@Environment）
- `RideManager` / `PurchaseManager` を `TetsuLogApp` で `RootTabView` に注入。
- これらを参照する全View（SettingsView/AddSightingView/SpotDetailView/PurchaseView/LogView）は
  RootTabView配下、またはそこから提示される `.sheet` / `.navigationDestination`（環境継承）。
- 該当ViewのPreviewにも `.environment(...)` 注入済み。

### API使用の妥当性
- StoreKit2: `Product.products` / `Transaction.currentEntitlements` / `Transaction.updates`、
  `purchase()` の `.success/.userCancelled/.pending/@unknown` 網羅、async整合OK。
- ActivityKit: `ActivityConfiguration` / `Activity.request` / `ActivityAuthorizationInfo`、APNs不使用。
- SwiftData: 全`@Model`にデフォルト値、リレーションはoptional+inverse、CloudKit互換。
- ImageRenderer + ShareLink(Image) + SharePreview(image:) は iOS16+ で妥当。
- `navigationDestination(item:)` / `containerBackground(for:.widget)` は iOS17+、deployment 18.0で可。
- 重複型定義なし（struct/class/enum の uniq -d が空）。

### デプロイメントターゲット
- iOS 18.0。使用している iOS16/17 世代API（ActivityKit, ImageRenderer, navigationDestination,
  Observable, containerBackground 等）はすべて利用可能。

---

## 残存する `try?`（エラーではない・設計判断）

`context.save()` の `try?` が19箇所。AddSightingView の保存は do/catch + ユーザーアラート済み。
他（削除・シード・補助保存）は失敗してもクラッシュせず体験を止めない方針で許容。
将来 `ModelContext` 拡張で共通ログ化する余地あり（`docs/critical-review-3.md` 記載）。

---

## 結論

実機ビルドを阻害する確実な誤りは **UIKit import 不足の4件のみ**で、本監査で修正済み。
それ以外の API 使用・型整合・環境注入・トークン参照は静的に検証して健全。
コンパイル検証はユーザーのXcodeで最終確認（`docs/run-on-device.md`）。
