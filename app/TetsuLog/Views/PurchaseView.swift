import SwiftUI
import StoreKit

/// 買い切り課金の購入画面（ペイウォール）。
/// 国鉄レトロ・上質デザインで世界観を維持し、誠実なコピーで信頼を得る。
struct PurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseManager.self) private var store

    var body: some View {
        NavigationStack {
            ZStack {
                NavyBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        MakuHeader(title: "TetsuLog Pro").padding(.top, 8)

                        // 価格カード
                        PaperCard(accent: false) {
                            VStack(spacing: 14) {
                                Text("一度きりの、買い切り。")
                                    .font(.system(size: 16, weight: .heavy, design: .serif))
                                    .tracking(2)
                                    .foregroundStyle(Theme.Palette.ink)

                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("¥")
                                        .font(.system(size: 28, weight: .heavy, design: .serif))
                                        .foregroundStyle(Theme.Palette.red)
                                    Text(displayPrice)
                                        .font(.system(size: 64, weight: .heavy, design: .serif).monospacedDigit())
                                        .foregroundStyle(Theme.Palette.red)
                                }
                                Text("サブスクなし／追加料金なし／永続")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(2)
                                    .foregroundStyle(Theme.Palette.inkSub)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }

                        // 価値の列挙
                        PaperCard {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(features, id: \.self) { f in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundStyle(Theme.Palette.red)
                                            .font(.system(size: 14))
                                        Text(f)
                                            .font(.system(size: 14))
                                            .foregroundStyle(Theme.Palette.ink)
                                    }
                                }
                            }
                        }

                        // 信頼の補足
                        PaperCard(accent: false) {
                            VStack(alignment: .leading, spacing: 8) {
                                row("プライバシー", "データは100%あなたのiCloudのみ。運営者は見られません。")
                                rowDivider
                                row("広告", "なし。トラッキングもありません。")
                                rowDivider
                                row("家族共有", "ファミリー共有に対応。")
                                rowDivider
                                row("解約", "買い切りなので、解約という概念がありません。")
                            }
                        }

                        // 購入ボタン
                        actionButton

                        // 復元ボタン
                        Button {
                            Task { await store.restore() }
                        } label: {
                            Text("購入を復元する")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.Palette.cream)
                                .underline()
                        }
                        .padding(.top, 4)

                        // エラー表示
                        if let err = store.lastError {
                            Text(err)
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.Palette.red)
                                .padding(.horizontal, 8)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(Theme.screenPadding)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Theme.Palette.navy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(Theme.Palette.cream)
                }
            }
        }
        .task { await store.loadProducts() }
    }

    @ViewBuilder
    private var actionButton: some View {
        if store.isPro {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                Text("Pro 有効化済み")
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .tracking(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.Palette.gold))
            .foregroundStyle(Theme.Palette.navy)
        } else {
            Button {
                Task { await store.purchase() }
            } label: {
                HStack(spacing: 10) {
                    if store.isPurchasing {
                        ProgressView().tint(Theme.Palette.paper)
                    } else {
                        Image(systemName: "bag.fill")
                    }
                    Text(store.isPurchasing ? "処理中..." : "購入する")
                        .font(.system(size: 16, weight: .heavy, design: .serif))
                        .tracking(2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.Palette.red))
                .foregroundStyle(Theme.Palette.paper)
                .shadow(color: Theme.Palette.red.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .disabled(store.isPurchasing || store.product == nil)
        }
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(k).font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.Palette.inkSub).frame(width: 80, alignment: .leading)
            Text(v).font(.system(size: 13)).foregroundStyle(Theme.Palette.ink)
        }
    }
    private var rowDivider: some View { Rectangle().fill(Theme.Palette.paperEdge).frame(height: 1) }

    private var displayPrice: String {
        store.product?.displayPrice
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: ",", with: "")
            ?? "980"
    }

    private let features: [String] = [
        "OCRで写真から編成番号を自動入力",
        "順光・逆光をその場で計算",
        "ライブアクティビティで乗車中を表示",
        "Apple Watch コンパニオン",
        "全国20の有名撮影地プリセット",
        "走行音・駅メロの録音添付",
        "JSON / CSV での書き出し・取り込み",
        "詳細統計とランキング",
        "全ての形式・編成データ"
    ]
}

#Preview {
    PurchaseView()
        .environment(PurchaseManager())
}
