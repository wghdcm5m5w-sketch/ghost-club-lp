import SwiftUI

/// TetsuLog デザインシステム「国鉄レトロ・上質」。
/// アイコン（国鉄ネイビー×クリーム×赤）と統一した世界観を全画面に適用する。
enum Theme {
    // MARK: - カラートークン
    enum Palette {
        static let navy      = Color(hex: 0x10243F)   // 基調（背景・濃い面）
        static let navyDeep  = Color(hex: 0x0A1A30)   // さらに濃い背景
        static let paper     = Color(hex: 0xF2EAD8)   // 紙（カード面）
        static let paperEdge = Color(hex: 0xE2D6BC)   // 紙の境界
        static let red       = Color(hex: 0xC0392B)   // 朱（アクセント・廃車・ゲージ）
        static let ink       = Color(hex: 0x10243F)   // 紙の上の文字（紺）
        static let inkSub    = Color(hex: 0x6B5A3C)   // 紙の上の副文字（セピア）
        static let cream     = Color(hex: 0xF0E6CF)   // 暗背景上の明文字
        static let creamSub  = Color(hex: 0xB7A98A)   // 暗背景上の副文字
        static let gold      = Color(hex: 0xC9A24B)   // 金（達成・特別）
        static let rail      = Color(hex: 0x9AA0AC)   // レール鋼色
    }

    // MARK: - タイポグラフィ
    enum Font {
        static func title(_ size: CGFloat = 28) -> SwiftUI.Font { .system(size: size, weight: .heavy, design: .serif) }
        static func headline(_ size: CGFloat = 20) -> SwiftUI.Font { .system(size: size, weight: .bold, design: .serif) }
        static func body(_ size: CGFloat = 16) -> SwiftUI.Font { .system(size: size, weight: .regular) }
        static func mono(_ size: CGFloat = 14) -> SwiftUI.Font { .system(size: size, weight: .semibold, design: .monospaced) }
    }

    // MARK: - 形状・余白
    static let cardRadius: CGFloat = 14
    static let cardPadding: CGFloat = 18
    static let screenPadding: CGFloat = 16
}

// MARK: - Color(hex:)
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

// MARK: - 共通コンポーネント

/// 紙の質感を表現する塗り（テクスチャ＋色ムラ＋紙の縁）。
/// 単色塗りではなく、実際の紙テクスチャ画像をタイル敷きして本物の質感を出す。
struct PaperSurface: View {
    var body: some View {
        ZStack {
            Theme.Palette.paper                                   // ベース色
            Image("PaperTexture")                                 // 繊維・色ムラ
                .resizable(resizingMode: .tile)
                .opacity(0.55)
                .blendMode(.multiply)
            // ごく淡い対角グラデで自然な陰影
            LinearGradient(
                colors: [Color.white.opacity(0.10), .clear, Color(hex: 0x8a, alpha: 0.05)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}

/// 紙質のカード（左に紺帯のオプション付き）。
/// 紙テクスチャ・厚みのエッジ・二層の柔らかい影で「本物の紙片」に仕上げる。
struct PaperCard<Content: View>: View {
    var accent: Bool = true
    @ViewBuilder var content: Content

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous) }

    var body: some View {
        HStack(spacing: 0) {
            if accent {
                Rectangle()
                    .fill(Theme.Palette.navy)
                    .overlay(Rectangle().fill(.white.opacity(0.08)))   // 帯のわずかな光沢
                    .frame(width: 8)
            }
            content
                .padding(Theme.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(PaperSurface())
        .clipShape(shape)
        // 紙の縁（上は明るく＝光、下は濃く＝厚み）
        .overlay(
            shape.stroke(
                LinearGradient(
                    colors: [.white.opacity(0.45), Theme.Palette.paperEdge, Color(hex: 0x9a8a5a, alpha: 0.6)],
                    startPoint: .top, endPoint: .bottom
                ),
                lineWidth: 1
            )
        )
        // 二層の影：近く濃い＋遠く広い＝紙が浮いている自然な影
        .shadow(color: .black.opacity(0.28), radius: 3, x: 0, y: 2)
        .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 10)
    }
}

/// 方向幕風の見出し帯（上下に朱ライン）
struct MakuHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Theme.Palette.red).frame(height: 4)
            HStack {
                Text(title)
                    .font(Theme.Font.title(30))
                    .foregroundStyle(Theme.Palette.ink)
                    .tracking(4)
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(Theme.Font.mono(28))
                        .foregroundStyle(Theme.Palette.red)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            Rectangle().fill(Theme.Palette.red).frame(height: 4)
        }
        .background(PaperSurface())
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 3, x: 0, y: 2)
        .shadow(color: .black.opacity(0.14), radius: 12, x: 0, y: 8)
    }
}

/// 罫線ゲージ（収集率など）
struct RailGauge: View {
    var ratio: Double
    var complete: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Theme.Palette.paperEdge)
                    .frame(height: 4)
                Rectangle()
                    .fill(complete ? Theme.Palette.gold : Theme.Palette.red)
                    .frame(width: geo.size.width * ratio, height: 8)
            }
        }
        .frame(height: 8)
    }
}

/// 廃車・ラストランなどの朱バッジ
struct InkBadge: View {
    let text: String
    var filled: Bool = true
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(filled ? Theme.Palette.paper : Theme.Palette.red)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(
                Capsule().fill(filled ? Theme.Palette.red : Color.clear)
            )
            .overlay(Capsule().stroke(Theme.Palette.red, lineWidth: filled ? 0 : 1.5))
    }
}

/// 画面全体の紺背景
struct NavyBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Theme.Palette.navy, Theme.Palette.navyDeep],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
