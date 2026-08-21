import SwiftUI
import WellnessModels
import WellnessStores
import WellnessDomain

public struct ProfileSettingsScreen: View {
    @Environment(ProfileFeatureStore.self) private var profileStore
    @Environment(\.dismiss) private var dismiss

    @State private var sex = "male"
    @State private var ageYears = 25
    @State private var heightCm = 175
    @State private var weightKg: Double = 75.0
    @State private var goal = "maintenance"
    @State private var activityLevel = "moderate"
    @State private var trainingDays = 3
    @State private var experience = "beginner"
    @State private var dietType = "omnivore"
    @State private var mealCount = "3"
    @State private var isSaving = false
    @State private var showDeleteConfirm = false

    public init() {}

    public var body: some View {
        Form {
            Section("Physical") {
                Picker("Sex", selection: $sex) {
                    Text("Male").tag("male")
                    Text("Female").tag("female")
                }
                Stepper("Age: \(ageYears)", value: $ageYears, in: 13...100)
                Stepper("Height: \(heightCm) cm", value: $heightCm, in: 100...250)
                HStack {
                    Text("Weight")
                    Spacer()
                    TextField("kg", value: $weightKg, format: .number)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Text("kg").foregroundStyle(.secondary)
                }
            }

            Section("Goals & Training") {
                Picker("Goal", selection: $goal) {
                    Text("Fat Loss").tag("fat_loss")
                    Text("Muscle Gain").tag("muscle_gain")
                    Text("Maintenance").tag("maintenance")
                    Text("Rehab").tag("mobility_rehab")
                }
                Picker("Activity", selection: $activityLevel) {
                    Text("Sedentary").tag("sedentary")
                    Text("Light").tag("light")
                    Text("Moderate").tag("moderate")
                    Text("Active").tag("active")
                    Text("Very Active").tag("very_active")
                }
                Stepper("Days/week: \(trainingDays)", value: $trainingDays, in: 1...7)
                Picker("Experience", selection: $experience) {
                    Text("Beginner").tag("beginner")
                    Text("Intermediate").tag("intermediate")
                    Text("Advanced").tag("advanced")
                }
            }

            Section("Diet") {
                Picker("Diet Type", selection: $dietType) {
                    Text("Omnivore").tag("omnivore")
                    Text("Vegetarian").tag("vegetarian")
                    Text("Vegan").tag("vegan")
                    Text("Pescatarian").tag("pescatarian")
                    Text("Keto").tag("keto")
                    Text("Paleo").tag("paleo")
                }
                Picker("Meals/Day", selection: $mealCount) {
                    Text("2 meals").tag("2")
                    Text("3 meals").tag("3")
                    Text("4 meals").tag("4")
                    Text("IF 16:8").tag("intermittent_fasting_16_8")
                }
            }

            let targets = SetupEngine.calculateTargets(
                sex: sex, weightKg: weightKg, heightCm: heightCm,
                ageYears: ageYears, goal: goal, activityLevel: activityLevel
            )
            Section("Computed Targets (preview)") {
                LabeledContent("BMR", value: "\(Int(targets.bmr)) kcal")
                LabeledContent("TDEE", value: "\(Int(targets.tdee)) kcal")
                LabeledContent("Calorie Target", value: "\(Int(targets.calorieTarget)) kcal")
                LabeledContent("Protein", value: "\(Int(targets.proteinG))g")
                LabeledContent("Fat", value: "\(Int(targets.fatG))g")
                LabeledContent("Carbs", value: "\(Int(targets.carbsG))g")
            }

            Section {
                Button("Delete Profile", role: .destructive) {
                    showDeleteConfirm = true
                }
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
                    .disabled(isSaving)
            }
        }
        .confirmationDialog("Delete Profile?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await profileStore.delete()
                    dismiss()
                }
            }
        } message: {
            Text("This will reset all profile data and return to onboarding.")
        }
        .onAppear {
            if let p = profileStore.profile {
                sex = p.sex
                ageYears = p.ageYears
                heightCm = p.heightCm
                weightKg = p.weightKg
                goal = p.goal
                activityLevel = p.activityLevel
                trainingDays = p.trainingDaysPerWeek
                experience = p.trainingExperience
                dietType = p.dietType
                mealCount = p.mealCountPerDay
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        guard let existing = profileStore.profile else { return }
        let profile = SetupEngine.createUserProfile(
            sex: sex, ageYears: ageYears, heightCm: heightCm, weightKg: weightKg,
            goal: goal, activityLevel: activityLevel,
            trainingDaysPerWeek: trainingDays, trainingExperience: experience,
            equipment: existing.equipment, dietType: dietType,
            mealCountPerDay: mealCount, exclusions: existing.exclusions,
            injuries: existing.injuries
        )
        try? await profileStore.save(profile)
        dismiss()
    }
}
