import SwiftUI
import Charts
import WellnessModels
import WellnessStores

public struct AnalyticsScreen: View {
    @Environment(AnalyticsFeatureStore.self) private var analyticsStore
    @Environment(MealFeatureStore.self) private var mealStore
    @Environment(WorkoutFeatureStore.self) private var workoutStore
    @Environment(SleepFeatureStore.self) private var sleepStore
    @State private var selectedRange: AnalyticsRange = .week

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Picker("Range", selection: $selectedRange) {
                    ForEach(AnalyticsRange.allCases, id: \.self) { range in
                        Text(range.rawValue.capitalized).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                LazyVStack(spacing: 16) {
                    NutritionChartSection(meals: analyticsStore.meals, range: selectedRange)
                    TrainingChartSection(sessions: analyticsStore.sessions, range: selectedRange)
                    SleepChartSection(entries: analyticsStore.sleepEntries, range: selectedRange)
                    BodyWeightChartSection(entries: analyticsStore.bodyWeightEntries)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Analytics")
        .onChange(of: selectedRange) { _, _ in loadRange() }
        .task { loadRange() }
    }

    private func loadRange() {
        let end = Date.now
        let start = Calendar.current.date(byAdding: .day, value: -selectedRange.days, to: end) ?? end
        Task { await analyticsStore.load(range: start...end) }
    }
}

// MARK: - Nutrition

struct NutritionChartSection: View {
    let meals: [Meal]
    let range: AnalyticsRange

    var body: some View {
        ChartCard(title: "Nutrition", icon: "fork.knife") {
            let data = dailyCalories
            if data.isEmpty {
                emptyChart
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Calories", item.value)
                    )
                    .foregroundStyle(.orange.gradient)
                }
                .chartYAxisLabel("kcal")
                .frame(height: 180)
            }

            let totals = macroTotals
            HStack(spacing: 16) {
                MacroStat(label: "Avg Cal", value: "\(Int(totals.avgKcal))", color: .orange)
                MacroStat(label: "Avg P", value: "\(Int(totals.avgProtein))g", color: .blue)
                MacroStat(label: "Avg C", value: "\(Int(totals.avgCarbs))g", color: .green)
                MacroStat(label: "Avg F", value: "\(Int(totals.avgFat))g", color: .yellow)
            }
            .padding(.top, 4)
        }
    }

    private var dailyCalories: [ChartDataPoint] {
        let cal = Calendar.current
        var byDay: [Date: Double] = [:]
        for meal in meals {
            let day = cal.startOfDay(for: MealFeatureStore.date(from: meal.date))
            byDay[day, default: 0] += meal.totalKcal
        }
        return byDay.map { ChartDataPoint(date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }
    }

    private var macroTotals: (avgKcal: Double, avgProtein: Double, avgCarbs: Double, avgFat: Double) {
        guard !meals.isEmpty else { return (0, 0, 0, 0) }
        let days = max(1, Double(Set(meals.map(\.date)).count))
        return (
            meals.reduce(0) { $0 + $1.totalKcal } / days,
            meals.reduce(0) { $0 + $1.totalProtein } / days,
            meals.reduce(0) { $0 + $1.totalCarbs } / days,
            meals.reduce(0) { $0 + $1.totalFat } / days
        )
    }

    private var emptyChart: some View {
        Text("No meal data for this period")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(height: 100)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Training

struct TrainingChartSection: View {
    let sessions: [WorkoutSession]
    let range: AnalyticsRange

    var body: some View {
        ChartCard(title: "Training", icon: "dumbbell") {
            let data = dailyVolume
            if data.isEmpty {
                Text("No workout data for this period")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Sets", item.value)
                    )
                    .foregroundStyle(.blue.gradient)
                }
                .chartYAxisLabel("sets")
                .frame(height: 180)
            }

            HStack(spacing: 16) {
                MacroStat(label: "Sessions", value: "\(sessions.filter(\.isCompleted).count)", color: .blue)
                MacroStat(label: "Total Sets", value: "\(sessions.flatMap(\.sets).count)", color: .cyan)
            }
            .padding(.top, 4)
        }
    }

    private var dailyVolume: [ChartDataPoint] {
        let cal = Calendar.current
        var byDay: [Date: Double] = [:]
        for session in sessions where session.isCompleted {
            let day = cal.startOfDay(for: session.startedAt)
            byDay[day, default: 0] += Double(session.sets.count)
        }
        return byDay.map { ChartDataPoint(date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }
    }
}

// MARK: - Sleep

struct SleepChartSection: View {
    let entries: [SleepEntry]
    let range: AnalyticsRange

    var body: some View {
        ChartCard(title: "Sleep", icon: "moon.zzz") {
            let data = dailySleep
            if data.isEmpty {
                Text("No sleep data for this period")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Hours", item.value)
                    )
                    .foregroundStyle(item.quality >= 4 ? Color.indigo : item.quality >= 3 ? Color.purple.opacity(0.7) : Color.red.opacity(0.7))
                }
                .chartYAxisLabel("hours")
                .frame(height: 180)
            }

            let completed = entries.filter { $0.endedAt != nil }
            let avgH = completed.compactMap(\.durationInHours)
            let avgQ = completed.compactMap(\.quality)
            HStack(spacing: 16) {
                MacroStat(
                    label: "Avg Hours",
                    value: avgH.isEmpty ? "—" : String(format: "%.1f", avgH.reduce(0, +) / Double(avgH.count)),
                    color: .indigo
                )
                MacroStat(
                    label: "Avg Quality",
                    value: avgQ.isEmpty ? "—" : String(format: "%.1f/5", Double(avgQ.reduce(0, +)) / Double(avgQ.count)),
                    color: .purple
                )
            }
            .padding(.top, 4)
        }
    }

    private var dailySleep: [SleepChartPoint] {
        let cal = Calendar.current
        return entries.compactMap { entry in
            guard let hours = entry.durationInHours else { return nil }
            let day = cal.startOfDay(for: entry.startedAt)
            return SleepChartPoint(date: day, value: hours, quality: entry.quality ?? 3)
        }
        .sorted { $0.date < $1.date }
    }
}

// MARK: - Body Weight

struct BodyWeightChartSection: View {
    let entries: [BodyWeightEntry]

    var body: some View {
        ChartCard(title: "Body Weight", icon: "scalemass") {
            if entries.isEmpty {
                Text("No weight data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(entries.sorted { $0.recordedAt < $1.recordedAt }) { entry in
                    LineMark(
                        x: .value("Date", entry.recordedAt, unit: .day),
                        y: .value("kg", entry.kg)
                    )
                    .foregroundStyle(.teal)
                    PointMark(
                        x: .value("Date", entry.recordedAt, unit: .day),
                        y: .value("kg", entry.kg)
                    )
                    .foregroundStyle(.teal)
                }
                .chartYAxisLabel("kg")
                .frame(height: 180)
            }

            if let latest = entries.sorted(by: { $0.recordedAt > $1.recordedAt }).first {
                HStack(spacing: 16) {
                    MacroStat(label: "Current", value: String(format: "%.1f kg", latest.kg), color: .teal)
                }
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Shared Components

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct SleepChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let quality: Int
}

struct ChartCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline)
            }
            content
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct MacroStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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
