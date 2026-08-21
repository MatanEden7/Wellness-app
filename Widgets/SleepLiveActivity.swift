import ActivityKit
import SwiftUI
import WidgetKit
import WellnessModels

struct SleepLiveActivity: Widget {
    let kind = "SleepLiveActivity"

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepActivityAttributes.self) { context in
            SleepLiveActivityView(state: context.state, attributes: context.attributes)
                .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Sleep", systemImage: "moon.zzz.fill")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.attributes.startedAt...Date.distantFuture, countsDown: false)
                        .font(.caption.bold().monospacedDigit())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("Sleeping since \(context.attributes.startedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            } compactLeading: {
                Image(systemName: "moon.zzz.fill")
                    .foregroundStyle(.purple)
            } compactTrailing: {
                Text(timerInterval: context.attributes.startedAt...Date.distantFuture, countsDown: false)
                    .monospacedDigit()
                    .frame(width: 50)
            } minimal: {
                Image(systemName: "moon.zzz.fill")
                    .foregroundStyle(.purple)
            }
        }
    }
}

struct SleepLiveActivityView: View {
    let state: SleepActivityAttributes.ContentState
    let attributes: SleepActivityAttributes

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label("Sleep Tracking", systemImage: "moon.zzz.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.purple)
                Text("Since \(attributes.startedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(timerInterval: attributes.startedAt...Date.distantFuture, countsDown: false)
                .font(.title2.bold().monospacedDigit())
        }
    }
}
