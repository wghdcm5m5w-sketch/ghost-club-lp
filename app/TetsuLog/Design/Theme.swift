import SwiftUI

/// TetsuLog デザインシステム「国鉄レトロ・上質」。
/// アイコン（国鉄ネイビー×クリーム×赤）と統一した世界観を全画面に適用する。
enum Theme {
    // MARK: - カラートークン
    enum Palette {
        static let navy      = Color(hex: 0x10243F)   // 基調（背景・濃い面）
        static let navyDeep  = Color(hex: 0x0A1A30)   // さらに濃い背景
        static let paper      = Color(hex: 0xF2EAD8)   // 紙（カード面）
        static let paperAged  = Color(hex: 0xDDC592)   // 経年した黄ばみ紙（廃車カード用）
        static let paperEdge  = Color(hex: 0xE2D6BC)   // 紙の境界
        static let red       = Color(hex: 0xC0392B)   // 朱（アクセント・廃車・ゲージ）
        static let redLight  = Color(hex: 0xE85A48)   // 明朱：紺地上のテキスト用（AA大satisfied）
        static let ink       = Color(hex: 0x10243F)   // 紙の上の文字（紺）
        static let inkSub    = Color(hex: 0x6B5A3C)   // 紙の上の副文字（セピア）
        static let cream     = Color(hex: 0xF0E6CF)   // 暗背景上の明文字
        static let creamSub  = Color(hex: 0xB7A98A)   // 暗背景上の副文字
        static let gold      = Color(hex: 0xC9A24B)   // 金（達成・特別）
        static let goldDeep  = Color(hex: 0x8A6F1F)   // 深い金：紙の上で AA本文を満たす
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
/// `aged`=true で経年した黄ばみ紙（廃車カード等の差分用）になる。
struct PaperSurface: View {
    var aged: Bool = false

    var body: some View {
        ZStack {
            (aged ? Theme.Palette.paperAged : Theme.Palette.paper)
            Image("PaperTexture")
                .resizable(resizingMode: .tile)
                .opacity(aged ? 0.7 : 0.55)
                .blendMode(.multiply)
            // 経年版のみ、黄ばみのオーバーレイ＋角のシミ
            if aged {
                // 全体の黄ばみ
                LinearGradient(
                    colors: [Color(hex: 0xd8a44a, alpha: 0.18),
                             Color(hex: 0xc8923a, alpha: 0.10),
                             Color(hex: 0xb88438, alpha: 0.20)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ).blendMode(.multiply)
                // 角の経年シミ（4隅にラジアル）
                ForEach(0..<4) { idx in
                    let pts: [UnitPoint] = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing]
                    RadialGradient(
                        colors: [Color(hex: 0x8a5a20, alpha: 0.25), .clear],
                        center: pts[idx], startRadius: 0, endRadius: 90
                    ).blendMode(.multiply)
                }
            }
            // ごく淡い対角グラデで自然な陰影
            LinearGradient(
                colors: [Color.white.opacity(0.10), .clear, Color(hex: 0x8a, alpha: 0.05)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}

/// カードの4隅に置く「紙の反り影」。実物の紙は完全には平らでなく、
/// 隅がわずかに浮いて落ち影が発生する。それを4隅のラジアルグラデで再現。
struct PaperCornerCurl: View {
    var body: some View {
        ZStack {
            curl(at: .topLeading,     angle: 135)
            curl(at: .topTrailing,    angle: 225)
            curl(at: .bottomLeading,  angle: 45)
            curl(at: .bottomTrailing, angle: 315)
        }
        .allowsHitTesting(false)
    }
    @ViewBuilder
    private func curl(at corner: UnitPoint, angle: Double) -> some View {
        RadialGradient(
            colors: [Color.black.opacity(0.18), .clear],
            center: corner, startRadius: 0, endRadius: 36
        )
        .blendMode(.multiply)
    }
}

/// タップ時にインクが染み込むエフェクト。
/// pressed フラグが立つと小さな朱の円が現れて広がり、にじみつつ消える。
struct InkBleedOverlay: View {
    var pressed: Bool
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var origin: UnitPoint = .center

    var body: some View {
        GeometryReader { geo in
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.Palette.red.opacity(0.55),
                                 Theme.Palette.red.opacity(0.25),
                                 Theme.Palette.red.opacity(0.0)],
                        center: .center, startRadius: 0, endRadius: 80
                    )
                )
                .frame(width: max(geo.size.width, geo.size.height) * 1.6,
                       height: max(geo.size.width, geo.size.height) * 1.6)
                .position(x: geo.size.width * origin.x, y: geo.size.height * origin.y)
                .scaleEffect(scale)
                .opacity(opacity)
                .blendMode(.multiply)
                .allowsHitTesting(false)
                .onChange(of: pressed) { _, isDown in
                    if isDown {
                        // ランダム位置にインクが落ちるイメージ
                        origin = UnitPoint(x: .random(in: 0.3...0.7),
                                           y: .random(in: 0.3...0.7))
                        scale = 0.05; opacity = 0
                        withAnimation(.easeOut(duration: 0.35)) {
                            scale = 1.0; opacity = 0.9
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.55)) {
                            opacity = 0
                            scale = 1.15
                        }
                    }
                }
        }
    }
}

/// 紙質のカード（左に紺帯のオプション付き）。
/// 紙テクスチャ・厚みのエッジ・二層の柔らかい影で「本物の紙片」に仕上げる。
/// `aged`=true で廃車カード用の経年黄ばみ紙に切替。
/// `interactive`=true でタップ時のインク染み込みエフェクトを有効化。
struct PaperCard<Content: View>: View {
    var accent: Bool = true
    var aged: Bool = false
    var interactive: Bool = false
    @ViewBuilder var content: Content

    @State private var isPressed = false

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous) }

    var body: some View {
        HStack(spacing: 0) {
            if accent {
                Rectangle()
                    .fill(aged ? Theme.Palette.navy.opacity(0.78) : Theme.Palette.navy)
                    .overlay(Rectangle().fill(.white.opacity(0.08)))
                    .frame(width: 8)
            }
            content
                .padding(Theme.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(PaperSurface(aged: aged))
        .overlay(PaperCornerCurl())                          // 4隅の反り影
        .overlay(InkBleedOverlay(pressed: isPressed))        // インク染み込み
        .clipShape(shape)
        // 紙の縁（上は明るく＝光、下は濃く＝厚み）
        .overlay(
            shape.stroke(
                LinearGradient(
                    colors: aged
                        ? [Color(hex: 0xd9c08a).opacity(0.7),
                           Color(hex: 0xa88a48, alpha: 0.9),
                           Color(hex: 0x6b4a18, alpha: 0.8)]
                        : [.white.opacity(0.45),
                           Theme.Palette.paperEdge,
                           Color(hex: 0x9a8a5a, alpha: 0.6)],
                    startPoint: .top, endPoint: .bottom
                ),
                lineWidth: 1
            )
        )
        // 二層の影：近く濃い＋遠く広い＝紙が浮いている自然な影
        .shadow(color: .black.opacity(0.28), radius: 3, x: 0, y: 2)
        .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 10)
        // 押下時のわずかな沈み込み
        .scaleEffect(isPressed ? 0.985 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        // タップジェスチャ
        .gesture(
            interactive
            ? DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isPressed { isPressed = true } }
                .onEnded { _ in isPressed = false }
            : nil
        )
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
                    .fill(complete ? Theme.Palette.goldDeep : Theme.Palette.red)
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
