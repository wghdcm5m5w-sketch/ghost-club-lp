import WidgetKit
import SwiftUI
import ActivityKit

/// 乗車セッションのライブアクティビティ表示（ロック画面 + Dynamic Island）。
/// RideAttributes.swift を本体とこのターゲットで共有する。
struct RideLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RideAttributes.self) { context in
            // ロック画面 / バナー
            LockScreenRideView(context: context)
                .activityBackgroundTint(WidgetTheme.navy.opacity(0.92))
                .activitySystemActionForegroundColor(WidgetTheme.cream)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.className, systemImage: "tram.fill")
                        .font(.caption.bold())
                        .foregroundStyle(WidgetTheme.red)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatElapsed(context.state.elapsedSec))
                        .font(.caption.monospaced())
                        .foregroundStyle(WidgetTheme.gold)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.formationCode)
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(WidgetTheme.cream)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        ProgressView(value: context.state.progress)
                            .tint(WidgetTheme.red)
                        HStack {
                            Text("次は \(context.state.nextStation)")
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%.1f km", context.state.distanceKm))
                                .font(.caption.monospaced())
                                .foregroundStyle(WidgetTheme.gold)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "tram.fill").foregroundStyle(WidgetTheme.red)
            } compactTrailing: {
                Text(formatElapsed(context.state.elapsedSec))
                    .font(.caption2.monospaced())
                    .foregroundStyle(WidgetTheme.gold)
            } minimal: {
                Image(systemName: "tram.fill").foregroundStyle(WidgetTheme.red)
            }
            .widgetURL(URL(string: "tetsulog://ride"))
        }
    }
}

private struct LockScreenRideView: View {
    let context: ActivityViewContext<RideAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("乗車中", systemImage: "tram.fill")
                    .font(.caption.bold())
                    .foregroundStyle(WidgetTheme.redLight)
                Spacer()
                Text(formatElapsed(context.state.elapsedSec))
                    .font(.caption.monospaced())
                    .foregroundStyle(WidgetTheme.gold)
            }
            Text("\(context.attributes.className) \(context.attributes.formationCode)")
                .font(.system(.headline, design: .serif))
                .foregroundStyle(WidgetTheme.cream)
            Text(context.attributes.lineName)
                .font(.caption)
                .foregroundStyle(WidgetTheme.creamSub)

            ProgressView(value: context.state.progress).tint(WidgetTheme.red)

            HStack {
                Text("次は \(context.state.nextStation)").font(.caption)
                    .foregroundStyle(WidgetTheme.cream)
                Spacer()
                Text(String(format: "%.1f km", context.state.distanceKm))
                    .font(.caption.monospaced())
                    .foregroundStyle(WidgetTheme.gold)
            }
        }
        .padding()
    }
}

private func formatElapsed(_ sec: Int) -> String {
    String(format: "%d:%02d", sec / 60, sec % 60)
}
