import WidgetKit
import SwiftUI

/// Widget Extension のエントリ。
/// アプリ本体とは別ターゲット。RideAttributes.swift / Models.swift を
/// このターゲットの Membership にも追加して共有する。
@main
struct TetsuLogWidgetBundle: WidgetBundle {
    var body: some Widget {
        CollectionWidget()
        RideLiveActivity()
    }
}
