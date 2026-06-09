import Foundation
import SwiftData

/// 既存サービス（レイルラボ/乗りつぶしオンライン/自作Excel）からの記録移行のためのCSVインポート。
/// 柔軟な列マッピングで、ユーザーが「どの列が駅か」を指定して取り込める。
/// 純粋関数を中心に設計してテスト容易にする。
enum CSVImporter {

    // MARK: - パース

    /// 取り込み行数の上限。異常な巨大ファイルでメモリを使い果たさないための保険。
    private static let maxRows = 100_000

    /// クォート対応の最小限のCSVパーサ。改行・カンマを含むフィールドを正しく扱う。
    static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var field = ""
        var row: [String] = []
        var inQuotes = false
        var i = text.startIndex
        while i < text.endIndex {
            let c = text[i]
            if inQuotes {
                if c == "\"" {
                    let next = text.index(after: i)
                    if next < text.endIndex, text[next] == "\"" {
                        field.append("\""); i = next
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(c)
                }
            } else {
                switch c {
                case "\"": inQuotes = true
                case ",":
                    row.append(field); field = ""
                case "\r":
                    break // LFと組で処理
                case "\n":
                    row.append(field); field = ""
                    rows.append(row); row = []
                    if rows.count >= maxRows { return rows }
                default: field.append(c)
                }
            }
            i = text.index(after: i)
        }
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        // 末尾の空行を除去
        return rows.filter { !($0.count == 1 && $0[0].isEmpty) }
    }

    // MARK: - 列マッピング

    enum Field: String, CaseIterable, Identifiable {
        case date = "日付"
        case lineName = "路線"
        case stationName = "駅"
        case className = "形式"
        case formationCode = "編成番号"
        case carNumber = "車番"
        case trainNumber = "列車番号"
        case note = "メモ"
        var id: String { rawValue }
    }

    /// 列ヘッダ→Fieldの推測。よくある日本語ヘッダ・英語ヘッダを認識する。
    static func suggestMapping(headers: [String]) -> [Field: Int] {
        var map: [Field: Int] = [:]
        for (idx, header) in headers.enumerated() {
            let h = header.lowercased()
            switch true {
            case h.contains("日付") || h.contains("date") || h.contains("乗車日"):
                if map[.date] == nil { map[.date] = idx }
            case h.contains("路線") || h.contains("線名") || h.contains("line"):
                if map[.lineName] == nil { map[.lineName] = idx }
            case h.contains("駅") || h.contains("station"):
                if map[.stationName] == nil { map[.stationName] = idx }
            case h.contains("形式") || h.contains("車種") || h.contains("class"):
                if map[.className] == nil { map[.className] = idx }
            case h.contains("編成") || h.contains("formation"):
                if map[.formationCode] == nil { map[.formationCode] = idx }
            case h.contains("車番") || h.contains("車両番号") || h.contains("car"):
                if map[.carNumber] == nil { map[.carNumber] = idx }
            case h.contains("列車番号") || h.contains("列番") || h.contains("train"):
                if map[.trainNumber] == nil { map[.trainNumber] = idx }
            case h.contains("メモ") || h.contains("備考") || h.contains("note"):
                if map[.note] == nil { map[.note] = idx }
            default: break
            }
        }
        return map
    }

    // MARK: - インポート

    struct ImportSummary {
        var imported: Int
        var skipped: Int
    }

    @MainActor
    @discardableResult
    static func importRows(_ rows: [[String]],
                           hasHeader: Bool,
                           mapping: [Field: Int],
                           into context: ModelContext) -> ImportSummary {
        let dataRows = hasHeader ? Array(rows.dropFirst()) : rows
        guard let dateIdx = mapping[.date] else { return .init(imported: 0, skipped: dataRows.count) }

        let allClasses = (try? context.fetch(FetchDescriptor<VehicleClass>())) ?? []
        var classByName = Dictionary(grouping: allClasses, by: \.name).compactMapValues { $0.first }

        func formation(for className: String, code: String) -> Formation? {
            guard !className.isEmpty || !code.isEmpty else { return nil }
            let name = className.isEmpty ? "（インポート）" : className
            let vc: VehicleClass
            if let existing = classByName[name] {
                vc = existing
            } else {
                let created = VehicleClass(name: name, operatorName: "", category: "")
                created.isUserAdded = true
                context.insert(created)
                classByName[name] = created
                vc = created
            }
            guard !code.isEmpty else { return nil }
            if let f = vc.formations?.first(where: { $0.code == code }) { return f }
            let f = Formation(code: code, carCount: 0)
            f.vehicleClass = vc
            context.insert(f)
            return f
        }

        var imported = 0
        var skipped = 0
        for row in dataRows {
            guard dateIdx < row.count, let date = parseDate(row[dateIdx]) else {
                skipped += 1; continue
            }
            let className = pick(row, mapping[.className])
            let code = pick(row, mapping[.formationCode])
            let sighting = Sighting(
                date: date,
                stationName: pick(row, mapping[.stationName]),
                lineName: pick(row, mapping[.lineName])
            )
            sighting.formation = formation(for: className, code: code)
            sighting.carNumber = pick(row, mapping[.carNumber])
            sighting.trainNumber = pick(row, mapping[.trainNumber])
            sighting.note = pick(row, mapping[.note])
            context.insert(sighting)
            imported += 1
        }
        try? context.save()
        return ImportSummary(imported: imported, skipped: skipped)
    }

    // MARK: - ヘルパ

    private static func pick(_ row: [String], _ idx: Int?) -> String {
        guard let idx, idx < row.count else { return "" }
        return row[idx].trimmingCharacters(in: .whitespaces)
    }

    private static let dateFormats = [
        "yyyy-MM-dd HH:mm:ss",
        "yyyy/MM/dd HH:mm",
        "yyyy-MM-dd",
        "yyyy/MM/dd",
        "yyyy.MM.dd"
    ]

    static func parseDate(_ s: String) -> Date? {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        for fmt in dateFormats {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = fmt
            if let d = df.date(from: trimmed) { return d }
        }
        // ISO8601
        return ISO8601DateFormatter().date(from: trimmed)
    }
}
