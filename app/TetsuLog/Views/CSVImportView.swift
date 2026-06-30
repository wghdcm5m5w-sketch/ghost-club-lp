import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// CSVファイルから記録を取り込むシート。
/// 列マッピングを推測表示し、ユーザーが確認・調整してから取り込む。
struct CSVImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var rows: [[String]] = []
    @State private var hasHeader = true
    @State private var mapping: [CSVImporter.Field: Int] = [:]
    @State private var showingFilePicker = true
    @State private var resultMessage: String?
    @State private var resultIsError = false

    private var headers: [String] {
        guard hasHeader, let first = rows.first else {
            // ヘッダなし時は列番号を見出しに
            let cols = rows.first?.count ?? 0
            return (0..<cols).map { "列\($0 + 1)" }
        }
        return first
    }

    private var sampleRows: [[String]] {
        let data = hasHeader ? Array(rows.dropFirst()) : rows
        return Array(data.prefix(3))
    }

    var body: some View {
        NavigationStack {
            Form {
                if rows.isEmpty {
                    Section {
                        Button {
                            showingFilePicker = true
                        } label: {
                            Label("CSVファイルを選択", systemImage: "doc.text")
                        }
                    } footer: {
                        Text("レイルラボの鉄レコ書き出し・乗りつぶしオンラインの書き出し・自作のExcelをCSVで保存したものを取り込めます。")
                    }
                } else {
                    Section("検出結果") {
                        Toggle("1行目をヘッダとして扱う", isOn: $hasHeader)
                            .onChange(of: hasHeader) { _, _ in
                                mapping = CSVImporter.suggestMapping(headers: headers)
                            }
                        LabeledContent("総行数", value: "\(rows.count)")
                        LabeledContent("列数", value: "\(rows.first?.count ?? 0)")
                    }

                    Section {
                        ForEach(CSVImporter.Field.allCases) { field in
                            Picker(field.rawValue, selection: Binding(
                                get: { mapping[field] ?? -1 },
                                set: { newVal in
                                    if newVal < 0 { mapping.removeValue(forKey: field) }
                                    else { mapping[field] = newVal }
                                }
                            )) {
                                Text("（なし）").tag(-1)
                                ForEach(0..<headers.count, id: \.self) { idx in
                                    Text(headers[idx]).tag(idx)
                                }
                            }
                        }
                    } header: {
                        Text("列マッピング")
                    } footer: {
                        Text("「日付」だけは必須です。他は任意で割り当てれば取り込みます。")
                    }

                    if !sampleRows.isEmpty {
                        Section("プレビュー（最初の3行）") {
                            ForEach(Array(sampleRows.enumerated()), id: \.offset) { _, r in
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(CSVImporter.Field.allCases) { field in
                                        if let idx = mapping[field], idx < r.count {
                                            HStack {
                                                Text(field.rawValue)
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                                    .frame(width: 64, alignment: .leading)
                                                Text(r[idx])
                                                    .font(.caption.monospaced())
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    if let resultMessage {
                        Section { Text(resultMessage).foregroundStyle(resultIsError ? .red : .green) }
                    }
                }
            }
            .tetsuFormStyle()
            .navigationTitle("CSVから取り込み")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("取り込む") { runImport() }
                        .disabled(rows.isEmpty || mapping[.date] == nil)
                }
            }
            .fileImporter(isPresented: $showingFilePicker,
                          allowedContentTypes: [.commaSeparatedText, .plainText, .text]) { result in
                handleFile(result)
            }
        }
    }

    private func handleFile(_ result: Result<URL, Error>) {
        guard case let .success(url) = result else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        // 巨大ファイルでメモリを使い果たさないための上限チェック
        if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
           size > CSVImporter.maxFileBytes {
            resultIsError = true
            resultMessage = "ファイルが大きすぎます（上限 \(CSVImporter.maxFileBytes / (1024*1024))MB）。"
            return
        }
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
              data.count <= CSVImporter.maxFileBytes else {
            resultIsError = true
            resultMessage = "ファイルを読み込めませんでした。"
            return
        }
        // 文字エンコーディング推測：UTF-8 → Shift-JIS
        let text: String
        if let utf = String(data: data, encoding: .utf8) {
            text = utf
        } else if let sjis = String(data: data, encoding: .shiftJIS) {
            text = sjis
        } else {
            return
        }

        let parsed = CSVImporter.parse(text)
        guard !parsed.isEmpty else { return }
        rows = parsed
        mapping = CSVImporter.suggestMapping(headers: headers)
    }

    private func runImport() {
        let summary = CSVImporter.importRows(rows, hasHeader: hasHeader,
                                             mapping: mapping, into: context)
        if summary.failed {
            resultIsError = true
            resultMessage = "保存に失敗しました。空き容量やiCloudの状態をご確認のうえ、もう一度お試しください。"
            Haptics.tick()
        } else {
            resultIsError = false
            resultMessage = "取り込み完了: \(summary.imported)件 / スキップ \(summary.skipped)件"
            Haptics.success()
        }
    }
}
