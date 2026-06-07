import SwiftUI
import VisionKit

/// VisionKit の DataScannerViewController を SwiftUI でラップし、
/// 認識テキストから編成番号候補を抽出して返す。端末内処理・通信なし。
struct FormationScannerView: UIViewControllerRepresentable {
    /// 候補が確定したら呼ばれる
    var onRecognize: ([FormationNumberParser.Candidate]) -> Void

    static var isSupported: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        try? uiViewController.startScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(onRecognize: onRecognize) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onRecognize: ([FormationNumberParser.Candidate]) -> Void
        private var lastFire = Date.distantPast

        init(onRecognize: @escaping ([FormationNumberParser.Candidate]) -> Void) {
            self.onRecognize = onRecognize
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            process(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didUpdate updatedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            process(allItems)
        }

        private func process(_ items: [RecognizedItem]) {
            // 0.6秒に1回までに間引き
            guard Date.now.timeIntervalSince(lastFire) > 0.6 else { return }
            let lines: [String] = items.compactMap {
                if case let .text(t) = $0 { return t.transcript }
                return nil
            }
            let candidates = FormationNumberParser.candidates(from: lines)
            guard !candidates.isEmpty else { return }
            lastFire = .now
            onRecognize(candidates)
        }
    }
}

/// スキャナを全画面で開き、候補を選ばせるシート
struct FormationScanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var candidates: [FormationNumberParser.Candidate] = []
    var onPick: (FormationNumberParser.Candidate) -> Void

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if FormationScannerView.isSupported {
                    FormationScannerView { found in
                        // 既存とマージ
                        for c in found where !candidates.contains(c) {
                            candidates.append(c)
                        }
                    }
                    .ignoresSafeArea()
                } else {
                    ContentUnavailableView(
                        "この端末ではスキャンを利用できません",
                        systemImage: "camera.metering.unknown",
                        description: Text("手入力で記録してください。")
                    )
                }

                if !candidates.isEmpty {
                    candidateList
                }
            }
            .navigationTitle("編成番号をスキャン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private var candidateList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("検出された候補")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(candidates, id: \.raw) { c in
                        Button {
                            onPick(c)
                            dismiss()
                        } label: {
                            VStack(spacing: 2) {
                                Text(c.raw).font(.headline.monospaced())
                                Text(c.kind == .carNumber ? "車番" : "編成")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(.thinMaterial)
    }
}
