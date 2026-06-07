import Foundation
import SwiftData
import CoreLocation

// MARK: - 車両の管理単位（ガチ鉄は編成と機関車・気動車を厳密に区別する）

enum UnitType: String, Codable, CaseIterable {
    case formation  = "編成"   // 編成番号で管理（トウ47 等）
    case locomotive = "機関車" // 号機で管理（EF65 2065号機 等）
    case railcar    = "気動車" // 車番で管理（キハ40 2095 等）

    /// 個体を数える単位
    var counter: String {
        switch self {
        case .formation: return "編成"
        case .locomotive: return "両"
        case .railcar: return "両"
        }
    }

    /// 個体ラベル
    var unitLabel: String {
        switch self {
        case .formation: return "編成"
        case .locomotive: return "号機"
        case .railcar: return "車番"
        }
    }
}

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
    var unitTypeRaw: String = UnitType.formation.rawValue
    var isUserAdded: Bool = false   // ユーザーが追加した形式か

    @Relationship(deleteRule: .cascade, inverse: \Formation.vehicleClass)
    var formations: [Formation]?

    init(name: String = "", operatorName: String = "", category: String = "") {
        self.name = name
        self.operatorName = operatorName
        self.category = category
    }

    var unitType: UnitType {
        get { UnitType(rawValue: unitTypeRaw) ?? .formation }
        set { unitTypeRaw = newValue.rawValue }
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

    /// 最終遭遇日
    var lastSeen: Date? {
        sightings?.map(\.date).max()
    }

    /// 初遭遇日
    var firstSeen: Date? {
        sightings?.map(\.date).min()
    }

    /// 遭遇回数
    var sightingCount: Int { sightings?.count ?? 0 }
}

extension VehicleClass {
    var collectedCount: Int { (formations ?? []).filter { $0.isCollected }.count }
    var totalCount: Int { formations?.count ?? 0 }
    var collectionRatio: Double {
        totalCount == 0 ? 0 : Double(collectedCount) / Double(totalCount)
    }
    var isComplete: Bool { totalCount > 0 && collectedCount == totalCount }
}

// MARK: - 遭遇記録

/// 列車運転種別（ガチ鉄が区別したい単位）
enum TrainKind: String, Codable, CaseIterable {
    case scheduled  = "定期"
    case extra      = "臨時"
    case deadhead   = "回送"
    case test       = "試運転"
    case delivery   = "配給"
    case charter    = "団体"
    case lastRun    = "ラストラン"
}

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

    // ガチ鉄向け拡張フィールド（既存記録との互換のためデフォルト値）
    var carNumber: String = ""        // 撮った車両の車番（クハE235-1247 等）
    var headmark: String = ""         // ○周年HM / 装飾サボ
    var livery: String = ""           // 塗装・ラッピング（リバイバル, 銀河鉄道等）
    var weather: String = ""          // 晴/曇/雨/雪/夕焼け
    var trainNumber: String = ""      // 2024M / 9501M / 試8520 など
    var kindRaw: String = TrainKind.scheduled.rawValue  // 定期/臨時/回送/...
    var audioFilenames: [String] = []   // 音鉄用: 走行音・車内放送・駅メロ等

    init(date: Date = .now, stationName: String = "", lineName: String = "") {
        self.date = date
        self.stationName = stationName
        self.lineName = lineName
    }

    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }

    var kind: TrainKind {
        get { TrainKind(rawValue: kindRaw) ?? .scheduled }
        set { kindRaw = newValue.rawValue }
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
