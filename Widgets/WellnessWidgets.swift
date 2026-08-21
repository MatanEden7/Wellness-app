import WidgetKit
import SwiftUI
import WellnessModels
import WellnessServices

@main
struct WellnessWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        NextUpWidget()
        WeekWidget()
        StreakWidget()
        LockScreenCalorieWidget()
        LockScreenNextEventWidget()
        LockScreenStreakWidget()
        WorkoutLiveActivity()
        SleepLiveActivity()
    }
}
