import Foundation
import Observation
import WellnessModels
import WellnessPersistence

@MainActor @Observable
public final class CalendarFeatureStore {
    public private(set) var events: [ScheduledEvent] = []
    public private(set) var isLoading = false

    private let store: any ScheduledEventStore

    public init(store: any ScheduledEventStore) {
        self.store = store
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            events = try await store.allScheduledEvents()
        } catch {}
    }

    public func eventsForDate(_ date: Date) -> [ScheduledEvent] {
        let cal = Calendar.current
        return events.filter { cal.isDate($0.scheduledAt, inSameDayAs: date) }
    }

    public func addEvent(_ event: ScheduledEvent) async throws {
        try await store.insertScheduledEvent(event)
        await load()
    }

    public func updateEvent(_ event: ScheduledEvent) async throws {
        try await store.updateScheduledEvent(event)
        await load()
    }

    public func deleteEvent(id: String) async throws {
        try await store.deleteScheduledEvent(id: id)
        await load()
    }

    public func completeEvent(_ id: String) async throws {
        guard var event = try await store.scheduledEvent(byId: id) else { return }
        event.completedAt = .now
        event.status = .completed
        try await store.updateScheduledEvent(event)
        await load()
    }
}
