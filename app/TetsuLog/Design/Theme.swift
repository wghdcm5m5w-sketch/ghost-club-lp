import SwiftUI

/// TetsuLog デザインシステム「ハイブリッド（案C）」。
/// 地＝近黒＋余白（⑤プレミアム）／骨格＝形式図・側面図のシアン製図（④）／
/// 温度＝遭遇詳細・Proだけ硬券のクリーム紙（①）。
/// 冷たい技術と温かい紙のコントラストそのものが世界観。
enum Theme {
    // MARK: - カラートークン
    enum Palette {
        // 背景・構造（近黒）。toolbar/ナビ等の構造色に navy を使う。
        static let navy      = Color(hex: 0x0E1420)   // 近黒（ツールバー・構造・背景上）
        static let navyDeep  = Color(hex: 0x070A10)   // さらに濃い背景下
        static let bg        = Color(hex: 0x0A0D12)
        static let bg2       = Color(hex: 0x11151D)

        // ダークガラス面（標準カード）
        static let surface     = Color(hex: 0x161B24)
        static let surface2    = Color(hex: 0x1C2330)
        static let surfaceEdge = Color(hex: 0x2A313D)

        // 技術アクセント（シアン）
        static let cyan      = Color(hex: 0x5FD0FF)
        static let cyanDim   = Color(hex: 0x84A7C2)

        // 硬券の紙（TicketCard / ShareCard 専用に温存）
        static let paper      = Color(hex: 0xECE0C2)   // クリーム紙
        static let paperAged  = Color(hex: 0xDCC794)   // 経年した黄ばみ紙
        static let paperEdge  = Color(hex: 0x2A313D)   // 暗面カード上の細い罫線/ゲージ軌道
        static let paperInk   = Color(hex: 0x251B10)   // 紙の上の文字（濃茶）
        static let paperInkSub = Color(hex: 0x7A6A48)  // 紙の上の副文字（セピア）

        // アクセント
        static let red       = Color(hex: 0xD8483A)   // 朱（特急・廃車・ラストラン・ゲージ）
        static let redLight  = Color(hex: 0xFF6A57)   // 明朱
        static let gold      = Color(hex: 0xD4AF5A)   // 金
        static let goldDeep  = Color(hex: 0xE3C36B)   // 明るい金（暗面の達成・コンプリート）

        // 暗面上の文字
        static let ink       = Color(hex: 0xE7ECF3)   // カード上の主文字（明）
        static let inkSub    = Color(hex: 0x94A1B2)   // カード上の副文字
        static let cream     = Color(hex: 0xEAF0F7)   // 背景上の明文字（クール白）
        static let creamSub  = Color(hex: 0x93A0B1)   // 背景上の副文字
        static let rail      = Color(hex: 0x6E7C8C)   // レール鋼色・無効
    }

    // MARK: - タイポグラフィ
    enum Font {
        static func title(_ size: CGFloat = 28) -> SwiftUI.Font { .system(size: size, weight: .heavy) }
        static func headline(_ size: CGFloat = 20) -> SwiftUI.Font { .system(size: size, weight: .bold) }
        static func body(_ size: CGFloat = 16) -> SwiftUI.Font { .system(size: size, weight: .regular) }
        static func mono(_ size: CGFloat = 14) -> SwiftUI.Font { .system(size: size, weight: .semibold, design: .monospaced) }
        /// 硬券の見出し（明朝＝serif）
        static func serif(_ size: CGFloat = 20, _ weight: SwiftUI.Font.Weight = .heavy) -> SwiftUI.Font { .system(size: size, weight: weight, design: .serif) }
    }

    // MARK: - 形状・余白
    static let cardRadius: CGFloat = 16
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

// MARK: - 背景（近黒プレミアム＋微グリッド）

/// 画面全体の背景。近黒のラジアル＋ごく薄い製図グリッド。
struct NavyBackground: View {
    var grid: Bool = true
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Theme.Palette.bg2, Theme.Palette.navyDeep],
                center: .init(x: 0.5, y: -0.05), startRadius: 8, endRadius: 720
            )
            if grid { BlueprintGrid().opacity(0.5) }
        }
        .ignoresSafeArea()
    }
}

/// 製図グリッド（19pt方眼）。技術トーンの薄い下地。
/// drawingGroup() でビットマップ化し、画面の上をスクロールしても再描画しない。
struct BlueprintGrid: View {
    var spacing: CGFloat = 19
    var color: Color = Color(hex: 0x96C8F0, alpha: 0.05)
    var body: some View {
        Canvas { ctx, size in
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width { path.move(to: .init(x: x, y: 0)); path.addLine(to: .init(x: x, y: size.height)); x += spacing }
            var y: CGFloat = 0
            while y <= size.height { path.move(to: .init(x: 0, y: y)); path.addLine(to: .init(x: size.width, y: y)); y += spacing }
            ctx.stroke(path, with: .color(color), lineWidth: 1)
        }
        .allowsHitTesting(false)
        .drawingGroup()
    }
}

