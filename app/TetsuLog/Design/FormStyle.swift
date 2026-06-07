import SwiftUI

/// Form を国鉄レトロ・上質の世界観に揃える共通モディファイア。
/// .formStyle(.grouped) の白背景を消し、紺地に紙のセクションが浮く見た目に。
extension View {
    /// シート/フォーム画面を世界観で包む
    func tetsuFormStyle() -> some View {
        self.modifier(TetsuFormStyle())
    }
}

private struct TetsuFormStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)        // List/Form のデフォルト背景を消す
            .background(NavyBackground())
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Theme.Palette.navy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(Theme.Palette.red)
    }
}
