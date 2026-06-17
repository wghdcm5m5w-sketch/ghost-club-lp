# 🛠 xcodegen 移行ガイド（v1.2 — 詳細版）

このガイドは「**1.0で出した最小構成のXcodeプロジェクト**」を「**Widget/Watchも入った5ターゲットの本格構成**」に切り替える手順です。

各ステップに：
- 🎯 **やること**（コピペ可能なコマンド or 具体的なクリック）
- ✅ **こうなれば成功**（画面に何が出るか）
- ⚠️ **違ったらどうする**（リカバリ）

を書きました。順番に上から実行してください。

---

## 📋 全体の流れ（先に把握）

| Phase | 内容 | 所要時間 |
|---|---|---|
| 1 | 準備（xcodegen 導入＋最新コードを取得） | 3分 |
| 2 | 既存プロジェクトを退避してから再生成 | 1分 |
| 3 | 5ターゲットすべてに署名Teamを設定 | 5分 |
| 4 | Capabilities（App Groups / iCloud / Push）を付与 | 10分 |
| 5 | 実機で動作確認（iOS本体 → iOSウィジェット → Watch → コンプリ） | 10分 |
| 6 | テストを走らせる（任意） | 2分 |

**合計 約30分**。最後の Phase 5 が一番達成感あります。Phase 4 で詰まりやすいので落ち着いて。

---

# Phase 1 — 準備

## ステップ 1.1：xcodegen をインストール

> `xcodegen` は「`project.yml` という設定ファイルから `.xcodeproj` を機械的に作るツール」。Homebrew で入れます。

🎯 **やること**：ターミナルを開いて、次の1行を貼り付けて Enter

```bash
brew install xcodegen
```

✅ **こうなれば成功**：最後に `🍺 /opt/homebrew/Cellar/xcodegen/...` のような行が出る。
そのあと `xcodegen --version` と打って `Version: 2.X.X` と表示されればOK。

⚠️ **違ったら**：
- 「brew: command not found」→ Homebrew が未インストール。`https://brew.sh` の手順で導入後、再度上記。
- 権限エラー → `sudo` は不要。Homebrew のフォルダ権限を直す指示が出る場合があるので、表示された通りに実行。

---

## ステップ 1.2：最新コードを取得

🎯 **やること**：ターミナルで以下をまとめて貼り付けて Enter

```bash
cd ~/ghost-club-lp
git fetch origin
git reset --hard origin/claude/railway-app-market-analysis-B4mFr
```

✅ **こうなれば成功**：最後に `HEAD is now at eead34a feat(v1.2): ...` のような行。

⚠️ **違ったら**：
- 「Your local changes would be overwritten」→ 何か変更が残っています。`git stash` で退避してから再度実行。
- 「Couldn't find remote ref ...」→ ネットワーク接続を確認。

---

# Phase 2 — プロジェクト再生成

## ステップ 2.1：Xcode を完全に閉じる

🎯 **やること**：Xcode を ⌘Q で終了（ウィンドウを閉じるだけでなく**完全に終了**）。

✅ **こうなれば成功**：Dockに Xcodeアイコンの下のドット（起動中マーク）が消える。

---

## ステップ 2.2：今のプロジェクトを退避（保険）

> もし新構成でうまくいかなくても、これを戻せば**元の v1.0 出荷構成にすぐ復帰**できます。捨てません。

🎯 **やること**：ターミナルで以下を貼り付けて Enter

```bash
cd ~/ghost-club-lp/app
mv TetsuLog.xcodeproj TetsuLog.xcodeproj.bak
```

✅ **こうなれば成功**：何も出力されない（成功すると無言）。
確認したいなら `ls | grep TetsuLog.xcodeproj` で `TetsuLog.xcodeproj.bak` が出る。

⚠️ **違ったら**：
- 「No such file or directory」→ パスが違うか、すでに移動済み。`ls ~/ghost-club-lp/app` で `TetsuLog.xcodeproj` か `.bak` のどちらが存在するか確認。

