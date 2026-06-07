import SwiftUI
import SwiftData

/// 遭遇記録の入力シート。OCR(v1.1)はここに統合する想定。
struct AddSightingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \VehicleClass.name) private var classes: [VehicleClass]

    @State private var selectedClass: VehicleClass?
    @State private var selectedFormation: Formation?
    @State private var stationName = ""
    @State private var lineName = ""
    @State private var date = Date.now
    @State private var isLastRun = false
    @State private var note = ""

    private var formations: [Formation] {
        (selectedClass?.formations ?? []).sorted { $0.code < $1.code }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("車両") {
                    Picker("形式", selection: $selectedClass) {
                        Text("選択").tag(VehicleClass?.none)
                        ForEach(classes) { vc in
                            Text(vc.name).tag(VehicleClass?.some(vc))
                        }
                    }
                    if selectedClass != nil {
                        Picker("編成", selection: $selectedFormation) {
                            Text("選択").tag(Formation?.none)
                            ForEach(formations) { f in
                                Text(f.code).tag(Formation?.some(f))
                            }
                        }
                    }
                }

                Section("場所・日時") {
                    TextField("路線名", text: $lineName)
                    TextField("駅名", text: $stationName)
                    DatePicker("日時", selection: $date)
                }

                Section {
                    Toggle("ラストラン", isOn: $isLastRun)
                    TextField("メモ", text: $note, axis: .vertical)
                }

                // v1.1: OCRボタンをここに配置
                Section {
                    Label("写真から編成番号を読み取る（v1.1）", systemImage: "text.viewfinder")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("記録を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(selectedFormation == nil)
                }
            }
        }
    }

    private func save() {
        let s = Sighting(date: date, stationName: stationName, lineName: lineName)
        s.formation = selectedFormation
        s.isLastRun = isLastRun
        s.note = note
        context.insert(s)
        try? context.save()
        dismiss()
    }
}

#Preview {
    AddSightingView()
        .modelContainer(PreviewData.container)
}
