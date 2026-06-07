import Foundation

/// 鉄ヲタが見たい統計を一気に算出する純粋関数群。
/// UI から直接呼べる。SwiftDataの`@Query`結果を渡す前提。
enum Statistics {

    struct Overview {
        var totalSightings: Int
        var totalRides: Int
        var totalRideKm: Double
        var collectedFormations: Int
        var totalRideHours: Double
        var firstRecordDate: Date?
    }

    static func overview(sightings: [Sighting], rides: [RideSegment]) -> Overview {
        let totalKm = rides.map(\.distanceKm).reduce(0, +)
        let totalSec = rides.map(\.durationSec).reduce(0, +)
        let formationsSeen = Set(sightings.compactMap { $0.formation?.id })
        let firstDate = (sightings.map(\.date) + rides.map(\.date)).min()
        return Overview(
            totalSightings: sightings.count,
            totalRides: rides.count,
            totalRideKm: totalKm,
            collectedFormations: formationsSeen.count,
            totalRideHours: Double(totalSec) / 3600.0,
            firstRecordDate: firstDate
        )
    }

    /// 形式別の遭遇回数 Top N
    static func topClasses(sightings: [Sighting], limit: Int = 5) -> [(name: String, count: Int)] {
        let names = sightings.compactMap { $0.formation?.vehicleClass?.name }
        let grouped = Dictionary(grouping: names) { $0 }.mapValues { $0.count }
        return grouped
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }

    /// 路線別の遭遇回数 Top N
    static func topLines(sightings: [Sighting], limit: Int = 5) -> [(name: String, count: Int)] {
        let names = sightings.map(\.lineName).filter { !$0.isEmpty }
        let grouped = Dictionary(grouping: names) { $0 }.mapValues { $0.count }
        return grouped
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }

    /// 駅別の遭遇回数 Top N
    static func topStations(sightings: [Sighting], limit: Int = 5) -> [(name: String, count: Int)] {
        let names = sightings.map(\.stationName).filter { !$0.isEmpty }
        let grouped = Dictionary(grouping: names) { $0 }.mapValues { $0.count }
        return grouped
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }

    /// 月別の遭遇数（直近12ヶ月）
    static func monthlySightings(sightings: [Sighting]) -> [(month: Date, count: Int)] {
        let cal = Calendar.current
        let now = Date.now
        return (0..<12).reversed().compactMap { offset -> (Date, Int)? in
            guard let target = cal.date(byAdding: .month, value: -offset, to: now),
                  let range = cal.dateInterval(of: .month, for: target) else { return nil }
            let count = sightings.filter { $0.date >= range.start && $0.date < range.end }.count
            return (range.start, count)
        }
    }

    /// ラストラン記録の件数
    static func lastRunCount(sightings: [Sighting]) -> Int {
        sightings.filter { $0.isLastRun || $0.kind == .lastRun }.count
    }
}
