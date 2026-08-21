import SwiftUI
import WellnessUI

@Observable
final class AppRouter {
    var selectedTab: AppTab = .dashboard
    var dashboardPath: [AppRoute] = []
    var mealsPath: [AppRoute] = []
    var workoutsPath: [AppRoute] = []
    var sleepPath: [AppRoute] = []
    var calendarPath: [AppRoute] = []

    func navigate(to route: AppRoute, in tab: AppTab) {
        selectedTab = tab
        switch tab {
        case .dashboard: dashboardPath.append(route)
        case .meals: mealsPath.append(route)
        case .workouts: workoutsPath.append(route)
        case .sleep: sleepPath.append(route)
        case .calendar: calendarPath.append(route)
        }
    }

    func popToRoot(tab: AppTab) {
        switch tab {
        case .dashboard: dashboardPath.removeAll()
        case .meals: mealsPath.removeAll()
        case .workouts: workoutsPath.removeAll()
        case .sleep: sleepPath.removeAll()
        case .calendar: calendarPath.removeAll()
        }
    }
}
