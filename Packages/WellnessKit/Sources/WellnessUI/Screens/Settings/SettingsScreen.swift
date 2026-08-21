import SwiftUI
import WellnessModels
import WellnessStores

public struct SettingsScreen: View {
    @Environment(ProfileFeatureStore.self) private var profileStore

    public init() {}

    public var body: some View {
        Form {
            Section {
                NavigationLink(value: AppRoute.settingsProfile) {
                    Label("Profile", systemImage: "person")
                }
                NavigationLink(value: AppRoute.settingsNotifications) {
                    Label("Notifications", systemImage: "bell")
                }
            }

            Section {
                NavigationLink(value: AppRoute.settingsAppearance) {
                    Label("Appearance", systemImage: "paintbrush")
                }
                NavigationLink(value: AppRoute.settingsLanguage) {
                    Label("Language", systemImage: "globe")
                }
            }

            Section {
                NavigationLink(value: AppRoute.settingsBackup) {
                    Label("Backup & Restore", systemImage: "arrow.up.doc")
                }
            }

            Section {
                NavigationLink(value: AppRoute.settingsAbout) {
                    Label("About", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Settings")
    }
}
