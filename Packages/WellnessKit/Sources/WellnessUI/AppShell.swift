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
        PlaceholderScreen(title: id == nil ? "New Meal" : "Edit Meal", icon: "fork.knife")
    case .mealFoods:
        PlaceholderScreen(title: "Foods", icon: "list.bullet")
    case .mealTemplates:
        PlaceholderScreen(title: "Meal Templates", icon: "doc.text")
    case .mealTemplateEdit(let id):
        PlaceholderScreen(title: id == nil ? "New Template" : "Edit Template", icon: "doc.text")
    case .workouts:
        WorkoutsScreen()
    case .workoutExercises:
        PlaceholderScreen(title: "Exercises", icon: "figure.strengthtraining.traditional")
    case .workoutSession(let id):
        PlaceholderScreen(title: "Session \(id.prefix(6))", icon: "timer")
    case .workoutTemplates:
        PlaceholderScreen(title: "Templates", icon: "doc.text")
    case .workoutTemplateEdit(let id):
        PlaceholderScreen(title: id == nil ? "New Template" : "Edit Template", icon: "doc.text")
    case .sleep:
        SleepScreen()
    case .calendar:
        CalendarScreen()
    case .calendarSchedule:
        PlaceholderScreen(title: "Schedule Event", icon: "calendar.badge.plus")
    case .analytics:
        AnalyticsScreen()
    case .settings:
        SettingsScreen()
    case .settingsProfile:
        ProfileSettingsScreen()
    case .settingsNotifications:
        PlaceholderScreen(title: "Notifications", icon: "bell")
    case .settingsBackup:
        PlaceholderScreen(title: "Backup", icon: "arrow.up.doc")
    case .settingsLanguage:
        PlaceholderScreen(title: "Language", icon: "globe")
    case .settingsAppearance:
        PlaceholderScreen(title: "Appearance", icon: "paintbrush")
    case .settingsAbout:
        PlaceholderScreen(title: "About", icon: "info.circle")
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
