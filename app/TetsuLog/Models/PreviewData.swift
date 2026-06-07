import Foundation
import SwiftData

/// SwiftUI プレビュー用のインメモリコンテナ。CloudKitなしでサンプル投入。
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: VehicleClass.self, Formation.self, Sighting.self,
                RideSegment.self, ShootingSpot.self, WatchItem.self, AbandonedLine.self,
            configurations: config
        )
        let ctx = container.mainContext

        let e235 = VehicleClass(name: "E235系", operatorName: "JR東日本", category: "通勤型")
        e235.lineNames = ["山手線"]
        ctx.insert(e235)

        var sampleFormation: Formation?
        for i in 1...20 {
            let f = Formation(code: "トウ\(i)", carCount: 11)
            f.vehicleClass = e235
            ctx.insert(f)
            if i == 1 { sampleFormation = f }
        }

        let n189 = VehicleClass(name: "189系", operatorName: "JR東日本", category: "特急型")
        n189.isRetiring = true
        ctx.insert(n189)
        for code in ["N101", "N102"] {
            let f = Formation(code: code, carCount: 6)
            f.vehicleClass = n189
            f.isActive = false
            ctx.insert(f)
        }

        // サンプル遭遇記録
        let s = Sighting(date: .now, stationName: "新宿", lineName: "山手線")
        s.formation = sampleFormation
        s.latitude = 35.690921
        s.longitude = 139.700258
        ctx.insert(s)

        try? ctx.save()
        return container
    }()
}
