import SwiftUI
import WellnessModels

public struct NotificationSettingsScreen: View {
    @State private var mealReminders = true
    @State private var workoutReminders = true
    @State private var sleepReminders = true
    @State private var reminderTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now) ?? .now
    @State private var quietHoursEnabled = false
    @State private var quietStart = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: .now) ?? .now
    @State private var quietEnd = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: .now) ?? .now

    public init() {}

    public var body: some View {
        Form {
            Section("Reminders") {
                Toggle("Meal Reminders", isOn: $mealReminders)
                Toggle("Workout Reminders", isOn: $workoutReminders)
                Toggle("Sleep Reminders", isOn: $sleepReminders)
            }

            Section("Timing") {
                DatePicker("Default Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
            }

            Section("Quiet Hours") {
                Toggle("Enable Quiet Hours", isOn: $quietHoursEnabled)
                if quietHoursEnabled {
                    DatePicker("Start", selection: $quietStart, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $quietEnd, displayedComponents: .hourAndMinute)
                }
            }
        }
        .navigationTitle("Notifications")
    }
}
