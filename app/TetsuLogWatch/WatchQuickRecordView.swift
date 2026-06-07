import SwiftUI
import SwiftData
import CoreLocation
#if os(watchOS)
import WatchKit
#endif

/// Watch のクイック記録: ベルトの一押しで「いま見た」を残す。
/// 形式は最後に記録したものを既定値に。位置情報は端末内で自動取得を試みる。
struct WatchQuickRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \VehicleClass.name) private var classes: [VehicleClass]
    @Query(sort: \Sighting.date, order: .reverse) private var recent: [Sighting]

    @State private var selectedClass: VehicleClass?
    @State private var formationCode = ""
    @State private var stationName = ""
    @State private var saved = false

    private var recentClassNames: [VehicleClass] {
        // 直近5件で出会った形式を頭に
        let recentClasses = Array(Set(recent.prefix(20).compactMap { $0.formation?.vehicleClass }))
        return recentClasses + classes.filter { !recentClasses.contains($0) }
    }

    var body: some View {
        ZStack {
            WatchNavyBackground()
            ScrollView {
                VStack(spacing: 8) {
                    // 形式選択
                    WatchPaperCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("形 式")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(WatchTheme.Palette.inkSub)
                            Picker("", selection: $selectedClass) {
                                Text("選択").tag(VehicleClass?.none)
                                ForEach(recentClassNames) { vc in
                                    Text(vc.name).tag(VehicleClass?.some(vc))
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.navigationLink)
                            .tint(WatchTheme.Palette.navy)
                        }
                    }

                    // 編成番号
                    WatchPaperCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("編成番号 (任意)")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(WatchTheme.Palette.inkSub)
                            TextField("トウ47", text: $formationCode)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundStyle(WatchTheme.Palette.ink)
                        }
                    }

                    // 駅名
                    WatchPaperCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("駅 (任意)")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(WatchTheme.Palette.inkSub)
                            TextField("新宿", text: $stationName)
                                .font(.system(size: 14))
                                .foregroundStyle(WatchTheme.Palette.ink)
                        }
                    }

                    // 保存ボタン
                    Button {
                        save()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: saved ? "checkmark.circle.fill" : "tram.fill")
                            Text(saved ? "保存しました" : "記録する")
                                .font(.system(size: 13, weight: .heavy, design: .serif))
                                .tracking(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(saved ? WatchTheme.Palette.gold : WatchTheme.Palette.red)
                        )
                        .foregroundStyle(WatchTheme.Palette.paper)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedClass == nil || saved)
                }
                .padding(.horizontal, 6)
                .padding(.top, 4)
            }
        }
        .navigationTitle("記録")
    }

    private func save() {
        guard let vc = selectedClass else { return }

        // 編成番号から既存編成を探す。無ければ作る。
        let formation: Formation
        if !formationCode.isEmpty,
           let existing = vc.formations?.first(where: { $0.code == formationCode }) {
            formation = existing
        } else if !formationCode.isEmpty {
            let f = Formation(code: formationCode, carCount: 0)
            f.vehicleClass = vc
            context.insert(f)
            formation = f
        } else if let any = vc.formations?.first {
            formation = any
        } else {
            // 形式に編成が一切無い場合は仮編成
            let f = Formation(code: "?", carCount: 0)
            f.vehicleClass = vc
            context.insert(f)
            formation = f
        }

        let sighting = Sighting(date: .now, stationName: stationName, lineName: "")
        sighting.formation = formation
        context.insert(sighting)
        try? context.save()

        // 成功フィードバック（watchOS のハプティクス）
        #if os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #endif
        saved = true

        // 0.8秒後に閉じる
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
}
