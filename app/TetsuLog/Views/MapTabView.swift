import SwiftUI
import SwiftData
import MapKit

/// 地図タブ: Apple純正Map に製図オーバーレイ（測量図トーン）。
/// 遭遇駅＝シアンの測量マーカー／撮影地＝琥珀のダイヤ／廃線＝破線。
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
                    Annotation(s.stationName.isEmpty ? "記録" : s.stationName,
                               coordinate: s.coordinate) {
                        SurveyMarker(color: s.isLastRun ? Theme.Palette.red : Theme.Palette.cyan)
                    }
                }
                ForEach(spots) { spot in
                    Annotation(spot.name, coordinate: spot.coordinate) {
                        SpotMarker(bearing: spot.bearingToTrack)
                    }
                }
                if showAbandoned {
                    ForEach(abandonedLines) { line in
                        let coords = PolylineCodec.decode(line.encodedPolyline)
                        if coords.count >= 2 {
                            MapPolyline(coordinates: coords)
                                .stroke(Theme.Palette.cyanDim,
                                        style: StrokeStyle(lineWidth: 2.5, dash: [6, 5]))
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .navigationTitle("足跡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Theme.Palette.navy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink { ShootingSpotListView() } label: {
                        Label("撮影地", systemImage: "camera").foregroundStyle(Theme.Palette.cream)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAbandoned.toggle() } label: {
                        Image(systemName: showAbandoned ? "eye.fill" : "eye.slash")
                            .foregroundStyle(Theme.Palette.cream)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { legendBar }
        }
    }

    private var legendBar: some View {
        HStack(spacing: 14) {
            legendItem(count: pinnedSightings.count, label: "遭遇") {
                SurveyMarker(color: Theme.Palette.cyan).scaleEffect(0.7)
            }
            legendItem(count: spots.count, label: "撮影地") {
                SpotMarker(bearing: 0).scaleEffect(0.7)
            }
            if !abandonedLines.isEmpty {
                legendItem(count: abandonedLines.count, label: "廃線") {
                    RoundedRectangle(cornerRadius: 1).fill(Theme.Palette.cyanDim)
                        .frame(width: 18, height: 2.5)
                }
            }
            Spacer()
            Text("MAP")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(3).foregroundStyle(Theme.Palette.cyanDim)
        }
        .padding(.horizontal, 16).padding(.vertical, 11)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().fill(Theme.Palette.surfaceEdge).frame(height: 1), alignment: .top)
    }

    private func legendItem<Icon: View>(count: Int, label: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 6) {
            icon().frame(width: 18, height: 18)
            Text("\(count)").font(.system(size: 14, weight: .heavy)).foregroundStyle(Theme.Palette.cream)
            Text(label).font(.system(size: 11)).foregroundStyle(Theme.Palette.creamSub)
        }
    }
}

/// 遭遇駅＝測量マーカー（発光リング付きの点）
private struct SurveyMarker: View {
    var color: Color
    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.22)).frame(width: 22, height: 22)
            Circle().fill(color).frame(width: 11, height: 11)
                .overlay(Circle().stroke(.white, lineWidth: 1.5))
        }
        .shadow(color: color.opacity(0.6), radius: 4)
    }
}

/// 撮影地＝琥珀のダイヤ＋順光方位ウェッジ
private struct SpotMarker: View {
    var bearing: Double
    private let amber = Color(hex: 0xFFCF4A)
    var body: some View {
        ZStack {
            // 順光方位ウェッジ
            Wedge()
                .fill(amber.opacity(0.30))
                .frame(width: 26, height: 26)
                .rotationEffect(.degrees(bearing))
            Rectangle().fill(amber).frame(width: 11, height: 11)
                .rotationEffect(.degrees(45))
                .overlay(Rectangle().stroke(.black.opacity(0.6), lineWidth: 1).rotationEffect(.degrees(45)))
        }
    }
}

/// 上向きの扇形（順光方位の表現）
private struct Wedge: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        p.move(to: c)
        p.addArc(center: c, radius: rect.width / 2,
                 startAngle: .degrees(-120), endAngle: .degrees(-60), clockwise: false)
        p.closeSubpath()
        return p
    }
}

#Preview {
    MapTabView()
        .modelContainer(PreviewData.container)
}
