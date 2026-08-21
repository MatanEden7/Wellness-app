import WidgetKit
import SwiftUI
import WellnessServices

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: .now, snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(TodayEntry(date: .now, snapshot: WidgetSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let entry = TodayEntry(date: .now, snapshot: WidgetSnapshotStore.load())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct TodayEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct TodayWidget: Widget {
    let kind = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today")
        .description("Today's nutrition at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TodayWidgetView: View {
    let entry: TodayEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ProgressRing(progress: snapshot.kcalProgress, color: .green, size: 44)
                        .overlay {
                            Text("\(Int(snapshot.todayKcal))")
                                .font(.system(size: 10, weight: .bold))
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(snapshot.todayKcal))/\(Int(snapshot.kcalGoal))")
                            .font(.caption.bold())
                        Text("kcal")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 8) {
                    MacroChip(label: "P", grams: Int(snapshot.todayProtein), color: .blue)
                    MacroChip(label: "C", grams: Int(snapshot.todayCarbs), color: .orange)
                    MacroChip(label: "F", grams: Int(snapshot.todayFat), color: .yellow)
                }
            }
        } else {
            Text("Open the app to start tracking")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ProgressRing: View {
    let progress: Double
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

struct MacroChip: View {
    let label: String
    let grams: Int
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(grams)g")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}
