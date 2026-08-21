import WidgetKit
import SwiftUI
import WellnessServices

struct NextUpProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextUpEntry {
        NextUpEntry(date: .now, events: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (NextUpEntry) -> Void) {
        let events = WidgetSnapshotStore.load()?.nextEvents ?? []
        completion(NextUpEntry(date: .now, events: events))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextUpEntry>) -> Void) {
        let events = WidgetSnapshotStore.load()?.nextEvents ?? []
        let entry = NextUpEntry(date: .now, events: events)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct NextUpEntry: TimelineEntry {
    let date: Date
    let events: [WidgetEvent]
}

struct NextUpWidget: Widget {
    let kind = "NextUpWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextUpProvider()) { entry in
            NextUpWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next Up")
        .description("Your upcoming events.")
        .supportedFamilies([.systemMedium])
    }
}

struct NextUpWidgetView: View {
    let entry: NextUpEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Next Up")
                .font(.headline)

            if entry.events.isEmpty {
                Text("No upcoming events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entry.events.prefix(3)) { event in
                    HStack(spacing: 6) {
                        eventIcon(event.type)
                            .font(.caption)
                            .frame(width: 16)
                        Text(event.title)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text(event.scheduledAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func eventIcon(_ type: String) -> some View {
        switch type {
        case "meal": Image(systemName: "fork.knife").foregroundStyle(.orange)
        case "workout": Image(systemName: "dumbbell").foregroundStyle(.blue)
        case "sleep": Image(systemName: "moon.zzz").foregroundStyle(.purple)
        default: Image(systemName: "calendar").foregroundStyle(.secondary)
        }
    }
}
