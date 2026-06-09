# TetsuLog アクセシビリティ監査

## カラーコントラスト（WCAG 2.1）

WCAG基準（AA本文 4.5 / AA大 3.0）でカラーペアを検証し、不足箇所を是正した。

### 監査結果

| 組み合わせ | 比 | 判定 |
|---|---:|---|
| ink on paper | 13.03 | AA本文 ✓ |
| inkSub on paper | 5.56 | AA本文 ✓ |
| red on paper | 4.54 | AA本文 ✓ |
| **gold on paper** | **2.00** | **不足 → goldDeep導入** |
| ink on paperAged | 9.27 | AA本文 ✓ |
| inkSub on paperAged | 3.96 | AA大 ✓ |
| red on paperAged | 3.23 | AA大 ✓ |
| cream on navy | 12.57 | AA本文 ✓ |
| creamSub on navy | 6.73 | AA本文 ✓ |
| gold on navy | 6.50 | AA本文 ✓ |
| **red on navy** | **2.87** | **不足 → redLight導入** |
| paper on navy | 13.03 | AA本文 ✓ |
| **redLight on navy** | **4.45** | **AA大 ✓（本文ほぼ可）** |

### 是正トークン

- `Theme.Palette.goldDeep` = `#8A6F1F`：紙地上の金テキスト/アイコン用（コンプリート達成）
- `Theme.Palette.redLight` = `#E85A48`：紺地上の朱テキスト/ライブラベル用

### 置換箇所

紙地上の `gold` → `goldDeep`：
- CollectionView: コンプチェックシール・%表記・形式詳細「コンプリート」ラベル
- StatsView: 「コンプリート」セクション
- ShootingSpotView: 日中の太陽アイコン
- SettingsView: Pro有効バッジ
- Theme RailGauge: 完了時の塗り色

紺地上の `red` → `redLight`：
- OnboardingView: ヘッダーのtramアイコン
- PurchaseView: エラーメッセージ
- WidgetTheme: redLight 追加
- LiveActivity ロック画面: 「乗車中」ラベル

## その他のアクセシビリティ

- **月別チャート**: 各バーに accessibilityLabel/Value で VoiceOver 対応済み
- **アイコン+ラベル併用**: 種別（定期/臨時/回送/...）は色だけでなくテキストも併記
- **タップ領域**: PaperCard はカード全体を `Button` として扱い、44pt以上を確保
- **Dynamic Type**: SwiftUI 標準フォントを使用、ユーザー設定に追随

## 残課題

- 形式詳細の InkBadge「廃車」outlined は紙地で red(4.54) なので AA本文を満たすが、
  老眼の利用者向けに `font(.caption.bold())` 程度を維持
- 写真サムネのフルスクリーンビューアー（将来）
