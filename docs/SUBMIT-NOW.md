# TetsuLog 提出 — 残りの手動作業だけ

コード／デザイン／法務ページ／審査用コピー／6.5"スクショは**すべて完成・push済み**（branch `claude/railway-app-market-analysis-B4mFr`、HEAD は最新）。
ここから先は **あなたのMac・Apple ID・リポジトリ管理権限が必要な作業**のみ。上から順にどうぞ。

---

## STEP 1 ── 最新をMacに取り込む（最優先・2分）

Xcode を終了（⌘Q）してターミナルで：

```bash
cd ~/ghost-club-lp \
 && git fetch origin \
 && git reset --hard origin/claude/railway-app-market-analysis-B4mFr \
 && rm -rf ~/Library/Developer/Xcode/DerivedData/TetsuLog-* \
 && open app/TetsuLog.xcodeproj
```

- Xcode で **TARGETS → TetsuLog → Signing & Capabilities → Team = RYO FUJIMATSU**
- **⌘R** で実機起動
- 確認：①近黒＋シアンの新デザインになっている ②スクロールが滑らか ③図鑑カードに側面図 ④遭遇記録が硬券

> `git log --oneline -1` の先頭が `perf(theme)` 系（最新）なら取り込めています。

---

## STEP 2 ── Capabilities 付与（同期/ウィジェット/通知を使うなら・要 有料Developer）

Signing & Capabilities → **＋ Capability** で追加：

| Capability | 値 |
|---|---|
| iCloud → **CloudKit** | コンテナ `iCloud.com.ryofujimatsu.tetsulog` を新規作成 |
| **App Groups** | `group.com.ryofujimatsu.tetsulog` |
| **Push Notifications** | （CloudKit同期トリガ） |
| **Background Modes** | Remote notifications |

> まず動かすだけなら STEP 2 はスキップ可（ローカル保存で起動する）。App Store提出時は付与推奨。

---

## STEP 3 ── 法務ページを公開（GitHub Pages）

アプリ内リンクと App Store は次のURLを指しています：
- プライバシー: `https://wghdcm5m5w-sketch.github.io/ghost-club-lp/tetsulog-privacy.html`
- 利用規約: `.../tetsulog-terms.html`
- 特商法: `.../tetsulog-tokushoho.html`
- サポート/マーケ(LP): `.../tetsulog.html`

**現状 `main` には旧ページしか無い**ため、上記URLを有効にするには次のどちらか：

- **方法A（推奨）**: feature ブランチを `main` にマージしてから、リポジトリ **Settings → Pages → Source = main / (root)** で公開。
  → マージは「やって」と言ってくれれば**僕が代行**します（mainへのpushは要承認のため）。
- **方法B**: Settings → Pages → Source を **`claude/railway-app-market-analysis-B4mFr` / (root)** に設定（マージ不要・すぐ公開）。

公開後、上の4URLがブラウザで開けることを確認。

---

## STEP 4 ── App Store Connect（apps）

1. **アプリ新規作成**: Bundle ID `com.ryofujimatsu.tetsulog` / 名称「TetsuLog（鉄道記録）」
2. **App内課金**: ＋ → **非消耗型** / 製品ID `com.ryofujimatsu.tetsulog.pro`（コードと完全一致）/ 価格 **¥980（Tier 9）** / 表示名「TetsuLog Pro」/ ja・en の説明
3. **契約**: 有料App契約（Paid Apps Agreement）＋ 税・銀行情報を完了（未完だとIAP申請不可）
4. **メタデータ**: `docs/app-store-assets.md` から丸ごとコピペ（アプリ名/サブタイトル/キーワード/概要/プロモ/What's New ＝ 既に日英用意済み）
5. **スクリーンショット**: `app/appstore-screenshots-6.5/`（1242×2688・7枚）をアップロード
6. **App Privacy** = **Data Not Collected**
7. **年齢レーティング** = 4+
8. **URL**: サポート/プライバシー/マーケティング（STEP 3 のURL）

---

## STEP 5 ── CloudKit スキーマ本番反映（STEP 2 を付与した場合）

1. 実機（iCloudサインイン済み）で一度起動し、記録を1件作成
2. **CloudKit Dashboard → Development スキーマ確認 → Deploy Schema to Production**

---

## STEP 6 ── ビルド提出

1. Xcode で実機/Generic device 選択 → **Product → Archive**
2. **Validate App** → 問題なければ **Distribute App → App Store Connect → Upload**
3. App Store Connect で **TestFlight** 内部テスト（任意）
4. ビルドを選択 → **審査へ提出**
   - 審査メモは `docs/app-store-assets.md` の「審査メモ」を貼付

---

## 補足

- 輸出コンプライアンス申告は**不要**（`ITSAppUsesNonExemptEncryption=false` 同梱済み）
- App Intents（Siri連携）は初回リリースでは無効化済み（ビルド安定のため。v1.1で復帰予定）
- スクショは現状モックアップ。実機が動いたら iPhone 16 Pro Max 等（6.9"/6.7"）で実画面キャプチャに差し替えるとより強い
