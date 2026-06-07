import SwiftUI
import SwiftData
import MapKit

/// 地図タブ: 遭遇地点ピンと撮影地、（v1.2で）廃線オーバーレイ
struct MapTabView: View {
    @Query private var sightings: [Sighting]
    @Query private var spots: [ShootingSpot]

    @State private var position: MapCameraPosition = .automatic

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
            }
            .navigationTitle("地図")
            .overlay(alignment: .bottom) {
                if pinnedSightings.isEmpty && spots.isEmpty {
                    Text("記録した地点や撮影地がここに表示されます")
                        .font(.caption)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 24)
                }
            }
        }
    }
}

#Preview {
    MapTabView()
        .modelContainer(PreviewData.container)
}
