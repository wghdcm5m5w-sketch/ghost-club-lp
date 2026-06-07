import SwiftUI
import SwiftData
import MapKit

/// 地図タブ: 遭遇地点ピン・撮影地・廃線オーバーレイ
struct MapTabView: View {
    @Query private var sightings: [Sighting]
    @Query private var spots: [ShootingSpot]
    @Query private var abandonedLines: [AbandonedLine]

    @State private var position: MapCameraPosition = .automatic
    @State private var showAbandoned = true

    private var pinnedSightings: [Sighting] {
        sightings.filter { $0.latitude != 0 || $0.longitude != 0 }
    }

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                ForEach(pinnedSightings) { s in
                    Marker(s.stationName.isEmpty ? "記録" : s.stationName,
                           systemImage: "tram.fill",
                           coordinate: s.coordinate)
                        .tint(.orange)
                }
                ForEach(spots) { spot in
                    Marker(spot.name, systemImage: "camera.fill", coordinate: spot.coordinate)
                        .tint(.blue)
                }

                if showAbandoned {
                    ForEach(abandonedLines) { line in
                        let coords = PolylineCodec.decode(line.encodedPolyline)
                        if coords.count >= 2 {
                            MapPolyline(coordinates: coords)
                                .stroke(.purple, style: StrokeStyle(
                                    lineWidth: 3, dash: [6, 4]))
                        }
                    }
                }
            }
            .navigationTitle("地図")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle(isOn: $showAbandoned) {
                        Label("廃線", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    }
                    .toggleStyle(.button)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if showAbandoned && !abandonedLines.isEmpty {
                    abandonedLegend
                }
            }
        }
    }

    private var abandonedLegend: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 1)
                .fill(.purple)
                .frame(width: 24, height: 3)
            Text("廃線 \(abandonedLines.count)路線")
                .font(.caption)
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .padding()
    }
}

#Preview {
    MapTabView()
        .modelContainer(PreviewData.container)
}