---

## ステップ 2.3：新しいプロジェクトを生成

🎯 **やること**：ターミナルで次の1行

```bash
xcodegen generate
```

✅ **こうなれば成功**：
```
⚙️  Generating project...
⚙️  Writing project...
Created project at /Users/ryofujimatsu/ghost-club-lp/app/TetsuLog.xcodeproj
```
のように表示される。新しい `TetsuLog.xcodeproj` ができる。

⚠️ **違ったら**：
- 「ERROR: ...」→ そのエラー文をスクショまたはコピーで僕に送ってください。`project.yml` の解釈問題なら僕が直します。

---

## ステップ 2.4：Xcode で開く

🎯 **やること**：ターミナルで

```bash
open TetsuLog.xcodeproj
```

✅ **こうなれば成功**：Xcodeが起動し、左サイドバーに **5つのターゲット**が見える：
- 🟦 TetsuLog（青いアイコン・本体）
- TetsuLogTests
- TetsuLogWatch
- TetsuLogWatchWidgets ★今回追加
- TetsuLogWidgetsExtension

---

# Phase 3 — 5ターゲットの署名

> ここからは Xcode の中で操作します。落ち着いてどうぞ。
> **やることは1ターゲットにつき2クリックだけ**。それを5回繰り返します。

## ステップ 3.0：Signing 画面の場所を覚える

Xcodeの画面上部、左から：
1. 一番左のサイドバーで **TetsuLog（青いアイコン）** をクリック
2. 真ん中のエディタ上部の **TARGETS** リストでターゲットを選ぶ
3. その下のタブ列で **「Signing & Capabilities」** を選ぶ
4. その下に **Signing** セクションがある。**Team** ドロップダウンで選択

これを 5ターゲット分繰り返すだけです。

## ステップ 3.1：本体 TetsuLog の Team を選ぶ

🎯 **やること**：
1. TARGETS で **TetsuLog**（一番上）を選択
2. **Signing & Capabilities** タブを開く
3. **Automatically manage signing** にチェック（既に入っていればOK）
4. **Team** で **RYO FUJIMATSU** を選択

✅ **こうなれば成功**：**Signing Certificate** に `Apple Development: hujihujimatu@hotmail.co.jp` が表示される。赤いエラーが消える。

⚠️ **違ったら**：
- 赤エラーで「No matching profile」→ そのまま少し待つ（Xcodeが自動で作る）。10秒以上待っても消えなければ Team を**一度別のものに変えてから戻す**と再生成される。

## ステップ 3.2 〜 3.5：残り4ターゲットも同じ操作

🎯 **やること**：TARGETSリストで以下を順に選び、それぞれ Team を RYO FUJIMATSU に設定（やり方は 3.1 と全く同じ）：

- [ ] **TetsuLogTests**
- [ ] **TetsuLogWatch**
- [ ] **TetsuLogWatchWidgets**
- [ ] **TetsuLogWidgetsExtension**

✅ **Phase 3 完了の合図**：5ターゲットすべてで Signing セクションに赤エラーが無い。

---

# Phase 4 — Capabilities（最重要）

> ここが**今回の作業の心臓部**です。Widget や Watch が本体と同じデータを見るために必要。

## 📊 何をどこに付けるか（早見表）

| 機能 | 本体<br>TetsuLog | iOSウィジェット<br>TetsuLogWidgetsExtension | Watchアプリ<br>TetsuLogWatch | Watchコンプリ<br>TetsuLogWatchWidgets |
|---|:-:|:-:|:-:|:-:|
| **App Groups** | ✅ | ✅ | ✅ | ✅ |
| **iCloud (CloudKit)** | ✅ | — | ✅ | — |
| **Push Notifications** | ✅ | — | — | — |
| **Background Modes** | ✅ | — | — | — |

つまり：
- **App Groups は4つに必要**（テスト以外全部）
- **iCloud は2つに必要**（本体とWatch）
- 残りは本体だけ