// MARK: - 硬券の紙テクスチャ（TicketCard / ShareCard 用に温存）

/// 紙の質感（クリーム＋地紋）。硬券・シェアカードの下地。
/// パフォーマンス方針: drawingGroup() は使わない（1枚ずつ GPU テクスチャを確保
/// するため、LazyVGrid/ScrollView 内で大量のカードに付けるとメモリ上限を超える）。
/// 地紋の Canvas は SwiftUI のレンダラに任せる。
struct PaperSurface: View {
    var aged: Bool = false
    var body: some View {
        ZStack {
            (aged ? Theme.Palette.paperAged : Theme.Palette.paper)
            // 地紋（偽造防止模様）：細い斜線のクロスハッチ
            Canvas { ctx, size in
                let c = Color(hex: 0x3C2D14, alpha: aged ? 0.07 : 0.05)
                for d in stride(from: -size.height, through: size.width, by: 7) {
                    var p = Path(); p.move(to: .init(x: d, y: 0)); p.addLine(to: .init(x: d + size.height, y: size.height))
                    ctx.stroke(p, with: .color(c), lineWidth: 1)
                    var q = Path(); q.move(to: .init(x: d, y: size.height)); q.addLine(to: .init(x: d + size.height, y: 0))
                    ctx.stroke(q, with: .color(c), lineWidth: 1)
                }
            }
            if aged {
                LinearGradient(colors: [Color(hex: 0xd8a44a, alpha: 0.18), Color(hex: 0xb88438, alpha: 0.20)],
                               startPoint: .topLeading, endPoint: .bottomTrailing).blendMode(.multiply)
            }
            LinearGradient(colors: [Color.white.opacity(0.12), .clear], startPoint: .top, endPoint: .bottom)
        }
    }
}

/// （互換のため定義を維持）紙の反り影。ダークガラスでは未使用。
struct PaperCornerCurl: View {
    var body: some View { Color.clear.allowsHitTesting(false) }
}

/// タップ時のインク染み込み（押下ハイライト）。
/// パフォーマンス重視で簡素化：押下中だけシアンの半透明オーバーレイを薄く出す。
/// 旧版は GeometryReader + Canvas + onChange で常時描画していたためスクロールを重くしていた。
struct InkBleedOverlay: View {
    var pressed: Bool
    var body: some View {
        Theme.Palette.cyan
            .opacity(pressed ? 0.10 : 0)
            .allowsHitTesting(false)
            .animation(.easeOut(duration: 0.18), value: pressed)
    }
}

// MARK: - 標準カード（ダークガラス＋シアン帯）

/// ダークガラスのカード。`accent`=true で左にシアンの帯。
/// `aged`=true で廃車差分（レール鋼色の帯＋やや沈んだ面）。
///
/// パフォーマンス方針：
/// - DragGesture によるバネ駆動アニメーションは外した。
///   親が Button/NavigationLink ならシステムの押下フィードバックで充分で、
///   かつスクロール中に指が触れて誤発火する“揺れ”の原因になっていた。
/// - 影は近距離 1 枚に絞り、ぼかし半径も控えめに（合成コストを半減）。
struct PaperCard<Content: View>: View {
    var accent: Bool = true
    var aged: Bool = false
    var interactive: Bool = false   // 互換のため残す。動作は無効化。
    @ViewBuilder var content: Content

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous) }

    var body: some View {
        HStack(spacing: 0) {
            if accent {
                Rectangle()
                    .fill(aged ? Theme.Palette.rail : Theme.Palette.cyan)
                    .frame(width: 4)
                    .opacity(aged ? 0.7 : 0.9)
            }
            content
                .padding(Theme.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: aged
                    ? [Theme.Palette.surface.opacity(0.7), Theme.Palette.bg2]
                    : [Theme.Palette.surface, Theme.Palette.surface.opacity(0.6)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(shape)
        .overlay(shape.stroke(Theme.Palette.surfaceEdge, lineWidth: 1))
        .shadow(color: .black.opacity(0.30), radius: 8, x: 0, y: 5)
    }
}

// MARK: - 硬券カード（クリーム）

/// 硬券スタイルのカード。遭遇詳細・Pro・地図ポップに使う。
/// `edge` で券種色（赤＝特急/青＝普通/緑）を表す左帯。`aged`=true で黄ばみ紙。
/// （共有画像用の固定レイアウト硬券は ShareCardView.TicketCard、別物）
struct KikenCard<Content: View>: View {
    var edge: Color = Theme.Palette.red
    var aged: Bool = false
    @ViewBuilder var content: Content
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 6, style: .continuous) }
    var body: some View {
        content
            .padding(.vertical, 14).padding(.trailing, 15).padding(.leading, 19)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PaperSurface(aged: aged))
            .overlay(alignment: .leading) { Rectangle().fill(edge).frame(width: 7) }
            .overlay(shape.inset(by: 5).stroke(Color(hex: 0x46341A, alpha: 0.45), lineWidth: 1))
            .clipShape(shape)
            .shadow(color: .black.opacity(0.42), radius: 8, x: 0, y: 5)
    }
}

