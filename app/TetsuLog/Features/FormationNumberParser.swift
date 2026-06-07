import Foundation

/// OCRで得たテキスト群から、日本の鉄道車両番号・編成番号の候補を抽出する純粋ロジック。
/// ネットワーク不使用・端末内完結。単体テストしやすいよう副作用を持たない。
enum FormationNumberParser {

    /// 抽出候補の種別
    enum Kind: String {
        case carNumber       // 車番: クハE235-1247, モハ223-2034
        case formationCode   // 編成記号: トウ47, J36, W1, N102
    }

    struct Candidate: Equatable {
        let raw: String
        let kind: Kind
        /// 形式名の手がかり（車番から推定: E235, 223 など）。なければ nil
        let classHint: String?
    }

    // 車番: 先頭カナ記号(クハ/モハ/サハ/キハ/クモハ等) + 任意の英字 + 数字 - 数字
    //   例: クハE235-1247 / モハ223-2034 / キハ40-2095
    private static let carNumberPattern =
        #"(ク[モ]?ハ|モハ|サ[ハロ]|ク[ロ]ハ?|キ[ハロ]|ナ[ハ]|スハ?[フネ]?|オハ?[フ]?)([A-Z]{0,2})(\d{2,4})-(\d{1,4})"#

    // 編成記号: カナ1〜3字 or 英字1〜2字 + 数字1〜3桁
    //   例: トウ47 / ミツ12 / J36 / W1 / N102 / K51
    private static let formationPattern =
        #"\b([A-Z]{1,2}|[ァ-ヶ]{1,3})-?(\d{1,3})\b"#

    /// テキスト行の配列から候補を抽出（重複排除・スコア順は呼び出し側で）
    static func candidates(from lines: [String]) -> [Candidate] {
        var results: [Candidate] = []

        for line in lines {
            let text = normalize(line)

            // 車番
            if let regex = try? NSRegularExpression(pattern: carNumberPattern) {
                let ns = text as NSString
                for m in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
                    let raw = ns.substring(with: m.range)
                    let alpha = m.range(at: 2).location != NSNotFound ? ns.substring(with: m.range(at: 2)) : ""
                    let num = m.range(at: 3).location != NSNotFound ? ns.substring(with: m.range(at: 3)) : ""
                    let hint = alpha.isEmpty ? num : (alpha + num)  // E235 / 223
                    results.append(.init(raw: raw, kind: .carNumber, classHint: hint))
                }
            }

            // 編成記号（車番にマッチした行はスキップしてノイズを減らす）
            if !results.contains(where: { $0.kind == .carNumber && text.contains($0.raw) }) {
                if let regex = try? NSRegularExpression(pattern: formationPattern) {
                    let ns = text as NSString
                    for m in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
                        let raw = ns.substring(with: m.range).replacingOccurrences(of: "-", with: "")
                        // 年号や号車などの誤検出を緩く除外
                        guard !isLikelyNoise(raw) else { continue }
                        results.append(.init(raw: raw, kind: .formationCode, classHint: nil))
                    }
                }
            }
        }

        // 重複排除（raw + kind）
        var seen = Set<String>()
        return results.filter { seen.insert("\($0.kind.rawValue):\($0.raw)").inserted }
    }

    // 全角英数を半角へ、空白除去
    private static func normalize(_ s: String) -> String {
        let half = s.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? s
        return half.trimmingCharacters(in: .whitespaces)
    }

    // 「2024」「12号車」などのありがちな誤検出を除外
    private static func isLikelyNoise(_ raw: String) -> Bool {
        // 純粋な4桁数字（年号の可能性） かつ 英字なし
        if raw.range(of: #"^\d{4}$"#, options: .regularExpression) != nil { return true }
        return false
    }
}
