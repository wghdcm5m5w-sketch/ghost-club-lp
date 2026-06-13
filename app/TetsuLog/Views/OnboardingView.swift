import SwiftUI

/// 初回起動の歓迎画面。国鉄レトロ・上質デザイン。
/// 紺地に紙の案内札が浮かぶような世界観で、世界観を最初の体験として刷り込む。
struct OnboardingView: View {
    @AppStorage("tetsulog.onboardingDone") private var done = false
    @State private var page = 0

    private let slides: [(icon: String, title: String, body: String)] = [
        ("tram.fill",
         "あなたの鉄道人生を、\n記録する。",
         "撮った編成・乗った区間・追いかけた憧れ。すべての出会いを、編成番号レベルで残せます。"),
        ("text.viewfinder",
         "撮るだけで、\n自動で記録。",
         "カメラを向けるだけでiOSが編成番号を読み取り、形式と編成を候補表示。手入力はほぼ不要です。"),
        ("lock.icloud.fill",
         "あなたのデータは、\nあなたのもの。",
         "TetsuLogは運営サーバーを持ちません。記録は100%あなたのiCloudの中にだけ。広告も追跡もサブスクもありません。")
    ]

    var body: some View {
        ZStack {
            NavyBackground()
            VStack(spacing: 0) {
                // 上部のロゴライン
                HStack(spacing: 10) {
                    Image(systemName: "tram.fill").foregroundStyle(Theme.Palette.redLight)
                    Text("TETSULOG")
                        .font(.system(size: 13, weight: .heavy, design: .serif))
                        .tracking(6)
                        .foregroundStyle(Theme.Palette.cream)
                }
                .padding(.top, 60)

                Spacer()

                TabView(selection: $page) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { i, slide in
                        slideCard(slide)
                            .padding(.horizontal, 28)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // カスタムインジケーター（朱の方向幕風）
                HStack(spacing: 10) {
                    ForEach(0..<slides.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Theme.Palette.red : Theme.Palette.cream.opacity(0.3))
                            .frame(width: i == page ? 26 : 8, height: 6)
                            .animation(.spring(response: 0.35), value: page)
                    }
                }
                .padding(.top, 18)

                Spacer()

                Button {
                    Haptics.tick()
                    if page < slides.count - 1 {
                        withAnimation { page += 1 }
                    } else { done = true }
                } label: {
                    HStack(spacing: 10) {
                        Text(page < slides.count - 1 ? "つぎへ" : "はじめる")
                            .font(.system(size: 17, weight: .heavy, design: .serif))
                            .tracking(2)
                        Image(systemName: page < slides.count - 1 ? "chevron.right" : "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.Palette.red)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(.white.opacity(0.18), lineWidth: 1)
                            )
                    )
                    .foregroundStyle(Theme.Palette.paper)
                    .shadow(color: Theme.Palette.red.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
    }

    @ViewBuilder
    private func slideCard(_ slide: (icon: String, title: String, body: String)) -> some View {
        PaperCard(accent: false) {
            VStack(spacing: 24) {
                // アイコンを朱の二重円で包む（社章風）
                ZStack {
                    Circle().stroke(Theme.Palette.red, lineWidth: 3).frame(width: 110, height: 110)
                    Circle().stroke(Theme.Palette.red.opacity(0.4), lineWidth: 1).frame(width: 96, height: 96)
                    Image(systemName: slide.icon)
                        .font(.system(size: 44, weight: .regular))
                        .foregroundStyle(Theme.Palette.cyan)
                }
                .padding(.top, 18)

                Text(slide.title)
                    .font(.system(size: 26, weight: .heavy, design: .serif))
                    .foregroundStyle(Theme.Palette.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                // 朱の細い区切り罫
                HStack(spacing: 6) {
                    Rectangle().fill(Theme.Palette.red.opacity(0.6)).frame(width: 24, height: 1)
                    Circle().fill(Theme.Palette.red).frame(width: 5, height: 5)
                    Rectangle().fill(Theme.Palette.red.opacity(0.6)).frame(width: 24, height: 1)
                }

                Text(slide.body)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.Palette.inkSub)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview { OnboardingView() }
