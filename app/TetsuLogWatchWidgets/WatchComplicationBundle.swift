import WidgetKit
import SwiftUI

/// watchOS コンプリケーション拡張のエントリ。
/// TetsuLogWatch アプリに埋め込まれる別ターゲット。
/// 共有: TetsuLog/Models/Models.swift, SharedStore.swift（Membership / project.yml で指定）。
@main
struct WatchComplicationBundle: WidgetBundle {
    var body: some Widget {
        SightingComplication()
    }
}
