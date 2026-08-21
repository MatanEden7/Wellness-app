import SwiftUI
import SwiftData
import WellnessModels
import WellnessPersistence
import WellnessServices
import WellnessStores
import WellnessUI

@main
struct WellnessApp: App {
    private let container: ModelContainer
    private let stores: AppStores

    init() {
        let container = try! WellnessContainer.create()
        self.container = container
        self.stores = AppStores(container: container)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(stores.profile)
                .environment(stores.meals)
                .environment(stores.workouts)
                .environment(stores.sleep)
                .environment(stores.calendar)
                .environment(stores.analytics)
                .task { await stores.loadAll() }
        }
        .modelContainer(container)
    }
}

@MainActor
struct AppStores {
    let profile: ProfileFeatureStore
    let meals: MealFeatureStore
    let workouts: WorkoutFeatureStore
    let sleep: SleepFeatureStore
    let calendar: CalendarFeatureStore
    let analytics: AnalyticsFeatureStore

    init(container: ModelContainer) {
        let store = SwiftDataStore(modelContainer: container)

        profile = ProfileFeatureStore(store: store)
        meals = MealFeatureStore(store: store, foodStore: store)
        workouts = WorkoutFeatureStore(
            templateStore: store, sessionStore: store, exerciseStore: store
        )
        sleep = SleepFeatureStore(store: store)
        calendar = CalendarFeatureStore(store: store)
        analytics = AnalyticsFeatureStore(
            mealStore: store, sessionStore: store,
            sleepStore: store, bodyWeightStore: store
        )
    }

    func loadAll() async {
        await profile.load()
        await meals.load()
        await workouts.load()
        await sleep.load()
        await calendar.load()
    }
}
