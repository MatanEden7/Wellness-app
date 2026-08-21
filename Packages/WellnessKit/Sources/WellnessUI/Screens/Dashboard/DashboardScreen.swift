import SwiftUI
import WellnessModels
import WellnessStores

public struct DashboardScreen: View {
    @Environment(ProfileFeatureStore.self) private var profileStore
    @Environment(MealFeatureStore.self) private var mealStore
    @Environment(WorkoutFeatureStore.self) private var workoutStore
    @Environment(SleepFeatureStore.self) private var sleepStore
    @Environment(CalendarFeatureStore.self) private var calendarStore

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let profile = profileStore.profile {
                    calorieCard(profile: profile)
                }

                todayEventsCard

                HStack(spacing: 12) {
                    quickStatCard(
                        title: "Workouts",
                        value: "\(workoutStore.recentSessions.count)",
                        subtitle: "sessions",
                        icon: "dumbbell",
                        color: .blue
                    )
                    quickStatCard(
                        title: "Sleep",
                        value: sleepAvgText,
                        subtitle: "avg hours",
                        icon: "moon.zzz",
                        color: .purple
                    )
                }

                if workoutStore.activeSession != nil {
                    activeWorkoutBanner
                }

                if sleepStore.activeSleep != nil {
                    activeSleepBanner
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func calorieCard(profile: UserProfile) -> some View {
        VStack(spacing: 8) {
            Text("Today's Nutrition")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 20) {
                VStack {
                    Text("\(Int(mealStore.totalKcal))")
                        .font(.title.bold())
                    Text("of \(Int(profile.calorieTarget)) kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    macroRow("P", current: mealStore.totalProtein, target: profile.proteinTargetG, color: .blue)
                    macroRow("C", current: mealStore.totalCarbs, target: profile.carbsTargetG, color: .orange)
                    macroRow("F", current: mealStore.totalFat, target: profile.fatTargetG, color: .yellow)
                }
            }
        }
        .padding()
        .background(.fill.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func macroRow(_ label: String, current: Double, target: Double, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(label): \(Int(current))/\(Int(target))g")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var todayEventsCard: some View {
        let events = calendarStore.eventsForDate(Date())
        let planned = events.filter { $0.status == .planned }.count
        let done = events.filter { $0.status == .completed }.count

        return VStack(alignment: .leading, spacing: 4) {
            Text("Today's Schedule")
                .font(.headline)
            HStack {
                Label("\(done) done", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Label("\(planned) planned", systemImage: "circle")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.fill.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func quickStatCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.fill.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var sleepAvgText: String {
        let completed = sleepStore.recentEntries.compactMap(\.durationInHours)
        guard !completed.isEmpty else { return "--" }
        return String(format: "%.1f", completed.reduce(0, +) / Double(completed.count))
    }

    private var activeWorkoutBanner: some View {
        NavigationLink(value: AppRoute.workoutSession(id: workoutStore.activeSession!.id)) {
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.green)
                Text("Workout in progress")
                    .font(.subheadline.bold())
                Spacer()
                Text("Resume")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var activeSleepBanner: some View {
        HStack {
            Image(systemName: "moon.zzz.fill")
                .foregroundStyle(.purple)
            Text("Sleep tracking active")
                .font(.subheadline.bold())
            Spacer()
            Text("Since \(sleepStore.activeSleep!.startedAt.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.purple.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
