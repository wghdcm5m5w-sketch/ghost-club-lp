import SwiftUI
import SwiftData

/// 乗車記録の編集（＝過去の乗車を手動で残す/直す）。
struct RideEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    /// 編集対象。nilなら新規。
    var ride: RideSegment?

    @State private var fromStation = ""
    @State private var toStation = ""
    @State private var lineName = ""
    @State private var formationCode = ""
    @State private var distanceKm = ""
    @State private var minutes = ""
    @State private var date = Date.now
    @State private var note = ""
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section("区間") {
                    TextField("乗車駅", text: $fromStation)
                    TextField("降車駅", text: $toStation)
                    TextField("路線名", text: $lineName)
                }
                Section("詳細") {
                    TextField("乗車した編成（任意）", text: $formationCode)
                        .font(.body.monospaced())
                    TextField("距離 (km)", text: $distanceKm).keyboardType(.decimalPad)
                    TextField("所要時間 (分)", text: $minutes).keyboardType(.numberPad)
                    DatePicker("日時", selection: $date)
                }
                Section {
                    TextField("メモ", text: $note, axis: .vertical)
                }
                if ride != nil {
                    Section {
                        Button(role: .destructive) { deleteRecord() } label: {
                            Label("この乗車記録を削除", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(ride == nil ? "乗車を記録" : "乗車を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(fromStation.isEmpty || toStation.isEmpty)
                }
            }
            .onAppear { loadIfNeeded() }
        }
    }

    private func loadIfNeeded() {
        guard !loaded, let r = ride else { loaded = true; return }
        fromStation = r.fromStation
        toStation = r.toStation
        lineName = r.lineName
        formationCode = r.formationCode
        distanceKm = r.distanceKm > 0 ? String(r.distanceKm) : ""
        minutes = r.durationSec > 0 ? String(r.durationSec / 60) : ""
        date = r.date
        note = r.note
        loaded = true
    }

    private func save() {
        let r = ride ?? RideSegment()
        r.fromStation = fromStation
        r.toStation = toStation
        r.lineName = lineName
        r.formationCode = formationCode
        r.distanceKm = Double(distanceKm) ?? 0
        r.durationSec = (Int(minutes) ?? 0) * 60
        r.date = date
        r.note = note
        if ride == nil { context.insert(r) }
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func deleteRecord() {
        guard let r = ride else { return }
        context.delete(r); try? context.save(); Haptics.tick(); dismiss()
    }
}

#Preview {
    RideEditView()
        .modelContainer(PreviewData.container)
}
