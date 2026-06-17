import AppIntents
import SwiftData
import Foundation

/// Siri / ショートカット / Spotlight から呼べる App Intents。
/// 共有ストア(SharedStore)を直接操作するためUIを介さず実行できる。
///
/// v1.0 では Xcode の AppIntentsSSUTraining ビルドステップが
/// nonzero exit で落ちる事象を回避するため一時無効化していたが、
/// project.pbxproj に `ENABLE_APP_SHORTCUTS_FLEXIBLE_MATCHING = NO`
/// を焼き込んだ v1.0 提出時点で SSUTraining は通過するようになったため、
/// v1.1 で復活させる。

// MARK: - 遭遇を記録

struct LogSightingIntent: AppIntent {
    static var title: LocalizedStringResource = "編成の遭遇を記録"
    static var description = IntentDescription("形式名と駅名を指定して遭遇を記録します。")

    @Parameter(title: "形式名")
    var className: String

    @Parameter(title: "駅名")
    var stationName: String?

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$className) を記録") {
            \.$stationName
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let container = SharedStore.container else {
            throw $className.needsValueError("データストアにアクセスできません")
        }
        let context = ModelContext(container)

        // 形式を検索（部分一致）
        let descriptor = FetchDescriptor<VehicleClass>()
        let classes = (try? context.fetch(descriptor)) ?? []
        let matched = classes.first { $0.name.contains(className) || className.contains($0.name) }

        let sighting = Sighting(date: .now, stationName: stationName ?? "", lineName: "")
        if let matched {
            // 形式の先頭の編成に仮紐付け（詳細はアプリで編集）
            sighting.formation = matched.formations?.first
        }
        context.insert(sighting)
        try? context.save()

        let where_ = (stationName?.isEmpty == false) ? "（\(stationName!)）" : ""
        return .result(dialog: "\(className)\(where_) を記録しました。")
    }
}

// MARK: - 乗車を開始

struct StartRideIntent: AppIntent {
    static var title: LocalizedStringResource = "乗車を開始"
    static var description = IntentDescription("ライブアクティビティで乗車セッションを開始します。")
    static var openAppWhenRun = true   // ライブアクティビティ起動のため前面化

    @Parameter(title: "路線名")
    var lineName: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        RideSessionController.shared.start(
            className: "", formationCode: "", lineName: lineName, nextStation: ""
        )
        return .result(dialog: "\(lineName) の乗車を開始しました。")
    }
}

// MARK: - ショートカット登録

struct TetsuLogShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogSightingIntent(),
            phrases: [
                "\(.applicationName)で記録",
                "\(.applicationName)に編成を記録"
            ],
            shortTitle: "遭遇を記録",
            systemImageName: "tram.fill"
        )
        AppShortcut(
            intent: StartRideIntent(),
            phrases: [
                "\(.applicationName)で乗車開始",
                "\(.applicationName)で乗車を始める"
            ],
            shortTitle: "乗車を開始",
            systemImageName: "play.circle"
        )
    }
}
