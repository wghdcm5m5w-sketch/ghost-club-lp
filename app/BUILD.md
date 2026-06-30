# TetsuLog — ビルド手順（重要）

このプロジェクトは **XcodeGen** で管理している。`project.yml` が唯一の正
(source of truth) で、`TetsuLog.xcodeproj` と各 `*.entitlements` は
**そこから生成する成果物**。どちらも `.gitignore` 済みで git には含めない。

## なぜ .xcodeproj を git 管理しないか
以前は単一ターゲットの古い `.xcodeproj` が commit されており、
それをそのままビルドすると **ウィジェット・Apple Watch ターゲットが抜けた
不完全なアプリ** が出来てしまう状態だった（リリース事故の温床）。
`project.yml` だけを正とし、毎回生成することでこの不整合を恒久的に防ぐ。

## ビルドする（毎回）
```sh
cd app
brew install xcodegen      # 初回のみ
xcodegen generate          # project.yml → TetsuLog.xcodeproj / *.entitlements を生成
open TetsuLog.xcodeproj    # Xcode で開いてビルド/アーカイブ
```

`xcodegen generate` は次を毎回作り直す:
- `TetsuLog.xcodeproj`（5ターゲット: 本体 / Tests / iOSウィジェット / Watchアプリ / Watchコンプリ）
- 各ターゲットの `*.entitlements`（App Group / iCloud(CloudKit)）
- 各ターゲットの共有スキーム

> Push (aps-environment) は entitlements に固定していない。CloudKit の基本同期には
> 不要で、App ID に Push が無い状態でアーカイブ署名が失敗するのを避けるため。
> プッシュ更新型ライブアクティビティ等で必要になったら、Xcode で Push Notifications を
> 有効化し、project.yml の本体 `entitlements:` に `aps-environment: development` を追記する。

→ Xcode の Signing & Capabilities を手で触る必要はない。手で触っても
次の `xcodegen generate` で project.yml の内容に戻る。Capability を増減
したいときは **project.yml の `entitlements:` を編集**すること。

## 署名 (DEVELOPMENT_TEAM)
`project.yml` の `settings.base.DEVELOPMENT_TEAM` に Apple Developer の
Team ID を設定済み。別アカウントでビルドするときはここを書き換える
（Xcode › Settings › Accounts、または developer.apple.com › Membership）。
`CODE_SIGN_STYLE: Automatic` なので、有料アカウントなら不足している
Capability（iCloud/App Groups/Push）は Xcode が App ID に自動登録する。

## 検証コマンド（リリース前）
```sh
cd app
xcodegen generate
xcodebuild -list -project TetsuLog.xcodeproj
xcodebuild -project TetsuLog.xcodeproj -scheme TetsuLog \
  -destination 'generic/platform=iOS' build
xcodebuild -project TetsuLog.xcodeproj -scheme TetsuLog \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```
