import SwiftUI
import WellnessModels
import WellnessStores

struct ExercisePickerSheet: View {
    @Environment(WorkoutFeatureStore.self) private var workoutStore
    @Environment(\.dismiss) private var dismiss

    let sessionId: String

    @State private var searchText = ""
    @State private var selectedMuscle: String?
    @State private var weight: Double = 0
    @State private var reps: Int = 10
    @State private var sets: Int = 3
    @State private var restSeconds: Int = 90
    @State private var selectedExercise: Exercise?

    var body: some View {
        Group {
            if let exercise = selectedExercise {
                prescriptionView(exercise)
            } else {
                exerciseList
            }
        }
        .navigationTitle("Add Exercise")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private var exerciseList: some View {
        List {
            ForEach(filteredExercises) { exercise in
                Button {
                    selectedExercise = exercise
                } label: {
                    ExerciseRow(exercise: exercise)
                }
                .tint(.primary)
            }
        }
        .searchable(text: $searchText, prompt: "Search exercises")
    }

    @ViewBuilder
    private func prescriptionView(_ exercise: Exercise) -> some View {
        Form {
            Section {
                Text(exercise.name)
                    .font(.headline)
                if let muscle = exercise.primaryMuscle {
                    Text(muscle.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Section("Prescription") {
                Stepper("Sets: \(sets)", value: $sets, in: 1...10)
                Stepper("Reps: \(reps)", value: $reps, in: 1...100)
                HStack {
                    Text("Weight")
                    Spacer()
                    TextField("0", value: $weight, format: .number)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Text(exercise.unit)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    Text("Rest")
                    Spacer()
                    ForEach([60, 90, 120, 180], id: \.self) { sec in
                        Button("\(sec)s") { restSeconds = sec }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(restSeconds == sec ? .accentColor : .secondary)
                    }
                }
            }
            Section {
                Button("Add to Workout") {
                    Task { await addSets(exercise) }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button { selectedExercise = nil } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
    }

    private func addSets(_ exercise: Exercise) async {
        let currentCount = workoutStore.activeSession?.sets.count ?? 0
        for i in 0..<sets {
            let entry = SetEntry(
                id: UUID().uuidString,
                sessionId: sessionId,
                exerciseId: exercise.id,
                orderIndex: currentCount + i,
                reps: reps,
                weight: weight > 0 ? weight : nil,
                restSeconds: restSeconds
            )
            try? await workoutStore.addSet(entry)
        }
        dismiss()
    }

    private var filteredExercises: [Exercise] {
        var result = workoutStore.allExercises
        if let muscle = selectedMuscle {
            result = result.filter { $0.primaryMuscle == muscle }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { $0.name.lowercased().contains(query) }
        }
        return result
    }
}
