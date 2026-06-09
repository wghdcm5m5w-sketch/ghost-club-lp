import Foundation

// MARK: - App Intents（v1.1 で再有効化予定）
//
// ⚠️ 一時無効化:
// Xcode の "AppIntentsSSUTraining" ビルドステップ（Siri 用メタデータ抽出）が
// nonzero exit で失敗するため、初回リリースでは App Intents をすべて無効化する。
// このファイルにはどこからも参照されていない LogSightingIntent / StartRideIntent /
// TetsuLogShortcuts のみが含まれていたため、無効化してもアプリの動作には影響しない。
//
// 元の実装は git 履歴（コミット 29e320c 以前）に保存済み。
// ツールチェーンが安定したら復元し、Siri/ショートカット連携を再有効化する。
