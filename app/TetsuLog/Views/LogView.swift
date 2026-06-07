import SwiftUI
import SwiftData

/// 記録タブ: 遭遇記録を年・月でグルーピングしたタイムライン
struct LogView: View {
    @Query(sort: \Sighting.date, order: .reverse) private var sightings: [Sighting]
    @State private var showingAdd = false

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddSightingView()
            }
        }
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
}
