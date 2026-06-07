import SwiftUI
import SwiftData
import CoreLocation
import MapKit

/// 撮影地の一覧。順光計算へ繋ぐ。
struct ShootingSpotListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ShootingSpot.name) private var spots: [ShootingSpot]
    @State private var showingAdd = false

    var body: some View {
        List {
            if spots.isEmpty {
                ContentUnavailableView(
                    "撮影地がありません",
                    systemImage: "camera",
                    description: Text("お気に入りのお立ち台を登録すると、順光・逆光を計算できます。")
                )
            } else {
                ForEach(spots) { spot in
                    NavigationLink {
                        SpotDetailView(spot: spot)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(spot.name)
                            Text("被写体方位 \(Int(spot.bearingToTrack))°")
                                .font(.caption.monospaced()).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    for i in offsets { context.delete(spots[i]) }
                    try? context.save()
                }
            }
        }
        .navigationTitle("撮影地")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) { SpotEditView() }
    }
}

/// 撮影地の追加・編集
struct SpotEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var spot: ShootingSpot?

    @State private var name = ""
    @State private var latText = ""
    @State private var lonText = ""
    @State private var bearing: Double = 90
    @State private var bestHours = ""
    @State private var note = ""
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section("撮影地") {
                    TextField("名称（例: 〇〇カーブ）", text: $name)
                    TextField("緯度", text: $latText).keyboardType(.numbersAndPunctuation)
                    TextField("経度", text: $lonText).keyboardType(.numbersAndPunctuation)
                }
                Section {
                    VStack(alignment: .leading) {
                        Text("被写体（線路）方位: \(Int(bearing))°")
                        Slider(value: $bearing, in: 0...359, step: 1)
                        Text("列車を向く方向。北=0 東=90 南=180 西=270")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("構図")
                }
                Section {
                    TextField("ベスト時間帯メモ（午前順光 等）", text: $bestHours)
                    TextField("メモ", text: $note, axis: .vertical)
                }
            }
            .navigationTitle(spot == nil ? "撮影地を追加" : "撮影地を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }.disabled(name.isEmpty)
                }
            }
            .onAppear {
                guard !loaded, let s = spot else { loaded = true; return }
                name = s.name; latText = String(s.latitude); lonText = String(s.longitude)
                bearing = s.bearingToTrack; bestHours = s.bestHours; note = s.note; loaded = true
            }
        }
    }

    private func save() {
        let s = spot ?? ShootingSpot()
        s.name = name
        s.latitude = Double(latText) ?? 0
        s.longitude = Double(lonText) ?? 0
        s.bearingToTrack = bearing
        s.bestHours = bestHours
        s.note = note
        if spot == nil { context.insert(s) }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

/// 撮影地詳細 + 順光/逆光計算（SunCalculatorを実際に使う画面）
struct SpotDetailView: View {
    let spot: ShootingSpot
    @State private var when = Date.now
    @State private var showingEdit = false

    private var sun: SunPosition {
        SunCalculator.position(latitude: spot.latitude, longitude: spot.longitude, date: when)
    }
    private var light: LightDirection {
        SunCalculator.lightDirection(trackBearing: spot.bearingToTrack, sunAzimuth: sun.azimuth)
    }

    var body: some View {
        Form {
            Section("撮影日時") {
                DatePicker("日時", selection: $when)
            }

            Section("太陽の位置") {
                LabeledContent("方位", value: "\(Int(sun.azimuth))° (\(compass(sun.azimuth)))")
                LabeledContent("高度", value: "\(Int(sun.altitude))°")
                LabeledContent("被写体方位", value: "\(Int(spot.bearingToTrack))°")
            }

            Section {
                HStack {
                    Image(systemName: lightIcon)
                        .font(.title)
                        .foregroundStyle(lightColor)
                    VStack(alignment: .leading) {
                        Text(verdict).font(.headline)
                        Text(detail).font(.caption).foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("光線判定")
            } footer: {
                if sun.altitude < 0 {
                    Text("この時刻、太陽は地平線の下です（夜間）。")
                }
            }

            if !spot.bestHours.isEmpty {
                Section("メモ") { Text(spot.bestHours) }
            }
        }
        .navigationTitle(spot.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("編集") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) { SpotEditView(spot: spot) }
    }

    private var verdict: String {
        if sun.altitude < 0 { return "夜間・撮影不可" }
        switch light {
        case .front: return "順光・撮影適"
        case .side: return "斜光"
        case .back: return "逆光"
        }
    }
    private var detail: String {
        switch light {
        case .front: return "太陽が被写体を正面から照らします。"
        case .side: return "斜めからの光。陰影が出ます。"
        case .back: return "逆光。シルエットや透過光狙いに。"
        }
    }
    private var lightIcon: String {
        if sun.altitude < 0 { return "moon.stars.fill" }
        switch light {
        case .front: return "sun.max.fill"
        case .side: return "sun.haze.fill"
        case .back: return "sun.min.fill"
        }
    }
    private var lightColor: Color {
        if sun.altitude < 0 { return .indigo }
        switch light {
        case .front: return .green
        case .side: return .orange
        case .back: return .red
        }
    }
    private func compass(_ deg: Double) -> String {
        let dirs = ["北","北東","東","南東","南","南西","西","北西"]
        let idx = Int((deg + 22.5) / 45) % 8
        return dirs[idx]
    }
}

#Preview {
    NavigationStack { ShootingSpotListView() }
        .modelContainer(PreviewData.container)
}
