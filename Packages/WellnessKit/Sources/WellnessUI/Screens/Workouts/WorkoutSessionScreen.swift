import SwiftUI
import WellnessModels
import WellnessStores

public struct WorkoutSessionScreen: View {
    @Environment(WorkoutFeatureStore.self) private var workoutStore
    @Environment(\.dismiss) private var dismiss

    let sessionId: String

    @State private var session: WorkoutSession?
    @State private var showExercisePicker = false
    @State private var showFinishConfirm = false
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?

    public init(sessionId: String) {
        self.sessionId = sessionId
    }

    public var body: some View {
        Group {
            if let session {
                sessionContent(session)
            } else {
                ProgressView("Loading…")
            }
        }
        .navigationTitle("Workout")
        .navigationBarBackButtonHidden(session?.endedAt == nil)
        .toolbar {
            if session?.endedAt == nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") { showFinishConfirm = true }
                }
            }
        }
        .confirmationDialog("Finish Workout?", isPresented: $showFinishConfirm) {
            Button("Complete Workout") {
                Task {
                    try? await workoutStore.endSession(sessionId)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showExercisePicker) {
            NavigationStack {
                ExercisePickerSheet(sessionId: sessionId)
            }
        }
        .task {
            await workoutStore.loadExercises()
            session = await workoutStore.session(byId: sessionId)
            startTimer()
        }
        .onDisappear { timer?.invalidate() }
    }

    @ViewBuilder
    private func sessionContent(_ session: WorkoutSession) -> some View {
        List {
            Section {
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(.green)
                    Text(formatDuration(elapsedSeconds))
                        .font(.title2.monospacedDigit())
                    Spacer()
                    Text("\(session.sets.count) sets")
                        .foregroundStyle(.secondary)
                }
            }

            let grouped = groupedSets(session.sets)
            ForEach(grouped, id: \.exerciseId) { group in
                Section(group.exerciseName) {
                    ForEach(Array(group.sets.enumerated()), id: \.element.id) { idx, set in
                        SetRow(index: idx + 1, set: set)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { try? await workoutStore.deleteSet(id: set.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    Button {
                        Task { await addSet(exerciseId: group.exerciseId, existingSets: group.sets) }
                    } label: {
                        Label("Add Set", systemImage: "plus.circle")
                    }
                }
            }

            Section {
                Button {
                    showExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "figure.strengthtraining.traditional")
                }
            }
        }
        .onChange(of: workoutStore.activeSession) { _, newSession in
            if let newSession, newSession.id == sessionId {
                self.session = newSession
            }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let session, session.endedAt == nil {
                elapsedSeconds = Int(Date.now.timeIntervalSince(session.startedAt))
            }
        }
    }

    private func addSet(exerciseId: String, existingSets: [SetEntry]) async {
        let last = existingSets.last
        let entry = SetEntry(
            id: UUID().uuidString,
            sessionId: sessionId,
            exerciseId: exerciseId,
            orderIndex: (session?.sets.count ?? 0),
            reps: last?.reps ?? 10,
            weight: last?.weight,
            restSeconds: last?.restSeconds ?? 90
        )
        try? await workoutStore.addSet(entry)
        session = await workoutStore.session(byId: sessionId)
    }

    private struct ExerciseGroup {
        let exerciseId: String
        let exerciseName: String
        let sets: [SetEntry]
    }

    private func groupedSets(_ sets: [SetEntry]) -> [ExerciseGroup] {
        var seen: [String] = []
        var grouped: [String: [SetEntry]] = [:]
        for set in sets.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            if !seen.contains(set.exerciseId) { seen.append(set.exerciseId) }
            grouped[set.exerciseId, default: []].append(set)
        }
        return seen.map { id in
            ExerciseGroup(
                exerciseId: id,
                exerciseName: workoutStore.exercise(byId: id)?.name ?? "Exercise",
                sets: grouped[id] ?? []
            )
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

private struct SetRow: View {
    let index: Int
    let set: SetEntry

    var body: some View {
        HStack {
            Text("Set \(index)")
                .font(.subheadline.bold())
                .frame(width: 50, alignment: .leading)
            if let w = set.weight {
                Text("\(String(format: "%.1f", w)) kg")
            }
            Text("× \(set.reps) reps")
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .font(.subheadline)
    }
}
