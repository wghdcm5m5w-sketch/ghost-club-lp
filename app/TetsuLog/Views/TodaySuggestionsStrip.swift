import SwiftUI
import SwiftData

/// 図鑑上部に置く「今日のおすすめ」ストリップ。
/// 新規ユーザーの「何から記録すれば？」を解消し、収集経験者には日替わりの発見を提供する。
///
/// ロジックは決定的（同じ日なら同じ並び）にして、サーバーやランダム性に依存しない。
struct TodaySuggestionsStrip: View {
    @Query(sort: \VehicleClass.name) private var classes: [VehicleClass]
    @Query(sort: \ShootingSpot.name) private var spots: [ShootingSpot]

    @State private var selectedClass: VehicleClass?
    @State private var selectedSpot: ShootingSpot?

    private let card = (w: CGFloat(220), h: CGFloat(132))

    var body: some View {
        if !classes.isEmpty || !spots.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("今日のおすすめ")
                        .font(.system(size: 13, weight: .heavy, design: .serif))
                        .tracking(3)
                        .foregroundStyle(Theme.Palette.creamSub)
                    Spacer()
                    Text(Date.now, format: .dateTime.month().day().weekday(.abbreviated))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.Palette.creamSub)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(pickedSuggestions, id: \.id) { item in
                            switch item.kind {
                            case .retiring(let vc):
                                NavigationLink(value: vc) { retiringCard(vc) }
                                    .buttonStyle(.plain)
                            case .spot(let s):
                                Button { selectedSpot = s } label: { spotCard(s) }
                                    .buttonStyle(.plain)
                            case .complete(let vc):
                                NavigationLink(value: vc) { completeCard(vc) }
                                    .buttonStyle(.plain)
                            case .featured(let vc):
                                NavigationLink(value: vc) { featuredCard(vc) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .navigationDestination(item: $selectedSpot) { spot in
                SpotDetailView(spot: spot)
            }
        }
    }

    // MARK: - 候補生成（決定的）

    private enum Kind {
        case retiring(VehicleClass)
        case spot(ShootingSpot)
        case complete(VehicleClass)
        case featured(VehicleClass)
    }
    private struct Item: Identifiable {
        let id: String
        let kind: Kind
    }

    /// 日付ベースのシードで安定して並び替える
    private var todaySeed: Int {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        return (c.year ?? 0) * 10000 + (c.month ?? 0) * 100 + (c.day ?? 0)
    }

    private var pickedSuggestions: [Item] {
        var items: [Item] = []

        // 1) 廃車進行中の形式 → 最優先
        let retiring = classes.filter { $0.isRetiring }
        items += retiring.prefix(2).map { Item(id: "ret-\($0.id)", kind: .retiring($0)) }

        // 2) 撮影地（日付シードで日替わり）
        if !spots.isEmpty {
            let s = stableRotate(spots, count: 3)
            items += s.map { Item(id: "spot-\($0.id)", kind: .spot($0)) }
        }

        // 3) コンプリート達成済み（誇示）
        let complete = classes.filter { $0.isComplete && $0.totalCount > 0 }
        items += complete.prefix(1).map { Item(id: "cmp-\($0.id)", kind: .complete($0)) }

        // 4) フィーチャー（未収集の中から日替わりで1〜2）
        let uncollected = classes.filter { !$0.isRetiring && $0.collectedCount < $0.totalCount }
        let feat = stableRotate(uncollected, count: 2)
        items += feat.map { Item(id: "ft-\($0.id)", kind: .featured($0)) }

        return Array(items.prefix(8))
    }

    /// 配列を日付シードで決定的に回転
    private func stableRotate<T>(_ arr: [T], count: Int) -> [T] {
        guard !arr.isEmpty else { return [] }
        let n = arr.count
        let start = todaySeed % n
        let rotated = (0..<min(count, n)).map { arr[(start + $0) % n] }
        return rotated
    }

    // MARK: - カード

    private func baseCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        PaperCard(accent: false) { content() }
            .frame(width: card.w, height: card.h)
    }

    private func retiringCard(_ vc: VehicleClass) -> some View {
        baseCard {
            VStack(alignment: .leading, spacing: 4) {
                InkBadge(text: "廃車進行", filled: true)
                Spacer(minLength: 0)
                Text(vc.name)
                    .font(.system(size: 20, weight: .heavy, design: .serif))
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)
                Text("会えるのは今のうち")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Palette.red)
                Text(vc.operatorName)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.Palette.inkSub)
            }
        }
    }

    private func spotCard(_ s: ShootingSpot) -> some View {
        baseCard {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "camera.fill").foregroundStyle(Theme.Palette.goldDeep)
                    Text("撮影地").font(.system(size: 11, weight: .bold)).tracking(2)
                        .foregroundStyle(Theme.Palette.inkSub)
                }
                Spacer(minLength: 0)
                Text(s.name)
                    .font(.system(size: 17, weight: .heavy, design: .serif))
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(2)
                if !s.bestHours.isEmpty {
                    Text(s.bestHours)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Palette.inkSub)
                        .lineLimit(1)
                }
            }
        }
    }

    private func completeCard(_ vc: VehicleClass) -> some View {
        baseCard {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.Palette.goldDeep)
                    Text("コンプリート").font(.system(size: 11, weight: .bold)).tracking(2)
                        .foregroundStyle(Theme.Palette.goldDeep)
                }
                Spacer(minLength: 0)
                Text(vc.name)
                    .font(.system(size: 20, weight: .heavy, design: .serif))
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)
                Text("\(vc.collectedCount) / \(vc.totalCount) \(vc.unitType.counter)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.Palette.inkSub)
            }
        }
    }

    private func featuredCard(_ vc: VehicleClass) -> some View {
        baseCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("今日の一推し")
                    .font(.system(size: 11, weight: .bold)).tracking(2)
                    .foregroundStyle(Theme.Palette.inkSub)
                Spacer(minLength: 0)
                Text(vc.name)
                    .font(.system(size: 20, weight: .heavy, design: .serif))
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)
                Text("\(vc.operatorName) · \(vc.lineNames.first ?? "—")")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.Palette.inkSub)
                    .lineLimit(1)
                RailGauge(ratio: vc.collectionRatio, complete: false)
                    .frame(height: 4)
            }
        }
    }
}