---

## ステップ 4.1：本体 TetsuLog にすべて付与

🎯 **やること**：

1. TARGETS で **TetsuLog** を選択
2. **Signing & Capabilities** タブを開く
3. 左上の **「+ Capability」** ボタンをクリック
4. 出てきた検索窓で各 Capability を1つずつ追加

### 4.1.a：App Groups

- 「+ Capability」→ `App Groups` と入力 → ダブルクリック
- 画面に「App Groups」セクションが出る
- 中の **「+」ボタン** をクリック
- ダイアログに次を入力 → **OK**：
  ```
  group.com.ryofujimatsu.tetsulog
  ```
- ✅ チェックマークが付く

### 4.1.b：iCloud

- 「+ Capability」→ `iCloud` と入力 → ダブルクリック
- 出てきた **iCloud** セクションで：
  - **Services** の中の **「CloudKit」** にチェック
  - **Containers** の **「+」** をクリック
  - 次を入力 → **OK**：
    ```
    iCloud.com.ryofujimatsu.tetsulog
    ```
- ✅ コンテナにチェックマークが付く

### 4.1.c：Push Notifications

- 「+ Capability」→ `Push` と入力 → **Push Notifications** をダブルクリック
- 設定不要、追加するだけでOK

### 4.1.d：Background Modes

- 「+ Capability」→ `Background` と入力 → **Background Modes** をダブルクリック
- 出てきたチェックリストの中の **「Remote notifications」** にチェック

✅ **本体は4つの Capability セクション**が並んでいれば完了。

---

## ステップ 4.2：iOSウィジェットに App Groups だけ付与

🎯 **やること**：

1. TARGETS で **TetsuLogWidgetsExtension** を選択
2. **Signing & Capabilities** タブ
3. 「+ Capability」→ **App Groups** を追加
4. 「+」で同じグループID を入力：
   ```
   group.com.ryofujimatsu.tetsulog
   ```
   ※ 既に4.1で作ったので、もしリストに出てきたら**チェックを入れるだけ**でOK

✅ App Groups セクションにグループ名とチェックマーク。

---

## ステップ 4.3：Watchアプリに App Groups と iCloud を付与

🎯 **やること**：

1. TARGETS で **TetsuLogWatch** を選択
2. **Signing & Capabilities** タブ
3. **App Groups** を追加 → `group.com.ryofujimatsu.tetsulog` をチェック
4. **iCloud** を追加 → CloudKit にチェック → `iCloud.com.ryofujimatsu.tetsulog` をチェック

---

## ステップ 4.4：Watchコンプリに App Groups だけ付与

🎯 **やること**：

1. TARGETS で **TetsuLogWatchWidgets** を選択
2. **Signing & Capabilities** タブ
3. **App Groups** を追加 → `group.com.ryofujimatsu.tetsulog` をチェック

---

## ✅ Phase 4 完了チェック

下の表をすべて「✅」で埋められれば完璧です：

| ターゲット | App Groups | iCloud | Push | Background |
|---|:-:|:-:|:-:|:-:|
| TetsuLog | ☐ | ☐ | ☐ | ☐ |
| TetsuLogWidgetsExtension | ☐ | — | — | — |
| TetsuLogWatch | ☐ | ☐ | — | — |
| TetsuLogWatchWidgets | ☐ | — | — | — |

⚠️ **共通のトラブル対処**：
- 「Failed to create provisioning profile」→ そのまま 10秒待つ。Xcode が裏で作っています。消えなければ Team を選び直す。
- 「App Group could not be added」→ developer.apple.com に Apple ID でログイン中か確認。auto-signing は裏で API を呼ぶので、ログイン状態が切れていると失敗します。

---

# Phase 5 — 動作確認

## ステップ 5.1：本体アプリが今まで通り動くか

🎯 **やること**：

1. 左上のスキーム選択（再生ボタンの隣）で **TetsuLog** を選択
2. デバイス選択でつないだ実機（ワイフォン）を選択
3. **⌘R** で実行

