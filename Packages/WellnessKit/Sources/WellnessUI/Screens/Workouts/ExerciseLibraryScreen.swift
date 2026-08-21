import SwiftUI
import WellnessModels
import WellnessStores

public struct ExerciseLibraryScreen: View {
    @Environment(WorkoutFeatureStore.self) private var workoutStore

    @State private var searchText = ""
    @State private var editingExercise: Exercise?
    @State private var showNewExercise = false

    public init() {}

    public var body: some View {
        List {
            ForEach(filteredExercises) { exercise in
                Button {
                    editingExercise = exercise
                } label: {
                    ExerciseRow(exercise: exercise)
                }
                .tint(.primary)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { try? await workoutStore.deleteExercise(id: exercise.id) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Exercises")
        .searchable(text: $searchText, prompt: "Search exercises")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { showNewExercise = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editingExercise) { exercise in
            NavigationStack {
                ExerciseEditorSheet(exercise: exercise)
            }
        }
        .sheet(isPresented: $showNewExercise) {
            NavigationStack {
                ExerciseEditorSheet(exercise: nil)
            }
        }
        .task { await workoutStore.loadExercises() }
    }

    private var filteredExercises: [Exercise] {
        guard !searchText.isEmpty else { return workoutStore.allExercises }
        let query = searchText.lowercased()
        return workoutStore.allExercises.filter { $0.name.lowercased().contains(query) }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.body)
            HStack(spacing: 8) {
                if let muscle = exercise.primaryMuscle {
                    Text(muscle.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !exercise.equipment.isEmpty {
                    Text(exercise.equipment.map(\.rawValue).joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
