import SwiftUI

/// Widget Extension 用のカラー定義（本体 Theme と同じ値）。
/// Widget拡張は本体ターゲットの Theme.swift を共有しないため、独立して持つ。
enum WidgetTheme {
    static let navy   = Color(red: 0x10/255, green: 0x24/255, blue: 0x3F/255)
    static let navyD  = Color(red: 0x0A/255, green: 0x1A/255, blue: 0x30/255)
    static let paper  = Color(red: 0xF2/255, green: 0xEA/255, blue: 0xD8/255)
    static let red    = Color(red: 0xC0/255, green: 0x39/255, blue: 0x2B/255)
    static let cream  = Color(red: 0xF0/255, green: 0xE6/255, blue: 0xCF/255)
    static let creamSub = Color(red: 0xB7/255, green: 0xA9/255, blue: 0x8A/255)
    static let gold   = Color(red: 0xC9/255, green: 0xA2/255, blue: 0x4B/255)
    static let ink    = Color(red: 0x10/255, green: 0x24/255, blue: 0x3F/255)
    static let inkSub = Color(red: 0x6B/255, green: 0x5A/255, blue: 0x3C/255)

    static var navyGradient: LinearGradient {
        LinearGradient(colors: [navy, navyD], startPoint: .top, endPoint: .bottom)
    }
}
