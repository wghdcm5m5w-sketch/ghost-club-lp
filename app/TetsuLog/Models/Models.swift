import Foundation
import SwiftData
import CoreLocation

// MARK: - 形式マスタ

@Model
final class VehicleClass {
    var id: UUID = UUID()
    var name: String = ""           // 例: "E235系"
    var operatorName: String = ""   // 例: "JR東日本"
    var category: String = ""       // 通勤/特急/新幹線/機関車...
    var lineNames: [String] = []
    var isRetiring: Bool = false
    var introducedYear: Int?
    var retiredYear: Int?
    var note: String = ""

    @Relationship(deleteRule: .cascade, inverse: \Formation.vehicleClass)
    var formations: [Formation]?

    init(name: String = "", operatorName: String = "", category: String = "") {
        self.name = name
        self.operatorName = operatorName
        self.category = category
    }
}

// MARK: - 編成（個体）

@Model
final class Formation {
    var id: UUID = UUID()
    var code: String = ""           // 編成番号 "トウ47" / "J36"
    var carNumbers: [String] = []
    var carCount: Int = 0
    var depot: String = ""
    var isActive: Bool = true
    var vehicleClass: VehicleClass?

    @Relationship(deleteRule: .cascade, inverse: \Sighting.formation)
    var sightings: [Sighting]?

    init(code: String = "", carCount: Int = 0) {
        self.code = code
        self.carCount = carCount
    }

    /// このユーザーが遭遇済みか
    var isCollected: Bool { !(sightings?.isEmpty ?? true) }
}

// MARK: - 遭遇記録

@Model
final class Sighting {
    var id: UUID = UUID()
    var date: Date = Date.now
    var stationName: String = ""
    var lineName: String = ""
    var latitude: Double = 0
    var longitude: Double = 0
    var note: String = ""
    var photoFilenames: [String] = []
    var sunAzimuth: Double?
    var isLastRun: Bool = false
    var formation: Formation?
    var shootingSpot: ShootingSpot?

    init(date: Date = .now, stationName: String = "", lineName: String = "") {
        self.date = date
        self.stationName = stationName
        self.lineName = lineName
    }

    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
}

// MARK: - 乗車記録（区間）

@Model
final class RideSegment {
    var id: UUID = UUID()
    var date: Date = Date.now
    var fromStation: String = ""
    var toStation: String = ""
    var lineName: String = ""
    var distanceKm: Double = 0
    var formationCode: String = ""
    var durationSec: Int = 0
    var note: String = ""

    init(fromStation: String = "", toStation: String = "", lineName: String = "") {
        self.fromStation = fromStation
        self.toStation = toStation
        self.lineName = lineName
    }
}

// MARK: - 撮影地

@Model
final class ShootingSpot {
    var id: UUID = UUID()
    var name: String = ""
    var latitude: Double = 0
    var longitude: Double = 0
    var bearingToTrack: Double = 0   // 被写体（線路）方向の方位角（北=0, 東=90）
    var bestHours: String = ""
    var isPublic: Bool = false
    var note: String = ""

    init(name: String = "", latitude: Double = 0, longitude: Double = 0) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }

    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
}

// MARK: - ウォッチリスト（接近アラート対象）

@Model
final class WatchItem {
    var id: UUID = UUID()
    var targetClassName: String = ""
    var targetFormationCode: String = ""
    var enabled: Bool = true
    var createdAt: Date = Date.now

    init(targetClassName: String = "", targetFormationCode: String = "") {
        self.targetClassName = targetClassName
        self.targetFormationCode = targetFormationCode
    }

    var displayName: String {
        targetFormationCode.isEmpty ? targetClassName : "\(targetClassName) \(targetFormationCode)"
    }
}

// MARK: - 廃線

@Model
final class AbandonedLine {
    var id: UUID = UUID()
    var name: String = ""
    var openedYear: Int?
    var closedYear: Int?
    var encodedPolyline: String = ""
    var note: String = ""

    init(name: String = "") {
        self.name = name
    }
}