/// 硬券の小書き（「下車前途無効」等）
struct TicketMicroprint: View {
    var text: String = "下車前途無効 ・ 通用発売当日限り"
    var body: some View {
        Text(text).font(.system(size: 8)).foregroundStyle(Color(hex: 0x9A875F))
    }
}

/// ダッチング日付印
struct DatingStamp: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundStyle(Color(hex: 0x3A2F4E))
            .rotationEffect(.degrees(-1.4))
    }
}

// MARK: - 車両側面図（製図）

/// 形式の側面図を Canvas で描く。1両ぶん or 編成（kinds 配列）。
struct CarDiagram: View {
    enum Kind { case cab, motor, plain, loco }
    var kinds: [Kind]
    var stroke: Color = Theme.Palette.cyan
    var height: CGFloat = 26

    init(_ kinds: [Kind], stroke: Color = Theme.Palette.cyan, height: CGFloat = 26) {
        self.kinds = kinds; self.stroke = stroke; self.height = height
    }

    var body: some View {
        Canvas { ctx, size in
            let n = max(kinds.count, 1)
            let gap: CGFloat = n > 1 ? 3 : 0
            let cw = (size.width - gap * CGFloat(n - 1)) / CGFloat(n)
            for (i, kind) in kinds.enumerated() {
                let x = CGFloat(i) * (cw + gap)
                drawCar(ctx, kind: kind, rect: CGRect(x: x, y: 0, width: cw, height: size.height), facingRight: i >= n - 1 && n > 1)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)   // 装飾的な側面図。情報は近接のテキストが伝える
    }

    private func drawCar(_ ctx: GraphicsContext, kind: Kind, rect: CGRect, facingRight: Bool) {
        let bodyTop = rect.minY + rect.height * 0.30
        let bodyH = rect.height * 0.46
        let bodyRect = CGRect(x: rect.minX + 1, y: bodyTop, width: rect.width - 2, height: bodyH)
        var body = Path()

        switch kind {
        case .cab:
            // 傾斜した前面（先頭車）
            let r: CGFloat = 3
            if facingRight {
                body.move(to: .init(x: bodyRect.minX, y: bodyRect.minY))
                body.addLine(to: .init(x: bodyRect.maxX - 6, y: bodyRect.minY))
                body.addLine(to: .init(x: bodyRect.maxX, y: bodyRect.minY + 5))
                body.addLine(to: .init(x: bodyRect.maxX, y: bodyRect.maxY))
                body.addLine(to: .init(x: bodyRect.minX, y: bodyRect.maxY))
                body.closeSubpath()
            } else {
                body.move(to: .init(x: bodyRect.minX + 6, y: bodyRect.minY))
                body.addLine(to: .init(x: bodyRect.maxX, y: bodyRect.minY))
                body.addLine(to: .init(x: bodyRect.maxX, y: bodyRect.maxY))
                body.addLine(to: .init(x: bodyRect.minX, y: bodyRect.maxY))
                body.addLine(to: .init(x: bodyRect.minX, y: bodyRect.minY + 5))
                body.closeSubpath()
            }
            _ = r
        case .motor:
            body.addRoundedRect(in: bodyRect, cornerSize: .init(width: 3, height: 3))
            // パンタグラフ（屋根上の菱形）
            var pan = Path()
            let px = bodyRect.midX, py = bodyRect.minY
            pan.move(to: .init(x: px - 6, y: py)); pan.addLine(to: .init(x: px - 2, y: py - 5))
            pan.addLine(to: .init(x: px + 2, y: py - 5)); pan.addLine(to: .init(x: px + 6, y: py))
            ctx.stroke(pan, with: .color(stroke), lineWidth: 1)
        case .plain:
            body.addRoundedRect(in: bodyRect, cornerSize: .init(width: 3, height: 3))
        case .loco:
            // 機関車：運転台がボディ端で一段下がる
            let inset: CGFloat = bodyRect.width * 0.16
            let inner = bodyRect.insetBy(dx: inset, dy: 0)
            body.addRoundedRect(in: CGRect(x: inner.minX, y: bodyRect.minY, width: inner.width, height: bodyH), cornerSize: .init(width: 2, height: 2))
            var skirtL = Path(); skirtL.addRect(CGRect(x: bodyRect.minX, y: bodyTop + 2, width: inset, height: bodyH - 2))
            var skirtR = Path(); skirtR.addRect(CGRect(x: bodyRect.maxX - inset, y: bodyTop + 2, width: inset, height: bodyH - 2))
            ctx.stroke(skirtL, with: .color(stroke), lineWidth: 1.2)
            ctx.stroke(skirtR, with: .color(stroke), lineWidth: 1.2)
        }
        ctx.stroke(body, with: .color(stroke), lineWidth: 1.3)

        // 窓
        let winY = bodyTop + bodyH * 0.22
        let winH = bodyH * 0.34
        let winColor = stroke.opacity(0.42)
        let count = max(Int(bodyRect.width / 9), 2)
        let inset: CGFloat = kind == .cab ? 8 : 5
        let usable = bodyRect.width - inset * 2
        let step = usable / CGFloat(count)
        for w in 0..<count {
            let wx = bodyRect.minX + inset + CGFloat(w) * step + step * 0.18
            var win = Path(); win.addRect(CGRect(x: wx, y: winY, width: step * 0.5, height: winH))
            ctx.fill(win, with: .color(winColor))
        }

        // 台車（車輪）
        let wheelY = bodyRect.maxY + rect.height * 0.10
        for wx in [bodyRect.minX + bodyRect.width * 0.22, bodyRect.maxX - bodyRect.width * 0.22] {
            var wheel = Path(); wheel.addEllipse(in: CGRect(x: wx - 2.2, y: wheelY - 2.2, width: 4.4, height: 4.4))
            ctx.stroke(wheel, with: .color(stroke), lineWidth: 1)
        }
    }
}

// MARK: - 円弧ゲージ（統計）

/// 半円の円弧ゲージ。`ratio`(0–1) ぶんシアンで満ちる。
struct GaugeArc: View {
    var ratio: Double
    var lineWidth: CGFloat = 9
    var body: some View {
        Canvas { ctx, size in
            let r = (min(size.width, size.height * 2) - lineWidth) / 2
            let center = CGPoint(x: size.width / 2, y: size.height - lineWidth / 2)
            func arc(_ frac: Double) -> Path {
                var p = Path()
                p.addArc(center: center, radius: r,
                         startAngle: .degrees(180), endAngle: .degrees(180 + 180 * frac), clockwise: false)
                return p
            }
            ctx.stroke(arc(1), with: .color(Theme.Palette.surfaceEdge), style: .init(lineWidth: lineWidth, lineCap: .round))
            ctx.stroke(arc(max(0, min(1, ratio))), with: .color(Theme.Palette.cyan), style: .init(lineWidth: lineWidth, lineCap: .round))
        }
    }
}

// MARK: - 見出し（プレミアム）

/// 画面見出し。小さなモノスペースの英字 kicker ＋大きな和文タイトル。
struct MakuHeader: View {
    let title: String
    var trailing: String? = nil
    var kicker: String = "TETSULOG"

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(kicker)
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                .tracking(4)
                .foregroundStyle(Theme.Palette.cyanDim)
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 27, weight: .heavy))
                    .foregroundStyle(Theme.Palette.cream)
                    .tracking(2)
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(Theme.Font.mono(15))
                        .foregroundStyle(Theme.Palette.cyanDim)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

// MARK: - ゲージ（収集率など）

struct RailGauge: View {
    var ratio: Double
    var complete: Bool = false
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Palette.surfaceEdge).frame(height: 5)
                Capsule()
                    .fill(complete ? Theme.Palette.goldDeep : Theme.Palette.cyan)
                    .frame(width: max(0, geo.size.width * ratio), height: 6)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - バッジ

/// 朱バッジ（廃車・ラストラン等）
struct InkBadge: View {
    let text: String
    var filled: Bool = true
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(filled ? Color.white : Theme.Palette.redLight)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Capsule().fill(filled ? Theme.Palette.red : Color.clear))
            .overlay(Capsule().stroke(Theme.Palette.redLight, lineWidth: filled ? 0 : 1.5))
    }
}
