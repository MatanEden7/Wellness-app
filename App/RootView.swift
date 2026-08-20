import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "house") {
                Text("Dashboard")
            }
            Tab("Meals", systemImage: "fork.knife") {
                Text("Meals")
            }
            Tab("Workouts", systemImage: "dumbbell") {
                Text("Workouts")
            }
            Tab("Sleep", systemImage: "bed.double") {
                Text("Sleep")
            }
            Tab("Settings", systemImage: "gearshape") {
                Text("Settings")
            }
        }
    }
}
