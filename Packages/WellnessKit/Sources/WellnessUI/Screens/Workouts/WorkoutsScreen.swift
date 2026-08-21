import SwiftUI
import WellnessModels
import WellnessStores

public struct WorkoutsScreen: View {
    @Environment(WorkoutFeatureStore.self) private var workoutStore

    public init() {}

    public var body: some View {
        List {
            if let active = workoutStore.activeSession {
                Section("Active Session") {
                    ActiveSessionRow(session: active)
                }
            }

            Section("Templates") {
                if workoutStore.templates.isEmpty {
                    ContentUnavailableView(
                        "No Templates",
                        systemImage: "dumbbell",
                        description: Text("Complete onboarding to generate workout templates.")
                    )
                } else {
                    ForEach(workoutStore.templates) { template in
                        TemplateRow(template: template)
                    }
                }
            }

            Section("Recent Sessions") {
                if workoutStore.recentSessions.isEmpty {
                    Text("No sessions yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(workoutStore.recentSessions.prefix(10)) { session in
                        SessionRow(session: session)
                    }
                }
            }
        }
        .navigationTitle("Workouts")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                NavigationLink(value: AppRoute.workoutExercises) {
                    Image(systemName: "figure.strengthtraining.traditional")
                }
            }
        }
        .refreshable { await workoutStore.load() }
    }
}

struct TemplateRow: View {
    let template: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name)
                .font(.headline)
            HStack {
                Text("\(template.exercises.count) exercises")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if template.origin == .generated {
                    Text("Generated")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.fill.tertiary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct ActiveSessionRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack {
            Image(systemName: "timer")
                .foregroundStyle(.green)
            VStack(alignment: .leading) {
                Text("In Progress")
                    .font(.headline)
                Text("Started \(session.startedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            NavigationLink(value: AppRoute.workoutSession(id: session.id)) {
                Text("Resume")
            }
        }
    }
}

struct SessionRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                Text("\(session.sets.count) sets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let ended = session.endedAt {
                let duration = ended.timeIntervalSince(session.startedAt) / 60
                Text("\(Int(duration)) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
