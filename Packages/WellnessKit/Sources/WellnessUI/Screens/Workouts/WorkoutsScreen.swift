import SwiftUI
import WellnessModels
import WellnessStores

public struct WorkoutsScreen: View {
    @Environment(WorkoutFeatureStore.self) private var workoutStore

    @State private var startingSession = false

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
                        WorkoutTemplateRow(template: template)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { try? await workoutStore.deleteTemplate(id: template.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                NavigationLink(value: AppRoute.workoutTemplateEdit(id: template.id)) {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }

            Section("Recent Sessions") {
                if workoutStore.recentSessions.isEmpty {
                    Text("No sessions yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(workoutStore.recentSessions.prefix(10)) { session in
                        NavigationLink(value: AppRoute.workoutSession(id: session.id)) {
                            SessionRow(session: session)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { try? await workoutStore.deleteSession(id: session.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Workouts")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button {
                        startQuickWorkout()
                    } label: {
                        Label("Quick Workout", systemImage: "bolt")
                    }
                    NavigationLink(value: AppRoute.workoutTemplateEdit(id: nil)) {
                        Label("New Template", systemImage: "doc.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .automatic) {
                NavigationLink(value: AppRoute.workoutExercises) {
                    Image(systemName: "figure.strengthtraining.traditional")
                }
            }
        }
        .refreshable { await workoutStore.load() }
    }

    private func startQuickWorkout() {
        Task {
            let session = try await workoutStore.startSession(templateId: nil)
            startingSession = true
        }
    }
}

struct WorkoutTemplateRow: View {
    let template: WorkoutTemplate
    @Environment(WorkoutFeatureStore.self) private var workoutStore

    var body: some View {
        HStack {
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
            Spacer()
            Button("Start") {
                Task { _ = try? await workoutStore.startSession(templateId: template.id) }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
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
