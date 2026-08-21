import WidgetKit
import SwiftUI
import WellnessServices

struct LockScreenCalorieWidget: Widget {
    let kind = "LockScreenCalorie"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            if let snapshot = entry.snapshot {
                Gauge(value: snapshot.kcalProgress) {
                    Image(systemName: "flame")
                }
                .gaugeStyle(.accessoryCircular)
            } else {
                Image(systemName: "flame")
                    .widgetAccentable()
            }
        }
        .configurationDisplayName("Calories")
        .description("Calorie ring on your lock screen.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct LockScreenNextEventWidget: Widget {
    let kind = "LockScreenNextEvent"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextUpProvider()) { entry in
            if let event = entry.events.first {
                VStack(alignment: .leading) {
                    Text(event.title)
                        .font(.caption)
                        .lineLimit(1)
                        .widgetAccentable()
                    Text(event.scheduledAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No events")
                    .font(.caption)
            }
        }
        .configurationDisplayName("Next Event")
        .description("Your next scheduled event.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct LockScreenStreakWidget: Widget {
    let kind = "LockScreenStreak"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            Text("\(entry.streak) day streak")
                .font(.caption)
        }
        .configurationDisplayName("Streak")
        .description("Workout streak on your lock screen.")
        .supportedFamilies([.accessoryInline])
    }
}
