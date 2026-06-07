import SwiftUI
import SwiftData

/// 乗車セッションの状態管理。ライブアクティビティ制御と記録保存を担う。
/// アプリ強制終了後も復元できるよう UserDefaults に永続化する。
@MainActor
@Observable
final class RideManager {
    var isActive = false
    var className = ""
    var formationCode = ""
    var lineName = ""
    var fromStation = ""
    var nextStation = ""
    var startDate: Date?

    private let defaults = UserDefaults.standard
    private let key = "tetsulog.rideSession"

    init() {
        restore()
    }

    func start(className: String, formationCode: String, lineName: String,
               fromStation: String, nextStation: String) {
        self.className = className
        self.formationCode = formationCode
        self.lineName = lineName
        self.fromStation = fromStation
        self.nextStation = nextStation
        self.startDate = .now
        self.isActive = true
        persist()

        RideSessionController.shared.start(
            className: className, formationCode: formationCode,
            lineName: lineName, nextStation: nextStation
        )
    }

    /// 終了して RideSegment を保存
    func end(toStation: String, distanceKm: Double, context: ModelContext) async {
        let duration = Int(Date.now.timeIntervalSince(startDate ?? .now))
        let seg = RideSegment(fromStation: fromStation, toStation: toStation, lineName: lineName)
        seg.formationCode = formationCode
        seg.distanceKm = distanceKm
        seg.durationSec = duration
        context.insert(seg)
        try? context.save()
        Haptics.success()

        await RideSessionController.shared.end()
        reset()
    }

    private func reset() {
        isActive = false
        className = ""; formationCode = ""; lineName = ""
        fromStation = ""; nextStation = ""; startDate = nil
        defaults.removeObject(forKey: key)
    }

    // MARK: - 永続化

    private struct Persisted: Codable {
        var className: String
        var formationCode: String
        var lineName: String
        var fromStation: String
        var nextStation: String
        var startDate: Date
    }

    private func persist() {
        guard let startDate else { return }
        let p = Persisted(className: className, formationCode: formationCode,
                          lineName: lineName, fromStation: fromStation,
                          nextStation: nextStation, startDate: startDate)
        if let data = try? JSONEncoder().encode(p) {
            defaults.set(data, forKey: key)
        }
    }

    private func restore() {
        guard let data = defaults.data(forKey: key),
              let p = try? JSONDecoder().decode(Persisted.self, from: data) else { return }
        // 24時間以上経過しているセッションは破棄（誤起動の救済）
        if Date.now.timeIntervalSince(p.startDate) > 24 * 3600 {
            defaults.removeObject(forKey: key)
            return
        }
        self.className = p.className
        self.formationCode = p.formationCode
        self.lineName = p.lineName
        self.fromStation = p.fromStation
        self.nextStation = p.nextStation
        self.startDate = p.startDate
        self.isActive = true
    }
}

/// 乗車開始シート
struct StartRideView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \VehicleClass.name) private var classes: [VehicleClass]
    let manager: RideManager

    @State private var selectedClass: VehicleClass?
    @State private var formationCode = ""
    @State private var lineName = ""
    @State private var fromStation = ""
    @State private var nextStation = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("乗車する列車") {
                    Picker("形式", selection: $selectedClass) {
                        Text("選択").tag(VehicleClass?.none)
                        ForEach(classes) { Text($0.name).tag(VehicleClass?.some($0)) }
                    }
                    TextField("編成番号（任意）", text: $formationCode)
                    TextField("路線名", text: $lineName)
                }
                Section("区間") {
                    TextField("乗車駅", text: $fromStation)
                    TextField("次の停車駅", text: $nextStation)
                }
            }
            .navigationTitle("乗車を開始")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("開始") {
                        manager.start(
                            className: selectedClass?.name ?? "",
                            formationCode: formationCode,
                            lineName: lineName,
                            fromStation: fromStation,
                            nextStation: nextStation
                        )
                        dismiss()
                    }
                    .disabled(lineName.isEmpty || fromStation.isEmpty)
                }
            }
        }
    }
}

/// 乗車中の画面（ライブアクティビティと同内容を本体でも表示）
struct ActiveRideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let manager: RideManager

    @State private var toStation = ""
    @State private var distanceKm = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "tram.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.orange)

                VStack(spacing: 4) {
                    Text("\(manager.className) \(manager.formationCode)")
                        .font(.title2.bold())
                    Text(manager.lineName)
                        .foregroundStyle(.secondary)
                }

                // 経過時間をリアルタイム表示
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(elapsedString)
                        .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                }

                Text("\(manager.fromStation) を出発")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Spacer()

                Form {
                    Section("降車時に記録") {
                        TextField("降車駅", text: $toStation)
                        TextField("乗車距離 (km)", text: $distanceKm)
                            .keyboardType(.decimalPad)
                    }
                }
                .frame(height: 160)
                .scrollDisabled(true)

                Button(role: .destructive) {
                    Task {
                        await manager.end(
                            toStation: toStation,
                            distanceKm: Double(distanceKm) ?? 0,
                            context: context
                        )
                        dismiss()
                    }
                } label: {
                    Text("乗車を終了して記録")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("乗車中")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var elapsedString: String {
        let sec = Int(Date.now.timeIntervalSince(manager.startDate ?? .now))
        return String(format: "%d:%02d", sec / 60, sec % 60)
    }
}
