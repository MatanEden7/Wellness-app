import SwiftUI
import WellnessModels
import WellnessStores

struct ExerciseEditorSheet: View {
    @Environment(WorkoutFeatureStore.self) private var workoutStore
    @Environment(\.dismiss) private var dismiss

    let existingExercise: Exercise?

    @State private var name = ""
    @State private var primaryMuscle = ""
    @State private var unit = "kg"
    @State private var notes = ""
    @State private var selectedEquipment: Set<Equipment> = []
    @State private var isSaving = false

    private var isNew: Bool { existingExercise == nil }

    init(exercise: Exercise?) {
        self.existingExercise = exercise
    }

    var body: some View {
        Form {
            Section {
                TextField("Exercise Name", text: $name)
                Picker("Primary Muscle", selection: $primaryMuscle) {
                    Text("None").tag("")
                    ForEach(muscleGroups, id: \.self) { muscle in
                        Text(muscle.capitalized).tag(muscle)
                    }
                }
                Picker("Weight Unit", selection: $unit) {
                    Text("kg").tag("kg")
                    Text("lbs").tag("lbs")
                    Text("bodyweight").tag("bodyweight")
                }
            }

            Section("Equipment") {
                ForEach(Equipment.allCases, id: \.self) { item in
                    Toggle(item.rawValue.capitalized, isOn: Binding(
                        get: { selectedEquipment.contains(item) },
                        set: { on in
                            if on { selectedEquipment.insert(item) }
                            else { selectedEquipment.remove(item) }
                        }
                    ))
                }
            }

            Section {
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            if existingExercise != nil {
                Section {
                    Button("Delete Exercise", role: .destructive) {
                        Task {
                            if let id = existingExercise?.id {
                                try? await workoutStore.deleteExercise(id: id)
                            }
                            dismiss()
                        }
                    }
                }
            }
        }
        .navigationTitle(isNew ? "New Exercise" : "Edit Exercise")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
                    .disabled(name.isEmpty || isSaving)
            }
        }
        .onAppear {
            if let e = existingExercise {
                name = e.name
                primaryMuscle = e.primaryMuscle ?? ""
                unit = e.unit
                notes = e.notes ?? ""
                selectedEquipment = e.equipment
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let exercise = Exercise(
            id: existingExercise?.id ?? UUID().uuidString,
            name: name,
            primaryMuscle: primaryMuscle.isEmpty ? nil : primaryMuscle,
            unit: unit,
            notes: notes.isEmpty ? nil : notes,
            equipment: selectedEquipment
        )
        if isNew {
            try? await workoutStore.insertExercise(exercise)
        } else {
            try? await workoutStore.updateExercise(exercise)
        }
        dismiss()
    }

    private let muscleGroups = [
        "chest", "back", "shoulders", "biceps", "triceps",
        "quadriceps", "hamstrings", "glutes", "calves",
        "abs", "forearms", "traps",
    ]
}
