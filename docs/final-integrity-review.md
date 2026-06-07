# TetsuLog 最終整合レビュー

実施日: 2026-06-07。LP・法務・実装・ドキュメント全体をスキャンし、矛盾と残バグを点検した記録。

---

## 点検したコード健全性（合格）

| 項目 | 結果 |
|---|---|
| struct/class/enum の重複定義 | **なし**（uniq -d で0件） |
| 参照されるView/型の定義有無 | 全13主要Viewが各1箇所で定義済み、未定義参照なし |
| ModelContainer に渡す型の一致 | TetsuLogApp / SharedStore / PreviewData で7モデル一致 |
| LP内部リンク（法務3ページ） | 3ファイルすべて実在、リンク先一致 |
| 価格表記（980円買い切り） | LP・spec・app-store-assets・特商法ページで一致 |
| 機能のコード実装 | LP掲載9機能すべて対応するViewが存在 |

---

## 発見し、修正した不整合

| # | 不整合 | 修正 |
|---|---|---|
| 1 | README が「8機能/8本柱」のまま（LPは統計を加え9機能） | README を9機能に更新、統計行を追加、編集/検索/追加/エクスポート等を追記 |
| 2 | spec のタブ構成が4タブ表記（実装は5タブ＝統計追加済み） | spec を5タブ（図鑑/記録/地図/統計/設定）に更新、各タブの機能も最新化 |
| 3 | build-troubleshooting のチェックリストが `yourname` 置換対象に RideActivityAttributes/SettingsView を誤記（実際は該当せず） | 正確に修正（yourname=SharedStore/TetsuLogApp、example.github.io=SettingsView） |
| 4 | app-store-assets のスクショ案に統計が欠落 | 統計キャプションを追加（8→9枚） |

---

## 意図的に残すプレースホルダ（公開前に置換）

これらは「リリース前に実値へ差し替える」設計で、不整合ではない：

- `com.yourname` / `iCloud.com.yourname.tetsulog` / `group.com.yourname.tetsulog`
  → `SharedStore.swift`, `TetsuLogApp.swift`
- `com.example.tetsulog`（Bundle ID）→ `project.yml`, `TetsuLog.xcodeproj`
- `support@example.com`（連絡先）→ 法務3ページ
- `example.github.io/ghost-club-lp/...`（法務ページURL）→ `SettingsView.swift`
- 事業者氏名・住所（特商法ページ、請求時開示の旨）

公開前チェックリストは `docs/app-store-assets.md` と `docs/build-troubleshooting.md` に集約済み。

---

## 既知の制約（将来課題・第3次レビューより継続）

実装外として明示済み。整合性の問題ではなく、スコープ上の割り切り：

- 音鉄（録音）未対応
- 全件 `@Query` ロード（数万件規模でのパフォーマンス）
- レイルラボ/乗りつぶしオンライン等の外部CSV移行未対応
- ジオフェンス20件上限の自動絞り込み未実装
- 写真本体は端末内のみ（iCloud非同期・JSONエクスポート非同梱、設定で明記済み）
- リポジトリ配置: iOSコードが `ghost-club-lp`（LP用リポジトリ）に同居。
  運用上は専用 `tetsulog-ios` への分離が望ましい（今は許容）。

---

## 結論

コード本体は重複・未定義参照・型不一致なし。ドキュメントの機能数・タブ構成のドリフトを是正し、
**LP / 法務 / 実装 / ドキュメントの表記が一致した状態**になった。
残るプレースホルダは公開前に置換するもののみで、設計通り。
