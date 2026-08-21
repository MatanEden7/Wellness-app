import ActivityKit
import SwiftUI
import WidgetKit
import WellnessModels

struct WorkoutLiveActivity: Widget {
    let kind = "WorkoutLiveActivity"

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            WorkoutLiveActivityView(state: context.state, attributes: context.attributes)
                .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.templateName, systemImage: "dumbbell")
                        .font(.caption)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                        .font(.caption.bold())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let restEnd = context.state.restEndDate {
                        HStack {
                            Image(systemName: "timer")
                            Text(timerInterval: Date.now...restEnd, countsDown: true)
                                .font(.title2.bold().monospacedDigit())
                            Spacer()
                            Text(context.state.exerciseName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            Text(context.state.exerciseName)
                                .font(.headline)
                            Spacer()
                            Text("Working")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "dumbbell")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                if let restEnd = context.state.restEndDate {
                    Text(timerInterval: Date.now...restEnd, countsDown: true)
                        .monospacedDigit()
                        .frame(width: 40)
                } else {
                    Text("\(context.state.currentSet)/\(context.state.totalSets)")
                        .font(.caption.bold())
                }
            } minimal: {
                Image(systemName: "dumbbell")
                    .foregroundStyle(.blue)
            }
        }
    }
}

struct WorkoutLiveActivityView: View {
    let state: WorkoutActivityAttributes.ContentState
    let attributes: WorkoutActivityAttributes

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(attributes.templateName, systemImage: "dumbbell")
                    .font(.subheadline.bold())
                Spacer()
                Text("Set \(state.currentSet)/\(state.totalSets)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(state.exerciseName)
                    .font(.headline)
                Spacer()
                if let restEnd = state.restEndDate {
                    Label {
                        Text(timerInterval: Date.now...restEnd, countsDown: true)
                            .font(.title3.bold().monospacedDigit())
                    } icon: {
                        Image(systemName: "timer")
                    }
                    .foregroundStyle(.orange)
                } else {
                    Text("Working")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }
            }

            HStack {
                Text("Started \(attributes.startedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }
}
