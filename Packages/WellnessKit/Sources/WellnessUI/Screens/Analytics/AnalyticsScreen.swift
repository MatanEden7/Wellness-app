import SwiftUI
import WellnessModels
import WellnessStores

public struct AnalyticsScreen: View {
    @Environment(MealFeatureStore.self) private var mealStore
    @Environment(WorkoutFeatureStore.self) private var workoutStore
    @Environment(SleepFeatureStore.self) private var sleepStore
    @State private var selectedRange: AnalyticsRange = .week

    public init() {}

    public var body: some View {
        List {
            Section {
                Picker("Range", selection: $selectedRange) {
                    ForEach(AnalyticsRange.allCases, id: \.self) { range in
                        Text(range.rawValue.capitalized).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            Section("Nutrition") {
                StatRow(label: "Calories", value: "\(Int(mealStore.totalKcal)) kcal")
                StatRow(label: "Protein", value: "\(Int(mealStore.totalProtein))g")
                StatRow(label: "Carbs", value: "\(Int(mealStore.totalCarbs))g")
                StatRow(label: "Fat", value: "\(Int(mealStore.totalFat))g")
            }

            Section("Workouts") {
                StatRow(label: "Templates", value: "\(workoutStore.templates.count)")
                StatRow(label: "Recent Sessions", value: "\(workoutStore.recentSessions.count)")
                if let last = workoutStore.recentSessions.first {
                    StatRow(label: "Last Session", value: last.startedAt.formatted(date: .abbreviated, time: .omitted))
                }
            }

            Section("Sleep") {
                let completed = sleepStore.recentEntries.filter { $0.endedAt != nil }
                StatRow(label: "Entries", value: "\(completed.count)")
                if !completed.isEmpty {
                    let avgHours = completed.compactMap(\.durationInHours).reduce(0, +) / Double(completed.compactMap(\.durationInHours).count)
                    StatRow(label: "Avg Duration", value: String(format: "%.1fh", avgHours))
                }
                let avgQuality = completed.compactMap(\.quality)
                if !avgQuality.isEmpty {
                    let avg = Double(avgQuality.reduce(0, +)) / Double(avgQuality.count)
                    StatRow(label: "Avg Quality", value: String(format: "%.1f/5", avg))
                }
            }
        }
        .navigationTitle("Analytics")
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
