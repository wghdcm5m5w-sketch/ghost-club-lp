import SwiftUI
import SwiftData

/// 記録タブ: 遭遇記録を年・月でグルーピングしたタイムライン
struct LogView: View {
    @Query(sort: \Sighting.date, order: .reverse) private var sightings: [Sighting]
    @Environment(RideManager.self) private var rideManager
    @State private var showingAdd = false
    @State private var showingStartRide = false
    @State private var showingActiveRide = false

    private var grouped: [(year: Int, items: [Sighting])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: sightings) { cal.component(.year, from: $0.date) }
        return dict.keys.sorted(by: >).map { ($0, dict[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sightings.isEmpty {
                    ContentUnavailableView(
                        "まだ記録がありません",
                        systemImage: "tram",
                        description: Text("右上の＋から、出会った編成を記録しましょう。")
                    )
                } else {
                    List {
                        ForEach(grouped, id: \.year) { group in
                            Section("\(group.year) · \(group.items.count)件") {
                                ForEach(group.items) { s in
                                    SightingRow(sighting: s)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("記録")
            .safeAreaInset(edge: .top) {
                if rideManager.isActive {
                    activeRideBanner
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingAdd = true
                        } label: {
                            Label("遭遇を記録", systemImage: "tram")
                        }
                        Button {
                            if rideManager.isActive {
                                showingActiveRide = true
                            } else {
                                showingStartRide = true
                            }
                        } label: {
                            Label(rideManager.isActive ? "乗車中の画面" : "乗車を開始",
                                  systemImage: "play.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddSightingView()
            }
            .sheet(isPresented: $showingStartRide) {
                StartRideView(manager: rideManager)
            }
            .sheet(isPresented: $showingActiveRide) {
                ActiveRideView(manager: rideManager)
            }
        }
    }

    private var activeRideBanner: some View {
        Button {
            showingActiveRide = true
        } label: {
            HStack {
                Image(systemName: "tram.fill")
                Text("乗車中: \(rideManager.className) \(rideManager.formationCode)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(.orange.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.orange)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}

private struct SightingRow: View {
    let sighting: Sighting

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tram.fill")
                .foregroundStyle(.orange)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(formationLabel)
                    .font(.subheadline.weight(.semibold))
                Text("\(sighting.lineName) · \(sighting.stationName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(sighting.date, format: .dateTime.month().day())
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                if sighting.isLastRun {
                    Text("ラストラン")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var formationLabel: String {
        guard let f = sighting.formation else { return "（編成未設定）" }
        let cls = f.vehicleClass?.name ?? ""
        return "\(cls) \(f.code)"
    }
}

#Preview {
    LogView()
        .modelContainer(PreviewData.container)
        .environment(RideManager())
}
