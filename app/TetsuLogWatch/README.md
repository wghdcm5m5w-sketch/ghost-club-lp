# TetsuLog Watch — Apple Watch コンパニオン

Apple Watch から「いま見た編成」をその場で記録できる最小コンパニオンアプリ。
本体（iOS）と CloudKit Private DB で同期し、SwiftUI + SwiftData で実装。

## できること

- **今週・今月の遭遇数**を一目で確認
- **最後の遭遇**を時間とともに表示
- **クイック記録**：形式（最近使ったものが上）→ 編成番号 → 駅、3ステップで記録
- **手首にハプティクス**で保存成功フィードバック
- 本体アプリの記録と即同期（iCloud経由）

## Xcode でターゲットを追加する手順

1. Xcode で TetsuLog プロジェクトを開く
2. File → New → Target → **watchOS** → **App**
3. Product Name: `TetsuLogWatch`、Interface: SwiftUI、Bundle ID は本体の末尾に `.watchapp` 等
4. 生成された雛形を削除し、本フォルダの 4ファイルをこの新ターゲットに追加：
   - `TetsuLogWatchApp.swift`
   - `WatchTheme.swift`
   - `WatchTodayView.swift`
   - `WatchQuickRecordView.swift`
5. **共有ファイル**（本体ターゲットとWatchターゲットの両方にMembershipを付ける）:
   - `TetsuLog/Models/Models.swift`
   - `TetsuLog/Models/SharedStore.swift`
6. Capabilities (Watchターゲット):
   - **iCloud** → CloudKit、コンテナは本体と同じ `iCloud.com.yourname.tetsulog`
   - **App Groups** → 本体と同じ `group.com.yourname.tetsulog`
7. ビルドターゲットを Watch シミュレータ（または実機）に切替えて ⌘R

## 設計

- **コードは独立**：本体のViewには一切依存せず、Watch用Themeを別に持つ（小画面に最適化）
- **データは共有**：CloudKitと SharedStore (App Group) を通して本体と完全同期
- **オフライン可**：CloudKit同期が無くてもローカルで保存。後で本体と勝手に同期する
- **権限不要**：位置情報・カメラなど使わない最小スコープ

## 将来拡張（メモ）

- ComplicationKit による文字盤ウィジェット（今月の遭遇数 / 集めた編成数）
- スマートスタックでの乗車セッション表示（本体のActivityKitと連携）
- 接近アラートの通知をWatchで受け取り、その場で記録
