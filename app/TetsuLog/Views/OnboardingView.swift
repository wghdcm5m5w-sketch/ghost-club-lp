import SwiftUI

/// 初回起動の歓迎画面。
/// 空っぽの図鑑でいきなり離脱されないための、トーン重視の3画面。
struct OnboardingView: View {
    @AppStorage("tetsulog.onboardingDone") private var done = false
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                slide(
                    icon: "tram.fill",
                    title: "あなたの鉄道人生を、\n記録する。",
                    body: "撮った編成・乗った区間・追いかけた憧れ。すべての出会いを、編成番号レベルで残せます。"
                ).tag(0)
                slide(
                    icon: "text.viewfinder",
                    title: "撮るだけで、\n自動で記録。",
                    body: "カメラを向けるだけでiOSが編成番号を読み取り、形式と編成を候補表示。手入力はほぼ不要です。"
                ).tag(1)
                slide(
                    icon: "lock.icloud.fill",
                    title: "あなたのデータは、\nあなたのもの。",
                    body: "TetsuLogは運営サーバーを持ちません。記録は100%あなたのiCloudの中にだけ。広告も追跡もサブスクもありません。"
                ).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                Haptics.tick()
                if page < 2 {
                    withAnimation { page += 1 }
                } else {
                    done = true
                }
            } label: {
                Text(page < 2 ? "つぎへ" : "はじめる")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func slide(icon: String, title: String, body: String) -> some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(.orange.gradient)
            Text(title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Text(body)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 36)
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