✅ **こうなれば成功**：従来通りの近黒＋シアン＋硬券のUIで起動。スクロールも滑らか。クラッシュなし。

⚠️ **違ったら**：
- ビルドエラー → エラー文をスクショして送ってください
- 起動はするがすぐ落ちる → コンソールログのスタックトレースをコピーして送ってください

---

## ステップ 5.2：iOSウィジェットを追加

🎯 **やること**（iPhone側で操作）：

1. iPhone のホーム画面で何もない領域を**長押し**
2. 左上の **「+」** をタップ
3. 検索窓に「TetsuLog」と入力
4. 一覧に **「コレクション」** と **「廃車進行中」** が出ているはず
5. それぞれ追加してホーム画面に配置

✅ **こうなれば成功**：
- 「コレクション」に **今月の遭遇数**と**集めた編成数**が出る
- 「廃車進行中」に **形式数と代表名**が出る（記録ゼロなら「0」「対象なし」）

⚠️ **違ったら**：
- 「TetsuLog」を検索しても何も出ない → Xcode で **Product > Clean Build Folder（⇧⌘K）** してから再度 ⌘R。
- 「TetsuLog」は出るがウィジェットが追加できない → 同上のClean → ⌘R 後、iPhone再起動。
- 数字が「0」のまま動かない → **App Group 未付与**の可能性大。Phase 4.2 を見直し。

---

## ステップ 5.3：Watch アプリを動かす

🎯 **やること**：

1. Xcodeのスキーム選択で **TetsuLogWatch** を選択
2. デバイス選択で連携Apple Watchを選択（実機 or シミュレータ）
3. ⌘R

✅ **こうなれば成功**：Apple Watch にTetsuLog（今週・今月の遭遇数）画面が表示される。

⚠️ **違ったら**：
- 「No matching device」→ iPhoneとWatchがペアリング済み・iPhone側のWatch.appでWatchが認識されているか確認
- ビルドは通るがインストールできない → Watch側を一度再起動

---

## ステップ 5.4：Watch コンプリケーションを文字盤に追加

🎯 **やること**（Apple Watch側）：

1. 文字盤を**長押し** → 「編集」
2. 横スワイプして「コンプリケーション」位置の枠を選択
3. クラウン回転で「TetsuLog」を探す
4. 「今週の遭遇」を選択
5. デジタルクラウン押して確定

✅ **こうなれば成功**：文字盤に **今週の遭遇数**が小さく表示される。

⚠️ **違ったら**：
- 「TetsuLog」が一覧に出ない → Watchを一度再起動してから文字盤編集を再試行
- 出るけど「---」になっている → **App Group 未付与**。Phase 4.4 を見直し。

---

# Phase 6 — テストを走らせる（任意・推奨）

🎯 **やること**：Xcodeで

1. スキームを **TetsuLog** に戻す
2. **⌘U** を押す

✅ **こうなれば成功**：左下のテストナビゲーターで全てが緑のチェックマーク。

⚠️ **違ったら**：失敗したテスト名をスクショして送ってください。

---

# 🆘 全部やり直したい時のリカバリ

「やっぱり元の構成に戻したい」場合：

```bash
cd ~/ghost-club-lp/app
rm -rf TetsuLog.xcodeproj
mv TetsuLog.xcodeproj.bak TetsuLog.xcodeproj
open TetsuLog.xcodeproj
```

これで **v1.0 で出した実績のある単一ターゲット構成**に即復帰します。Widget/Watch は無しになりますが、本体は問題なく動きます。

---

# 完了したら

- [ ] チェックリスト全部 ✅ になった
- [ ] ウィジェットに数字が出ている
- [ ] Watch のコンプリに数字が出ている

これらが揃えば、**v1.1 として App Store に提出する準備が完了**です。

🎉 おつかれさまでした。

何か詰まったら、**ステップ番号とスクショ**を送ってください。その場で直します。
