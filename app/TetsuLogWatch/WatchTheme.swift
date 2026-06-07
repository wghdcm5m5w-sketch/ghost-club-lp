import SwiftUI

/// watchOS 用の縮小デザインシステム。
/// 本体（iOS）の Theme と同じ色・思想を、小画面向けにサイズ調整して移植。
enum WatchTheme {
    enum Palette {
        static let navy   = Color(red: 0x10/255, green: 0x24/255, blue: 0x3F/255)
        static let paper  = Color(red: 0xF2/255, green: 0xEA/255, blue: 0xD8/255)
        static let red    = Color(red: 0xC0/255, green: 0x39/255, blue: 0x2B/255)
        static let ink    = Color(red: 0x10/255, green: 0x24/255, blue: 0x3F/255)
        static let inkSub = Color(red: 0x6B/255, green: 0x5A/255, blue: 0x3C/255)
        static let cream  = Color(red: 0xF0/255, green: 0xE6/255, blue: 0xCF/255)
        static let gold   = Color(red: 0xC9/255, green: 0xA2/255, blue: 0x4B/255)
    }
}

/// 小画面用の紙カード（テクスチャは省略、色とエッジで質感を出す）
struct WatchPaperCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(WatchTheme.Palette.paper)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(LinearGradient(colors: [.white.opacity(0.4), .black.opacity(0.2)],
                                           startPoint: .top, endPoint: .bottom), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
    }
}

/// 紺地の背景
struct WatchNavyBackground: View {
    var body: some View {
        LinearGradient(colors: [WatchTheme.Palette.navy, .black],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}
