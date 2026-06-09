import SwiftUI

/// 遭遇記録を「硬券（こうけん）」風の画像にして共有する。
/// 撮り鉄がXなどへ投稿する文化に寄り添い、アプリの世界観のまま拡散できる。
/// ImageRenderer で UIImage 化し、ShareLink で共有する。

/// 硬券デザインのカード（共有画像としてレンダリングされる固定レイアウト）
struct TicketCard: View {
    let className: String
    let formationCode: String
    let lineName: String
    let stationName: String
    let date: Date
    var headmark: String = ""
    var isLastRun: Bool = false

    // 硬券比率（エドモンソン券に近い横長）。@3x想定で実寸の3倍で描く前提。
    static let size = CGSize(width: 690, height: 420)

    var body: some View {
        ZStack {
            // 紙地（テクスチャ＋クリーム）
            PaperSurface()

            // 地紋（細い斜線パターン）
            Canvas { ctx, size in
                let step: CGFloat = 14
                var x: CGFloat = -size.height
                while x < size.width {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                    ctx.stroke(path, with: .color(Theme.Palette.navy.opacity(0.04)), lineWidth: 1)
                    x += step
                }
            }

            // 朱の二重枠
            RoundedRectangle(cornerRadius: 6).stroke(Theme.Palette.red, lineWidth: 4)
                .padding(14)
            RoundedRectangle(cornerRadius: 3).stroke(Theme.Palette.red.opacity(0.5), lineWidth: 1)
                .padding(20)

            HStack(spacing: 0) {
                // 左の縦帯「遭遇記録」
                ZStack {
                    Rectangle().fill(Theme.Palette.navy)
                    VStack(spacing: 8) {
                        Text(isLastRun ? "記念" : "遭遇")
                            .font(.system(size: 30, weight: .heavy, design: .serif))
                        Text("記録")
                            .font(.system(size: 30, weight: .heavy, design: .serif))
                    }
                    .foregroundStyle(Theme.Palette.cream)
                }
                .frame(width: 92)
                .padding(.vertical, 28)
                .padding(.leading, 28)

                // 券面本体
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("TETSULOG 鉄道遭遇券")
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .tracking(2)
                            .foregroundStyle(Theme.Palette.inkSub)
                        Spacer()
                        if isLastRun {
                            Text("LAST RUN")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundStyle(Theme.Palette.red)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.Palette.red, lineWidth: 1.5))
                        }
                    }
                    .padding(.top, 36)

                    Spacer(minLength: 0)

                    // 形式・編成（主役）
                    Text(className)
                        .font(.system(size: 48, weight: .heavy, design: .serif))
                        .foregroundStyle(Theme.Palette.ink)
                        .lineLimit(1).minimumScaleFactor(0.6)
                    Text(formationCode.isEmpty ? " " : formationCode)
                        .font(.system(size: 30, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.Palette.red)

                    if !headmark.isEmpty {
                        Text("〔\(headmark)〕")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.Palette.inkSub)
                    }

                    Spacer(minLength: 0)

                    // 券面下段：路線・駅・日付
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lineName.isEmpty ? "—" : lineName)
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundStyle(Theme.Palette.ink)
                            Text(stationName.isEmpty ? "" : "\(stationName) にて")
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.Palette.inkSub)
                        }
                        Spacer()
                        Text(date, format: .dateTime.year().month().day())
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.Palette.ink)
                    }
                    .padding(.bottom, 36)
                }
                .padding(.horizontal, 28)

                // 右のミシン目＋通し番号
                VStack {
                    Text(serial)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.Palette.inkSub)
                        .rotationEffect(.degrees(90))
                        .fixedSize()
                        .frame(width: 28)
                }
                .frame(width: 40)
                .padding(.vertical, 28)
                .padding(.trailing, 22)
                .overlay(alignment: .leading) {
                    // ミシン目（縦の点線）
                    VStack(spacing: 6) {
                        ForEach(0..<22, id: \.self) { _ in
                            Circle().fill(Theme.Palette.inkSub.opacity(0.4)).frame(width: 3, height: 3)
                        }
                    }
                }
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var serial: String {
        // 日付ベースの擬似通し番号（券らしさの演出）
        let f = DateFormatter(); f.dateFormat = "yyMMdd"
        return "No. \(f.string(from: date))-\(abs(formationCode.hashValue) % 1000)"
    }
}

/// 硬券のプレビューと共有を行うシート
struct TicketShareSheet: View {
    @Environment(\.dismiss) private var dismiss
    let sighting: Sighting

    @State private var rendered: UIImage?

    private var card: TicketCard {
        TicketCard(
            className: sighting.formation?.vehicleClass?.name ?? "（形式未設定）",
            formationCode: sighting.formation?.code ?? "",
            lineName: sighting.lineName,
            stationName: sighting.stationName,
            date: sighting.date,
            headmark: sighting.headmark,
            isLastRun: sighting.isLastRun
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NavyBackground()
                VStack(spacing: 24) {
                    Spacer()
                    // プレビュー（画面幅に合わせて縮小表示）
                    card
                        .scaleEffect(min(1, (UIScreen.main.bounds.width - 48) / TicketCard.size.width))
                        .frame(width: UIScreen.main.bounds.width - 48,
                               height: TicketCard.size.height * min(1, (UIScreen.main.bounds.width - 48) / TicketCard.size.width))
                        .shadow(color: .black.opacity(0.4), radius: 16, y: 8)

                    Text("この硬券を画像で共有できます")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Palette.creamSub)

                    Spacer()

                    if let img = rendered {
                        ShareLink(
                            item: Image(uiImage: img),
                            preview: SharePreview("TetsuLog 鉄道遭遇券", image: Image(uiImage: img))
                        ) {
                            Label("きっぷを共有", systemImage: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .heavy, design: .serif))
                                .tracking(2)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.Palette.red))
                                .foregroundStyle(Theme.Palette.paper)
                        }
                        .padding(.horizontal, 24)
                    } else {
                        ProgressView().tint(Theme.Palette.cream)
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("きっぷを作る")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Theme.Palette.navy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }.foregroundStyle(Theme.Palette.cream)
                }
            }
            .task { render() }
        }
    }

    @MainActor
    private func render() {
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        rendered = renderer.uiImage
    }
}
