import SwiftUI
import WellnessModels
import WellnessStores

public struct ProfileSettingsScreen: View {
    @Environment(ProfileFeatureStore.self) private var profileStore

    public init() {}

    public var body: some View {
        Form {
            if let profile = profileStore.profile {
                Section("Physical") {
                    LabeledContent("Sex", value: profile.sex.capitalized)
                    LabeledContent("Age", value: "\(profile.ageYears) years")
                    LabeledContent("Height", value: "\(profile.heightCm) cm")
                    LabeledContent("Weight", value: String(format: "%.1f kg", profile.weightKg))
                }

                Section("Training") {
                    LabeledContent("Goal", value: profile.goal.replacingOccurrences(of: "_", with: " ").capitalized)
                    LabeledContent("Activity", value: profile.activityLevel.capitalized)
                    LabeledContent("Days/week", value: "\(profile.trainingDaysPerWeek)")
                    LabeledContent("Experience", value: profile.trainingExperience.capitalized)
                }

                Section("Nutrition Targets") {
                    LabeledContent("Calories", value: "\(profile.calorieTarget) kcal")
                    LabeledContent("Protein", value: "\(profile.proteinTargetG)g")
                    LabeledContent("Fat", value: "\(profile.fatTargetG)g")
                    LabeledContent("Carbs", value: "\(profile.carbsTargetG)g")
                }

                Section("Diet") {
                    LabeledContent("Type", value: profile.dietType.capitalized)
                    LabeledContent("Meals/day", value: profile.mealCountPerDay)
                }

                if !profile.equipment.isEmpty {
                    Section("Equipment") {
                        ForEach(profile.equipment, id: \.self) { item in
                            Text(item.replacingOccurrences(of: "_", with: " ").capitalized)
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Profile",
                    systemImage: "person.crop.circle.badge.questionmark",
                    description: Text("Complete onboarding to set up your profile.")
                )
            }
        }
        .navigationTitle("Profile")
    }
}
