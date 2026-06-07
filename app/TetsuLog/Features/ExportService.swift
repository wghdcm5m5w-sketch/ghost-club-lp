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
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
