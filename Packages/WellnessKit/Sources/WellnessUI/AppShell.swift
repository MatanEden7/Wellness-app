import SwiftUI
import WellnessModels

public struct AppShell: View {
    @State private var selectedTab: AppTab = .dashboard

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.dashboard.title, systemImage: AppTab.dashboard.icon, value: .dashboard) {
                DashboardTab()
            }
            Tab(AppTab.meals.title, systemImage: AppTab.meals.icon, value: .meals) {
                MealsTab()
            }
            Tab(AppTab.workouts.title, systemImage: AppTab.workouts.icon, value: .workouts) {
                WorkoutsTab()
            }
            Tab(AppTab.sleep.title, systemImage: AppTab.sleep.icon, value: .sleep) {
                SleepTab()
            }
            Tab(AppTab.calendar.title, systemImage: AppTab.calendar.icon, value: .calendar) {
                CalendarTab()
            }
        }
        .tabViewStyle(.tabBarOnly)
    }
}

// MARK: - Tab shells

struct DashboardTab: View {
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            DashboardScreen()
                .navigationTitle("Dashboard")
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        NavigationLink(value: AppRoute.settings) {
                            Image(systemName: "gearshape")
                        }
                    }
                    ToolbarItem(placement: .automatic) {
                        NavigationLink(value: AppRoute.analytics) {
                            Image(systemName: "chart.bar")
                        }
                    }
                }
                .navigationDestination(for: AppRoute.self) { route in
                    routeView(route)
                }
        }
    }
}

struct MealsTab: View {
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            MealsScreen()
                .navigationDestination(for: AppRoute.self) { route in
                    routeView(route)
                }
        }
    }
}

struct WorkoutsTab: View {
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            WorkoutsScreen()
                .navigationDestination(for: AppRoute.self) { route in
                    routeView(route)
                }
        }
    }
}

struct SleepTab: View {
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            SleepScreen()
                .navigationDestination(for: AppRoute.self) { route in
                    routeView(route)
                }
        }
    }
}

struct CalendarTab: View {
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            CalendarScreen()
                .navigationDestination(for: AppRoute.self) { route in
                    routeView(route)
                }
        }
    }
}

// MARK: - Route resolution

@MainActor @ViewBuilder
func routeView(_ route: AppRoute) -> some View {
    switch route {
    case .dashboard:
        DashboardScreen()
    case .meals:
        MealsScreen()
    case .mealEdit(let id):
        MealEditorScreen(mealId: id)
    case .mealFoods:
        FoodCatalogScreen()
    case .mealTemplates:
        MealTemplatesScreen()
    case .mealTemplateEdit(let id):
        MealTemplateEditorScreen(templateId: id)
    case .workouts:
        WorkoutsScreen()
    case .workoutExercises:
        ExerciseLibraryScreen()
    case .workoutSession(let id):
        WorkoutSessionScreen(sessionId: id)
    case .workoutTemplates:
        WorkoutsScreen()
    case .workoutTemplateEdit(let id):
        WorkoutTemplateEditorScreen(templateId: id)
    case .sleep:
        SleepScreen()
    case .calendar:
        CalendarScreen()
    case .calendarSchedule:
        CalendarScreen()
    case .analytics:
        AnalyticsScreen()
    case .settings:
        SettingsScreen()
    case .settingsProfile:
        ProfileSettingsScreen()
    case .settingsNotifications:
        NotificationSettingsScreen()
    case .settingsBackup:
        BackupSettingsScreen()
    case .settingsLanguage:
        LanguageSettingsScreen()
    case .settingsAppearance:
        AppearanceSettingsScreen()
    case .settingsAbout:
        AboutScreen()
    case .onboarding:
        OnboardingScreen()
    }
}

// MARK: - Placeholder

struct PlaceholderScreen: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
