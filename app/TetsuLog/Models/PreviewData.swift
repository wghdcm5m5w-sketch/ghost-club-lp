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

        // サンプル遭遇記録（複数日付・装飾あり）
        let cal = Calendar.current
        let s1 = Sighting(date: .now, stationName: "新宿", lineName: "山手線")
        s1.formation = sampleFormation
        s1.latitude = 35.690921; s1.longitude = 139.700258
        s1.headmark = "○周年HM"
        s1.weather = "晴れ"
        ctx.insert(s1)

        let s2 = Sighting(date: cal.date(byAdding: .day, value: -3, to: .now)!,
                          stationName: "渋谷", lineName: "山手線")
        s2.formation = sampleFormation
        s2.kind = .deadhead
        ctx.insert(s2)

        let s3 = Sighting(date: cal.date(byAdding: .month, value: -2, to: .now)!,
                          stationName: "立川", lineName: "中央本線")
        s3.formation = (n189.formations ?? []).first
        s3.isLastRun = true
        s3.kind = .lastRun
        s3.livery = "リバイバル"
        ctx.insert(s3)

        // 乗車記録
        let r = RideSegment(fromStation: "東京", toStation: "新宿", lineName: "中央線")
        r.distanceKm = 10.3
        r.durationSec = 17 * 60
        r.date = .now
        ctx.insert(r)

        try? ctx.save()
        return container
    }()
}
