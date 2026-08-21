import Foundation
import Observation
import WellnessModels
import WellnessPersistence

@MainActor @Observable
public final class SleepFeatureStore {
    public private(set) var recentEntries: [SleepEntry] = []
    public private(set) var activeSleep: SleepEntry?
    public private(set) var isLoading = false

    private let store: any SleepStore

    public init(store: any SleepStore) {
        self.store = store
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            recentEntries = try await store.recentSleepEntries(limit: 30)
            activeSleep = recentEntries.first { $0.endedAt == nil }
        } catch {}
    }

    public func startSleep() async throws -> SleepEntry {
        let entry = SleepEntry(id: UUID().uuidString, startedAt: .now)
        try await store.insertSleepEntry(entry)
        activeSleep = entry
        await load()
        return entry
    }

    public func stopSleep(_ id: String) async throws {
        guard var entry = try await store.sleepEntry(byId: id) else { return }
        entry.endedAt = .now
        try await store.updateSleepEntry(entry)
        activeSleep = nil
        await load()
    }

    public func updateSleep(_ entry: SleepEntry) async throws {
        try await store.updateSleepEntry(entry)
        await load()
    }

    public func insertSleep(_ entry: SleepEntry) async throws {
        try await store.insertSleepEntry(entry)
        await load()
    }

    public func deleteSleep(id: String) async throws {
        try await store.deleteSleepEntry(id: id)
        await load()
    }

    public func sleep(byId id: String) async -> SleepEntry? {
        try? await store.sleepEntry(byId: id)
    }

    public var lastNightHours: Double? {
        recentEntries.first { $0.endedAt != nil }?.durationInHours
    }

    public var weekAvgHours: Double? {
        let completed = recentEntries.filter { $0.endedAt != nil }.prefix(7)
        guard !completed.isEmpty else { return nil }
        let total = completed.compactMap(\.durationInHours).reduce(0, +)
        return total / Double(completed.count)
    }
}
