# TetsuLog を iPhone 実機で動かす手順

> 前提: **Mac（Xcode 16以降）が必要**です。クラウド上のこのリポジトリから直接iPhoneへは入れられません。
> このリポジトリを Mac に clone し、下記の手順で実機にインストールします。

---

## 0. まず結論：2段階で進める

| 段階 | 構成 | 必要なもの | 何が動く |
|---|---|---|---|
| **STEP 1（推奨・まず動かす）** | 本体アプリのみ・ローカル保存 | **無料のApple IDでOK** | 図鑑/記録/地図/統計/撮影地/順光/カメラOCR。**端末内保存**（同期なし） |
| **STEP 2（フル機能）** | + CloudKit同期 + ウィジェット + ライブアクティビティ | **有料 Apple Developer Program ($99/年)** | 上記 + iCloud同期・ウィジェット・Dynamic Island |

まずは STEP 1 で「手に持って触れる」状態を最短で作るのがおすすめです。

---

## STEP 1: 最小構成で実機にインストール

### 1-1. リポジトリを Mac に取得して開く
**Xcodeプロジェクトはコミット済み**なので、生成作業は不要です。
```bash
git clone <このリポジトリのURL>
cd ghost-club-lp/app
open TetsuLog.xcodeproj      # ダブルクリックでも可
```
> 全Swiftファイルはフォルダ同期で自動取り込み済み。ファイルのドラッグ＆ドロップは不要です。

### 1-3. 署名（Signing）を設定
1. Xcode左のプロジェクト → TARGETS の **TetsuLog** を選択
2. **Signing & Capabilities** タブ
3. **Team** で自分のApple ID（無料でも可）を選択
   - 初回は Xcode → Settings → Accounts で Apple ID を追加
4. **Bundle Identifier** が他と重複するとエラー → `com.<自分の名前>.tetsulog` 等に変更

### 1-4. iPhone を接続
- **USBケーブル接続が最も確実**（インターネット共有中でもUSBが安定）。
- 初回は iPhone 側で「このコンピュータを信頼しますか？」→ 信頼。
- ワイヤレスにする場合: 一度USB接続し、Xcode → Window → Devices and Simulators →「Connect via network」にチェック。以後は同一ネットワーク（インターネット共有のネットワークでも可）で接続可。

### 1-5. ビルド先を実機に
- Xcode 上部のスキーム横のデバイス選択で、**自分のiPhone** を選ぶ。
- ⌘R（Run）。

### 1-6. iPhone 側で開発者を信頼
初回起動時に「信頼されていないデベロッパ」と出たら：
- iPhone → 設定 → 一般 → **VPNとデバイス管理** → 自分のApple IDを **信頼**。
- 再度アプリを起動。

✅ これでオンボーディング → 図鑑（52形式入り）が表示されれば成功。
記録を追加すると図鑑が埋まり、統計・地図・撮影地の順光計算まで触れます。

> ⚠️ 無料アカウントの制限: ビルドした実機アプリは**7日で期限切れ**（再ビルドで延長）。同時にインストールできるアプリ数にも制限あり。常用するなら STEP 2（有料）へ。

---

## STEP 2: フル機能（CloudKit / ウィジェット / ライブアクティビティ）

有料 Apple Developer Program 登録後に行います。

### 2-1. Capabilities を追加（TetsuLog ターゲット）
Signing & Capabilities → ＋ Capability で以下を追加:
- **iCloud** → CloudKit にチェック → コンテナ `iCloud.com.<自分>.tetsulog` を作成
- **App Groups** → `group.com.<自分>.tetsulog` を追加
- **Push Notifications**（CloudKit同期トリガ用）
- **Background Modes** → Remote notifications

### 2-2. コード内のIDを置換
以下のファイルの `com.yourname` / `iCloud.com.yourname.tetsulog` / `group.com.yourname.tetsulog` を、上で作った実IDに置換:
- `TetsuLog/Models/SharedStore.swift`
- `TetsuLog/TetsuLogApp.swift`

### 2-3. ウィジェット拡張を追加
1. Xcode → File → New → Target → **Widget Extension**（名前 `TetsuLogWidgets`、Include Live Activity にチェック）
2. `app/TetsuLogWidgets/` の3ファイルを、このターゲットに追加
3. 共有ファイル（Target Membership を本体＋Widget両方に）:
   - `Models/Models.swift`
   - `Models/SharedStore.swift`
   - `Features/RideActivityAttributes.swift`
4. Widgetターゲットにも iCloud + App Groups capability を追加（同じID）

### 2-4. 多言語リソースを追加
- `TetsuLog/Resources/Localizable.xcstrings` と `InfoPlist.xcstrings` をプロジェクトに追加し、ターゲットに含める。

詳細な落とし穴は `docs/build-troubleshooting.md` を参照。

---

## つまずいたら

| 症状 | 対処 |
|---|---|
| `xcodegen: command not found` | `brew install xcodegen` |
| 署名エラー | Bundle ID を一意に変更、Team を選択 |
| 「信頼されていないデベロッパ」 | 設定→一般→VPNとデバイス管理 で信頼 |
| カメラ画面が黒い | カメラOCRは実機のみ（シミュレータ不可） |
| 7日で起動できなくなった | 無料アカウントの仕様。再度⌘Rで延長 |
| iPhoneが選べない | USB接続→信頼、Xcode→Devicesで認識確認 |

---

## 補足: インターネット共有環境について

- iPhoneのインターネット共有でMacをネットにつないでいる状態でも、実機ビルドは可能です。
- **デバイス認識は「USB接続」か「同一ネットワークのワイヤレスデバッグ」**で行います。インターネット共有のネットワーク自体がビルドに使われるわけではありません。
- 最も確実なのは **Lightning/USB-Cケーブルでの直結**。まずはこれを推奨します。
