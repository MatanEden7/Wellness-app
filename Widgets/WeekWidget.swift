import WidgetKit
import SwiftUI
import WellnessServices

struct WeekProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeekEntry {
        WeekEntry(date: .now, days: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (WeekEntry) -> Void) {
        let days = WidgetSnapshotStore.load()?.weekAdherence ?? []
        completion(WeekEntry(date: .now, days: days))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeekEntry>) -> Void) {
        let days = WidgetSnapshotStore.load()?.weekAdherence ?? []
        let entry = WeekEntry(date: .now, days: days)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct WeekEntry: TimelineEntry {
    let date: Date
    let days: [WidgetDayStatus]
}

struct WeekWidget: Widget {
    let kind = "WeekWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeekProvider()) { entry in
            WeekWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Week")
        .description("7-day adherence overview.")
        .supportedFamilies([.systemLarge])
    }
}

struct WeekWidgetView: View {
    let entry: WeekEntry

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            if entry.days.isEmpty {
                Text("Open the app to start tracking")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(0..<7, id: \.self) { i in
                        Text(dayLabels[i])
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                    ForEach(entry.days.indices, id: \.self) { i in
                        let day = entry.days[i]
                        VStack(spacing: 2) {
                            DotRow(meals: day.mealsLogged, workout: day.workoutDone, sleep: day.sleepLogged)
                        }
                    }
                }

                HStack(spacing: 12) {
                    LegendDot(color: .orange, label: "Meals")
                    LegendDot(color: .blue, label: "Workout")
                    LegendDot(color: .purple, label: "Sleep")
                }
                .font(.caption2)
            }
        }
    }
}

struct DotRow: View {
    let meals: Bool
    let workout: Bool
    let sleep: Bool

    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(meals ? .orange : .gray.opacity(0.3))
                .frame(width: 6, height: 6)
            Circle()
                .fill(workout ? .blue : .gray.opacity(0.3))
                .frame(width: 6, height: 6)
            Circle()
                .fill(sleep ? .purple : .gray.opacity(0.3))
                .frame(width: 6, height: 6)
        }
    }
}

struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}
