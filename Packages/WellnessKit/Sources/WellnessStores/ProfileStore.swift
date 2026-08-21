import Foundation
import Observation
import WellnessModels
import WellnessPersistence

@MainActor @Observable
public final class ProfileFeatureStore {
    public private(set) var profile: UserProfile?
    public private(set) var isLoading = false

    private let store: any UserProfileStore

    public init(store: any UserProfileStore) {
        self.store = store
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            profile = try await store.profile()
        } catch {}
    }

    public func save(_ profile: UserProfile) async throws {
        try await store.saveProfile(profile)
        self.profile = profile
    }

    public func delete() async throws {
        try await store.deleteProfile()
        profile = nil
    }

    public var hasProfile: Bool { profile != nil }
}
