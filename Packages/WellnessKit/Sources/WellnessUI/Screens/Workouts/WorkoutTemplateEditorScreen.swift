import SwiftUI
import WellnessModels
import WellnessStores

public struct WorkoutTemplateEditorScreen: View {
    @Environment(WorkoutFeatureStore.self) private var workoutStore
    @Environment(\.dismiss) private var dismiss

    let editingTemplateId: String?

    @State private var name = ""
    @State private var notes = ""
    @State private var exercises: [TemplateExercise] = []
    @State private var showExercisePicker = false
    @State private var isSaving = false

    private var isNew: Bool { editingTemplateId == nil }

    public init(templateId: String? = nil) {
        self.editingTemplateId = templateId
    }

    public var body: some View {
        Form {
            Section {
                TextField("Template Name", text: $name)
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("Exercises") {
                if exercises.isEmpty {
                    Text("No exercises added")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(exercises) { te in
                        templateExerciseRow(te)
                    }
                    .onDelete { indices in
                        exercises.remove(atOffsets: indices)
                    }
                    .onMove { from, to in
                        exercises.move(fromOffsets: from, toOffset: to)
                        reindex()
                    }
                }
                Button {
                    showExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle(isNew ? "New Template" : "Edit Template")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
                    .disabled(name.isEmpty || isSaving)
            }
            #if os(iOS)
            if !exercises.isEmpty {
                ToolbarItem(placement: .automatic) {
                    EditButton()
                }
            }
            #endif
        }
        .sheet(isPresented: $showExercisePicker) {
            NavigationStack {
                TemplateExerciseAdder(templateId: editingTemplateId ?? "") { te in
                    exercises.append(te)
                    reindex()
                }
            }
        }
        .task {
            await workoutStore.loadExercises()
            if let id = editingTemplateId,
               let template = workoutStore.templates.first(where: { $0.id == id }) {
                name = template.name
                notes = template.notes ?? ""
                exercises = template.exercises.sorted { $0.orderIndex < $1.orderIndex }
            }
        }
    }

    @ViewBuilder
    private func templateExerciseRow(_ te: TemplateExercise) -> some View {
        let exerciseName = workoutStore.exercise(byId: te.exerciseId)?.name ?? "Exercise"
        VStack(alignment: .leading, spacing: 4) {
            Text(exerciseName)
                .font(.body)
            HStack(spacing: 12) {
                Text("\(te.defaultSets) sets")
                if let reps = te.defaultReps { Text("\(reps) reps") }
                if let weight = te.defaultWeight { Text("\(String(format: "%.1f", weight)) kg") }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func reindex() {
        for i in exercises.indices {
            exercises[i].orderIndex = i
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let templateId = editingTemplateId ?? UUID().uuidString
        let updatedExercises = exercises.map { ex in
            var copy = ex
            copy.templateId = templateId
            return copy
        }
        let template = WorkoutTemplate(
            id: templateId, name: name,
            notes: notes.isEmpty ? nil : notes,
            origin: .user,
            exercises: updatedExercises
        )
        if isNew {
            try? await workoutStore.insertTemplate(template)
        } else {
            try? await workoutStore.updateTemplate(template)
        }
        dismiss()
    }
}

private struct TemplateExerciseAdder: View {
    @Environment(WorkoutFeatureStore.self) private var workoutStore
    @Environment(\.dismiss) private var dismiss

    let templateId: String
    let onAdd: (TemplateExercise) -> Void

    @State private var searchText = ""
    @State private var selectedExercise: Exercise?
    @State private var sets = 3
    @State private var reps = 10
    @State private var weight: Double = 0
    @State private var restSeconds = 90

    var body: some View {
        Group {
            if let exercise = selectedExercise {
                prescriptionForm(exercise)
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
    private func prescriptionForm(_ exercise: Exercise) -> some View {
        Form {
            Section {
                Text(exercise.name).font(.headline)
            }
            Section("Defaults") {
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
                Stepper("Rest: \(restSeconds)s", value: $restSeconds, in: 30...300, step: 15)
            }
            Section {
                Button("Add") {
                    let te = TemplateExercise(
                        id: UUID().uuidString,
                        templateId: templateId,
                        exerciseId: exercise.id,
                        orderIndex: 0,
                        defaultSets: sets,
                        defaultReps: reps,
                        defaultWeight: weight > 0 ? weight : nil,
                        defaultRestSeconds: restSeconds
                    )
                    onAdd(te)
                    dismiss()
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

    private var filteredExercises: [Exercise] {
        guard !searchText.isEmpty else { return workoutStore.allExercises }
        let query = searchText.lowercased()
        return workoutStore.allExercises.filter { $0.name.lowercased().contains(query) }
    }
}
