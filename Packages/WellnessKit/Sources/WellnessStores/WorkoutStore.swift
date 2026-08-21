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

    public func addSet(_ entry: SetEntry) async throws {
        try await sessionStore.insertSetEntry(entry)
        await load()
    }

    public func exercises() async throws -> [Exercise] {
        try await exerciseStore.allExercises()
    }
}
