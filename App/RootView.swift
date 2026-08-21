import SwiftUI
import WellnessUI
import WellnessStores

struct RootView: View {
    @Environment(ProfileFeatureStore.self) private var profileStore

    var body: some View {
        if profileStore.hasProfile {
            AppShell()
        } else {
            NavigationStack {
                OnboardingScreen()
            }
        }
    }
}
