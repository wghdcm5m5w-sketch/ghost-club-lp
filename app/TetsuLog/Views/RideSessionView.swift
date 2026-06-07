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
            .tetsuFormStyle()
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
            ZStack {
                NavyBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        // 進行中インジケータ
                        HStack(spacing: 8) {
                            Circle().fill(Theme.Palette.red)
                                .frame(width: 8, height: 8)
                                .opacity(0.9)
                            Text("LIVE")
                                .font(.system(size: 12, weight: .heavy, design: .serif))
                                .tracking(4)
                                .foregroundStyle(Theme.Palette.red)
                        }
                        .padding(.top, 4)

                        // 編成情報カード
                        PaperCard(accent: true) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(manager.className) \(manager.formationCode)")
                                    .font(.system(size: 24, weight: .heavy, design: .serif))
                                    .foregroundStyle(Theme.Palette.ink)
                                Text(manager.lineName)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.Palette.inkSub)
                            }
                        }

                        // 経過時間カード
                        PaperCard(accent: false) {
                            VStack(spacing: 12) {
                                Text("経過時間")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(4)
                                    .foregroundStyle(Theme.Palette.inkSub)
                                TimelineView(.periodic(from: .now, by: 1)) { _ in
                                    Text(elapsedString)
                                        .font(.system(size: 64, weight: .heavy, design: .serif).monospacedDigit())
                                        .foregroundStyle(Theme.Palette.red)
                                }
                                HStack(spacing: 6) {
                                    Image(systemName: "tram.fill")
                                        .foregroundStyle(Theme.Palette.navy)
                                    Text("\(manager.fromStation) を出発")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.Palette.inkSub)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }

                        // 降車入力
                        PaperCard(accent: false) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("降車時に記録").font(Theme.Font.headline(16)).foregroundStyle(Theme.Palette.ink)
                                TextField("降車駅", text: $toStation)
                                    .textFieldStyle(.roundedBorder)
                                TextField("乗車距離 (km)", text: $distanceKm)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)
                            }
                        }

                        // 終了ボタン
                        Button {
                            Task {
                                await manager.end(toStation: toStation, distanceKm: Double(distanceKm) ?? 0, context: context)
                                dismiss()
                            }
                        } label: {
                            Text("乗車を終了して記録")
                                .font(.system(size: 16, weight: .heavy, design: .serif))
                                .tracking(2)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.Palette.red))
                                .foregroundStyle(Theme.Palette.paper)
                                .shadow(color: Theme.Palette.red.opacity(0.35), radius: 10, x: 0, y: 5)
                        }
                        .padding(.top, 4)
                    }
                    .padding(Theme.screenPadding)
                }
            }
            .navigationTitle("乗車中")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Theme.Palette.navy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var elapsedString: String {
        let sec = Int(Date.now.timeIntervalSince(manager.startDate ?? .now))
        return String(format: "%d:%02d", sec / 60, sec % 60)
    }
}
