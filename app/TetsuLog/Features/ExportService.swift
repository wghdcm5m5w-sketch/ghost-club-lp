import Foundation
import SwiftData

/// あなたのデータをロックインしない約束を守るためのJSON書き出し。
/// 「自分のデータをいつでも取り出せる」のはガチ鉄の信頼の根幹。
enum ExportService {

    struct Export: Codable {
        var version: Int
        var exportedAt: Date
        var sightings: [SightingExport]
        var rides: [RideExport]
        var spots: [SpotExport]
    }

    struct SightingExport: Codable {
        var date: Date
        var className: String
        var formationCode: String
        var carNumber: String
        var lineName: String
        var stationName: String
        var latitude: Double
        var longitude: Double
        var headmark: String
        var livery: String
        var weather: String
        var trainNumber: String
        var kind: String
        var isLastRun: Bool
        var note: String
    }

    struct RideExport: Codable {
        var date: Date
        var fromStation: String
        var toStation: String
        var lineName: String
        var formationCode: String
        var distanceKm: Double
        var durationSec: Int
        var note: String
    }

    struct SpotExport: Codable {
        var name: String
        var latitude: Double
        var longitude: Double
        var bearingToTrack: Double
        var bestHours: String
        var note: String
    }

    @MainActor
    static func exportAll(_ context: ModelContext) -> URL? {
        let sightings = (try? context.fetch(FetchDescriptor<Sighting>())) ?? []
        let rides = (try? context.fetch(FetchDescriptor<RideSegment>())) ?? []
        let spots = (try? context.fetch(FetchDescriptor<ShootingSpot>())) ?? []

        let payload = Export(
            version: 1,
            exportedAt: .now,
            sightings: sightings.map {
                SightingExport(
                    date: $0.date,
                    className: $0.formation?.vehicleClass?.name ?? "",
                    formationCode: $0.formation?.code ?? "",
                    carNumber: $0.carNumber,
                    lineName: $0.lineName,
                    stationName: $0.stationName,
                    latitude: $0.latitude,
                    longitude: $0.longitude,
                    headmark: $0.headmark,
                    livery: $0.livery,
                    weather: $0.weather,
                    trainNumber: $0.trainNumber,
                    kind: $0.kind.rawValue,
                    isLastRun: $0.isLastRun,
                    note: $0.note
                )
            },
            rides: rides.map {
                RideExport(date: $0.date, fromStation: $0.fromStation,
                           toStation: $0.toStation, lineName: $0.lineName,
                           formationCode: $0.formationCode,
                           distanceKm: $0.distanceKm, durationSec: $0.durationSec, note: $0.note)
            },
            spots: spots.map {
                SpotExport(name: $0.name, latitude: $0.latitude, longitude: $0.longitude,
                           bearingToTrack: $0.bearingToTrack, bestHours: $0.bestHours, note: $0.note)
            }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(payload) else { return nil }

        let stamp = ISO8601DateFormatter().string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TetsuLog-export-\(stamp).json")
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
            return url
        } catch {
            return nil
        }
    }

    // MARK: - CSV書き出し（Excel・スプレッドシート用）

