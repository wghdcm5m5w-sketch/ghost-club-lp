import SwiftUI
import SwiftData

/// 載っていない形式を、ユーザー自身が追加する。
/// 「データが古い/載ってない」でガチ鉄に見捨てられないための要。
struct AddVehicleClassView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var operatorName = ""
    @State private var category = ""
    @State private var unitType: UnitType = .formation
    @State private var lineText = ""
    @State private var isRetiring = false

    // 編成の一括生成（任意）
    @State private var prefix = ""
    @State private var fromText = ""
    @State private var toText = ""

    var body: some View {
        Form {
            Section("形式") {
                TextField("形式名（例: E235系）", text: $name)
                TextField("事業者（例: JR東日本）", text: $operatorName)
                TextField("区分（通勤型/特急型 等）", text: $category)
                Picker("管理単位", selection: $unitType) {
                    ForEach(UnitType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                TextField("主な路線（/ 区切り）", text: $lineText)
                Toggle("廃車進行中", isOn: $isRetiring)
            }

            Section {
                TextField("\(unitType.unitLabel)の接頭辞（例: トウ）", text: $prefix)
                HStack {
                    TextField("開始番号", text: $fromText).keyboardType(.numberPad)
                    Text("〜")
                    TextField("終了番号", text: $toText).keyboardType(.numberPad)
                }
            } header: {
                Text("\(unitType.unitLabel)を一括生成（任意）")
            } footer: {
                Text("例: 接頭辞「トウ」開始1終了50 で トウ1〜トウ50 を自動作成。あとから個別に追加・編集もできます。")
            }
        }
        .navigationTitle("形式を追加")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }.disabled(name.isEmpty)
            }
        }
    }

    private func save() {
        let vc = VehicleClass(name: name, operatorName: operatorName, category: category)
        vc.unitType = unitType
        vc.isRetiring = isRetiring
        vc.isUserAdded = true
        vc.lineNames = lineText
            .split(separator: "/")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        context.insert(vc)

        if let from = Int(fromText), let to = Int(toText), from <= to {
            for n in from...to {
                let f = Formation(code: "\(prefix)\(n)", carCount: 0)
                f.vehicleClass = vc
                f.isActive = !isRetiring
                context.insert(f)
            }
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

/// 既存形式に編成/号機/車番を1件追加
struct AddFormationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let vehicleClass: VehicleClass

    @State private var code = ""
    @State private var carCount = ""
    @State private var depot = ""

    var body: some View {
        Form {
            Section("\(vehicleClass.name) に追加") {
                TextField("\(vehicleClass.unitType.unitLabel)（例: トウ51）", text: $code)
                    .font(.body.monospaced())
                TextField("両数", text: $carCount).keyboardType(.numberPad)
                TextField("所属（任意）", text: $depot)
            }
        }
        .navigationTitle("\(vehicleClass.unitType.unitLabel)を追加")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }.disabled(code.isEmpty)
            }
        }
    }

    private func save() {
        let f = Formation(code: code, carCount: Int(carCount) ?? 0)
        f.depot = depot
        f.vehicleClass = vehicleClass
        context.insert(f)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

#Preview {
    NavigationStack { AddVehicleClassView() }
        .modelContainer(PreviewData.container)
}
