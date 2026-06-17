# フル構成（xcodegen）への移行ガイド — Widget / Watch を出荷ビルドへ

v1.0/v1.1/v1.2 は「本体1ターゲットだけの最小 `.xcodeproj`」でリリースしてきた。
Widget（ホーム/ロック画面）と Apple Watch コンプリケーションを**実際にビルド・出荷**するには、
`app/project.yml` から **4〜5ターゲット構成の `.xcodeproj` を再生成**する必要がある。

> ⚠️ これは出荷中アプリの `.xcodeproj` を作り直す操作。再生成後に
> **各ターゲットの署名Team再選択**と **Capabilities付与** が必須。落ち着いて下記の順で。

---

## 0. 事前確認

`app/project.yml` は以下の **5ターゲット**を定義済み：
- `TetsuLog`（本体・iOS）
- `TetsuLogTests`（テスト）
- `TetsuLogWidgetsExtension`（iOS ウィジェット：コレクション/廃車進行中/ライブアクティビティ）
- `TetsuLogWatch`（watchOS アプリ）
- `TetsuLogWatchWidgets`（watchOS コンプリケーション）★今回追加

Bundle ID 体系：
```
com.ryofujimatsu.tetsulog                        本体
com.ryofujimatsu.tetsulog.tests                  テスト
com.ryofujimatsu.tetsulog.widgets                iOSウィジェット
com.ryofujimatsu.tetsulog.watchapp               Watchアプリ
com.ryofujimatsu.tetsulog.watchapp.complication  Watchコンプリ
```

---

## 1. xcodegen を入れて再生成

```bash
brew install xcodegen
cd ~/ghost-club-lp/app
# 念のため現行プロジェクトを退避
mv TetsuLog.xcodeproj TetsuLog.xcodeproj.bak
xcodegen generate
open TetsuLog.xcodeproj
```

> project.yml には Info.plist の生成プロパティ（権限文言・NSSupportsLiveActivities・
> ITSAppUsesNonExemptEncryption・NSFaceID 等）と
> `ENABLE_APP_SHORTCUTS_FLEXIBLE_MATCHING: NO` が入っているので、
> 生成後の Info.plist / ビルド設定は v1.x と同等になる。

---

## 2. 署名（各ターゲットで Team を選ぶ）

TARGETS の **5つすべて**で Signing & Capabilities → **Team = RYO FUJIMATSU**、
Automatically manage signing は ON。

---

## 3. Capabilities 付与（Widget/Watch のデータ共有に必須）

データは App Group + CloudKit 経由で共有する。以下を**該当ターゲットすべて**に。

| Capability | 値 | 付与するターゲット |
|---|---|---|
| **App Groups** | `group.com.ryofujimatsu.tetsulog` | 本体 / iOSウィジェット / Watch / Watchコンプリ |
| **iCloud → CloudKit** | `iCloud.com.ryofujimatsu.tetsulog` | 本体 / Watch（※拡張は本体/Watch経由で読む） |
| **Push Notifications** | — | 本体 |
| **Background Modes → Remote notifications** | — | 本体 |

> App Group を付け忘れると、ウィジェット/コンプリは `SharedStore.container == nil` で
> **ゼロ表示**になる（クラッシュはしない）。

---

## 4. ビルド & 確認

- スキーム **TetsuLog**（iOS実機）で ⌘R → ホーム画面ウィジェット追加で
  「コレクション」「廃車進行中」が出るか
- スキーム **TetsuLogWatch** で ⌘R → 文字盤に「今週の遭遇」コンプリケーションを追加
- `⌘U` で TetsuLogTests（駅名正規化など）が通るか

---

## 5. 提出（v1.1 として）

1. バージョンは project.yml で `1.1 / 2` 済み
2. Archive → Validate → Upload
3. App Store Connect で 1.1 バージョン作成 → ビルド選択 → 審査提出
4. What's New（`docs/whats-new-1.1.md` 参照）

---

## ロールバック

うまくいかない場合：
```bash
cd ~/ghost-club-lp/app
rm -rf TetsuLog.xcodeproj
mv TetsuLog.xcodeproj.bak TetsuLog.xcodeproj
```
で従来の単一ターゲット構成（出荷実績あり）に即戻せる。Widget/Watch は次回に回せる。
