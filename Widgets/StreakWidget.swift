import WidgetKit
import SwiftUI
import WellnessServices

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, streak: 0, lastWorkout: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let snapshot = WidgetSnapshotStore.load()
        completion(StreakEntry(date: .now, streak: snapshot?.workoutStreak ?? 0, lastWorkout: snapshot?.lastWorkoutDate))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let snapshot = WidgetSnapshotStore.load()
        let entry = StreakEntry(date: .now, streak: snapshot?.workoutStreak ?? 0, lastWorkout: snapshot?.lastWorkoutDate)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let lastWorkout: Date?
}

struct StreakWidget: Widget {
    let kind = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Streak")
        .description("Your workout streak.")
        .supportedFamilies([.systemSmall])
    }
}

struct StreakWidgetView: View {
    let entry: StreakEntry

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundStyle(.orange)
            Text("\(entry.streak)")
                .font(.title.bold())
            Text("day streak")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let last = entry.lastWorkout {
                Text(last.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
