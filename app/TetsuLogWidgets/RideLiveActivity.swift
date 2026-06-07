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
                .activityBackgroundTint(Color.black.opacity(0.6))
                .activitySystemActionForegroundColor(.orange)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.className, systemImage: "tram.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatElapsed(context.state.elapsedSec))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.formationCode)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        ProgressView(value: context.state.progress)
                            .tint(.orange)
                        HStack {
                            Text("次は \(context.state.nextStation)")
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%.1f km", context.state.distanceKm))
                                .font(.caption.monospaced())
                                .foregroundStyle(.green)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "tram.fill").foregroundStyle(.orange)
            } compactTrailing: {
                Text(formatElapsed(context.state.elapsedSec))
                    .font(.caption2.monospaced())
            } minimal: {
                Image(systemName: "tram.fill").foregroundStyle(.orange)
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
                    .foregroundStyle(.orange)
                Spacer()
                Text(formatElapsed(context.state.elapsedSec))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Text("\(context.attributes.className) \(context.attributes.formationCode)")
                .font(.headline)
            Text(context.attributes.lineName)
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressView(value: context.state.progress).tint(.orange)

            HStack {
                Text("次は \(context.state.nextStation)").font(.caption)
                Spacer()
                Text(String(format: "%.1f km", context.state.distanceKm))
                    .font(.caption.monospaced())
                    .foregroundStyle(.green)
            }
        }
        .padding()
    }
}

private func formatElapsed(_ sec: Int) -> String {
    String(format: "%d:%02d", sec / 60, sec % 60)
}