    /// 遭遇記録をCSVで書き出す。BOM付きUTF-8（Excelで文字化けしない）・CRLF改行。
    /// ガチ鉄の「自分の集計は自分のシートでやる」文化への直結口。
    @MainActor
    static func exportSightingsCSV(_ context: ModelContext) -> URL? {
        let descriptor = FetchDescriptor<Sighting>(sortBy: [SortDescriptor(\.date)])
        let sightings = (try? context.fetch(descriptor)) ?? []

        let header = ["日付", "形式", "編成番号", "車番", "路線", "駅",
                      "緯度", "経度", "ヘッドマーク", "塗装", "天気",
                      "列車番号", "種別", "ラストラン", "メモ"]
        let dateFormatter = ISO8601DateFormatter()

        var lines: [String] = [header.map(csvEscape).joined(separator: ",")]
        for s in sightings {
            let fields = [
                dateFormatter.string(from: s.date),
                s.formation?.vehicleClass?.name ?? "",
                s.formation?.code ?? "",
                s.carNumber,
                s.lineName,
                s.stationName,
                s.latitude == 0 ? "" : String(s.latitude),
                s.longitude == 0 ? "" : String(s.longitude),
                s.headmark,
                s.livery,
                s.weather,
                s.trainNumber,
                s.kind.rawValue,
                s.isLastRun ? "1" : "0",
                s.note
            ]
            lines.append(fields.map(csvEscape).joined(separator: ","))
        }
        let csv = lines.joined(separator: "\r\n")

        // BOM付きUTF-8。これが無いとExcelがShift_JISと誤認して文字化けする。
        var data = Data([0xEF, 0xBB, 0xBF])
        data.append(Data(csv.utf8))

        let stamp = ISO8601DateFormatter().string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TetsuLog-sightings-\(stamp).csv")
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
            return url
        } catch {
            return nil
        }
    }

    /// 乗車記録をCSVで書き出す（遭遇記録と同じ書式ルール）。
    @MainActor
    static func exportRidesCSV(_ context: ModelContext) -> URL? {
        let descriptor = FetchDescriptor<RideSegment>(sortBy: [SortDescriptor(\.date)])
        let rides = (try? context.fetch(descriptor)) ?? []
        guard !rides.isEmpty else { return nil }

        let header = ["日付", "出発駅", "到着駅", "路線", "編成番号", "距離km", "所要秒", "メモ"]
        let dateFormatter = ISO8601DateFormatter()

        var lines: [String] = [header.map(csvEscape).joined(separator: ",")]
        for r in rides {
            let fields = [
                dateFormatter.string(from: r.date),
                r.fromStation,
                r.toStation,
                r.lineName,
                r.formationCode,
                String(format: "%.2f", r.distanceKm),
                String(r.durationSec),
                r.note
            ]
            lines.append(fields.map(csvEscape).joined(separator: ","))
        }
        let csv = lines.joined(separator: "\r\n")

        var data = Data([0xEF, 0xBB, 0xBF])
        data.append(Data(csv.utf8))

        let stamp = ISO8601DateFormatter().string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TetsuLog-rides-\(stamp).csv")
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
            return url
        } catch {
            return nil
        }
    }

    /// RFC 4180 準拠のフィールドエスケープ
    private static func csvEscape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    // MARK: - インポート（移行・復元）

    struct ImportResult {
        var sightings: Int
        var rides: Int
        var spots: Int
        var duplicates: Int
    }

    // MARK: 重複判定キー（同じファイルの二重取り込みを防ぐ）

    private static func sightingKey(date: Date, station: String, formationCode: String, trainNumber: String) -> String {
        "\(Int(date.timeIntervalSince1970))|\(station)|\(formationCode)|\(trainNumber)"
    }
    private static func rideKey(date: Date, from: String, to: String, line: String) -> String {
        "\(Int(date.timeIntervalSince1970))|\(from)|\(to)|\(line)"
    }
    private static func spotKey(name: String, lat: Double, lon: Double) -> String {
        "\(name)|\(String(format: "%.5f", lat))|\(String(format: "%.5f", lon))"
    }

    /// JSONを読み込み、記録を追加する。形式・編成は名称で既存に照合し、
    /// 無ければ「インポート」形式の下に編成を自動生成する（記録を失わせない）。
    @MainActor
    @discardableResult
    static func importAll(from url: URL, into context: ModelContext) -> ImportResult? {
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }

        // 異常に大きいファイルでメモリを使い果たさないための上限（64MB）
        if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
           size > 64 * 1024 * 1024 {
            return nil
        }
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let payload = try? decoder.decode(Export.self, from: data) else { return nil }

        let allClasses = (try? context.fetch(FetchDescriptor<VehicleClass>())) ?? []
        var classByName = Dictionary(grouping: allClasses, by: \.name).compactMapValues { $0.first }

        func formation(for className: String, code: String) -> Formation? {
            guard !code.isEmpty else { return nil }
            let vc: VehicleClass
            if let existing = classByName[className] {
                vc = existing
            } else {
                let created = VehicleClass(name: className.isEmpty ? "（インポート）" : className,
                                           operatorName: "", category: "")
                created.isUserAdded = true
                context.insert(created)
                classByName[className] = created
                vc = created
            }
            if let f = vc.formations?.first(where: { $0.code == code }) { return f }
            let f = Formation(code: code, carCount: 0)
            f.vehicleClass = vc
            context.insert(f)
            return f
        }

        // 既存記録の重複キーを構築（同じファイルを2回読み込んでも二重化しない）
        let existingSightings = (try? context.fetch(FetchDescriptor<Sighting>())) ?? []
        let existingRides = (try? context.fetch(FetchDescriptor<RideSegment>())) ?? []
        let existingSpots = (try? context.fetch(FetchDescriptor<ShootingSpot>())) ?? []
        var seenSightings = Set(existingSightings.map {
            sightingKey(date: $0.date, station: $0.stationName,
                        formationCode: $0.formation?.code ?? "", trainNumber: $0.trainNumber)
        })
        var seenRides = Set(existingRides.map {
            rideKey(date: $0.date, from: $0.fromStation, to: $0.toStation, line: $0.lineName)
        })
        var seenSpots = Set(existingSpots.map {
            spotKey(name: $0.name, lat: $0.latitude, lon: $0.longitude)
        })

        var imported = (sightings: 0, rides: 0, spots: 0)
        var duplicates = 0

        for s in payload.sightings {
            let key = sightingKey(date: s.date, station: s.stationName,
                                  formationCode: s.formationCode, trainNumber: s.trainNumber)
            if seenSightings.contains(key) { duplicates += 1; continue }
            seenSightings.insert(key)

            let sighting = Sighting(date: s.date, stationName: s.stationName, lineName: s.lineName)
            sighting.formation = formation(for: s.className, code: s.formationCode)
            sighting.carNumber = s.carNumber
            sighting.headmark = s.headmark
            sighting.livery = s.livery
            sighting.weather = s.weather
            sighting.trainNumber = s.trainNumber
            sighting.kindRaw = s.kind
            sighting.isLastRun = s.isLastRun
            sighting.latitude = s.latitude
            sighting.longitude = s.longitude
            sighting.note = s.note
            context.insert(sighting)
            imported.sightings += 1
        }

        for r in payload.rides {
            let key = rideKey(date: r.date, from: r.fromStation, to: r.toStation, line: r.lineName)
            if seenRides.contains(key) { duplicates += 1; continue }
            seenRides.insert(key)

            let ride = RideSegment(fromStation: r.fromStation, toStation: r.toStation, lineName: r.lineName)
            ride.date = r.date
            ride.formationCode = r.formationCode
            ride.distanceKm = r.distanceKm
            ride.durationSec = r.durationSec
            ride.note = r.note
            context.insert(ride)
            imported.rides += 1
        }

        for sp in payload.spots {
            let key = spotKey(name: sp.name, lat: sp.latitude, lon: sp.longitude)
            if seenSpots.contains(key) { duplicates += 1; continue }
            seenSpots.insert(key)

            let spot = ShootingSpot(name: sp.name, latitude: sp.latitude, longitude: sp.longitude)
            spot.bearingToTrack = sp.bearingToTrack
            spot.bestHours = sp.bestHours
            spot.note = sp.note
            context.insert(spot)
            imported.spots += 1
        }

        try? context.save()
        return ImportResult(sightings: imported.sightings,
                            rides: imported.rides,
                            spots: imported.spots,
                            duplicates: duplicates)
    }
}
