import SwiftUI
import WellnessModels

public enum AppRoute: Hashable {
    case dashboard
    case meals
    case mealEdit(id: String?)
    case mealFoods
    case mealTemplates
    case mealTemplateEdit(id: String?)
    case workouts
    case workoutExercises
    case workoutSession(id: String)
    case workoutTemplates
    case workoutTemplateEdit(id: String?)
    case sleep
    case calendar
    case calendarSchedule
    case analytics
    case settings
    case settingsProfile
    case settingsNotifications
    case settingsBackup
    case settingsLanguage
    case settingsAppearance
    case settingsAbout
    case onboarding
}

public enum AppTab: String, CaseIterable, Identifiable {
    case dashboard, meals, workouts, sleep, calendar

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .meals: "Meals"
        case .workouts: "Workouts"
        case .sleep: "Sleep"
        case .calendar: "Calendar"
        }
    }

    public var icon: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .meals: "fork.knife"
        case .workouts: "dumbbell"
        case .sleep: "moon.zzz"
        case .calendar: "calendar"
        }
    }
}
