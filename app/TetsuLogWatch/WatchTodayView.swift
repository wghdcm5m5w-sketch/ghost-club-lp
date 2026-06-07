import SwiftUI
import SwiftData

/// Watch のメイン画面: 今週・今月の遭遇数 + クイック記録への導線。
struct WatchTodayView: View {
    @Query private var allSightings: [Sighting]
    @State private var showingQuick = false

    private var weekCount: Int {
        let cal = Calendar.current
        guard let start = cal.dateInterval(of: .weekOfYear, for: .now)?.start else { return 0 }
        return allSightings.filter { $0.date >= start }.count
    }
    private var monthCount: Int {
        let cal = Calendar.current
        guard let start = cal.dateInterval(of: .month, for: .now)?.start else { return 0 }
        return allSightings.filter { $0.date >= start }.count
    }
    private var lastSighting: Sighting? {
        allSightings.max(by: { $0.date < $1.date })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WatchNavyBackground()
                ScrollView {
                    VStack(spacing: 8) {
                        // ヘッダー
                        HStack(spacing: 4) {
                            Image(systemName: "tram.fill")
                                .foregroundStyle(WatchTheme.Palette.red)
                            Text("TETSULOG")
                                .font(.system(size: 10, weight: .heavy, design: .serif))
                                .tracking(3)
                                .foregroundStyle(WatchTheme.Palette.cream)
                        }
                        .padding(.top, 2)

                        // 今週カウント
                        WatchPaperCard {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("今 週")
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(2)
                                    .foregroundStyle(WatchTheme.Palette.inkSub)
                                HStack(alignment: .firstTextBaseline) {
                                    Text("\(weekCount)")
                                        .font(.system(size: 36, weight: .heavy, design: .serif).monospacedDigit())
                                        .foregroundStyle(WatchTheme.Palette.red)
                                    Text("件")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(WatchTheme.Palette.inkSub)
                                    Spacer()
                                    Text("今月 \(monthCount)")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(WatchTheme.Palette.inkSub)
                                }
                            }
                        }

                        // 最後の遭遇
                        if let last = lastSighting {
                            WatchPaperCard {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("最後の遭遇")
                                        .font(.system(size: 9, weight: .bold))
                                        .tracking(2)
                                        .foregroundStyle(WatchTheme.Palette.inkSub)
                                    if let f = last.formation {
                                        Text("\(f.vehicleClass?.name ?? "") \(f.code)")
                                            .font(.system(size: 13, weight: .bold, design: .serif))
                                            .foregroundStyle(WatchTheme.Palette.ink)
                                            .lineLimit(1)
                                    }
                                    Text("\(last.lineName) · \(last.stationName)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(WatchTheme.Palette.inkSub)
                                        .lineLimit(1)
                                    Text(last.date, format: .relative(presentation: .named))
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(WatchTheme.Palette.inkSub)
                                }
                            }
                        }

                        // クイック記録ボタン
                        NavigationLink {
                            WatchQuickRecordView()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("記録")
                                    .font(.system(size: 14, weight: .heavy, design: .serif))
                                    .tracking(2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(WatchTheme.Palette.red)
                            )
                            .foregroundStyle(WatchTheme.Palette.paper)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 6)
                }
            }
            .navigationBarHidden(true)
        }
    }
}
