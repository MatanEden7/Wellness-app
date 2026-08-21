import Foundation
import Observation
import WellnessModels
import WellnessPersistence
import WellnessDomain

@MainActor @Observable
public final class WorkoutFeatureStore {
    public private(set) var templates: [WorkoutTemplate] = []
    public private(set) var recentSessions: [WorkoutSession] = []
    public private(set) var activeSession: WorkoutSession?
    public private(set) var allExercises: [Exercise] = []
    public private(set) var isLoading = false

    private let templateStore: any WorkoutTemplateStore
    private let sessionStore: any WorkoutSessionStore
    private let exerciseStore: any ExerciseStore

    public init(
        templateStore: any WorkoutTemplateStore,
        sessionStore: any WorkoutSessionStore,
        exerciseStore: any ExerciseStore
    ) {
        self.templateStore = templateStore
        self.sessionStore = sessionStore
        self.exerciseStore = exerciseStore
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            templates = try await templateStore.allWorkoutTemplates()
            recentSessions = try await sessionStore.recentWorkoutSessions(limit: 20)
            activeSession = recentSessions.first { $0.endedAt == nil }
        } catch {}
    }

    public func loadExercises() async {
        allExercises = (try? await exerciseStore.allExercises()) ?? []
    }

    // MARK: - Sessions

    public func startSession(templateId: String?) async throws -> WorkoutSession {
        let session = WorkoutSession(id: UUID().uuidString, templateId: templateId)
        try await sessionStore.insertWorkoutSession(session)
        activeSession = session
        await load()
        return session
    }

    public func endSession(_ id: String) async throws {
        guard var session = try await sessionStore.workoutSession(byId: id) else { return }
        session.endedAt = .now
        try await sessionStore.updateWorkoutSession(session)
        activeSession = nil
        await load()
    }

    public func deleteSession(id: String) async throws {
        try await sessionStore.deleteWorkoutSession(id: id)
        if activeSession?.id == id { activeSession = nil }
        await load()
    }

    public func addSet(_ entry: SetEntry) async throws {
        try await sessionStore.insertSetEntry(entry)
        await reloadActiveSession()
    }

    public func updateSet(_ entry: SetEntry) async throws {
        try await sessionStore.updateSetEntry(entry)
        await reloadActiveSession()
    }

    public func deleteSet(id: String) async throws {
        try await sessionStore.deleteSetEntry(id: id)
        await reloadActiveSession()
    }

    public func session(byId id: String) async -> WorkoutSession? {
        try? await sessionStore.workoutSession(byId: id)
    }

    private func reloadActiveSession() async {
        if let id = activeSession?.id {
            activeSession = try? await sessionStore.workoutSession(byId: id)
        }
        await load()
    }

    // MARK: - Templates

    public func insertTemplate(_ template: WorkoutTemplate) async throws {
        try await templateStore.insertWorkoutTemplate(template)
        for ex in template.exercises {
            try await templateStore.insertTemplateExercise(ex)
        }
        await load()
    }

    public func updateTemplate(_ template: WorkoutTemplate) async throws {
        try await templateStore.updateWorkoutTemplate(template)
        await load()
    }

    public func deleteTemplate(id: String) async throws {
        try await templateStore.deleteWorkoutTemplate(id: id)
        await load()
    }

    // MARK: - Exercises

    public func exercise(byId id: String) -> Exercise? {
        allExercises.first { $0.id == id }
    }

    public func insertExercise(_ exercise: Exercise) async throws {
        try await exerciseStore.insertExercise(exercise)
        await loadExercises()
    }

    public func updateExercise(_ exercise: Exercise) async throws {
        try await exerciseStore.updateExercise(exercise)
        await loadExercises()
    }

    public func deleteExercise(id: String) async throws {
        try await exerciseStore.deleteExercise(id: id)
        await loadExercises()
    }

    @available(*, deprecated, renamed: "allExercises")
    public func exercises() async throws -> [Exercise] {
        try await exerciseStore.allExercises()
    }
}
