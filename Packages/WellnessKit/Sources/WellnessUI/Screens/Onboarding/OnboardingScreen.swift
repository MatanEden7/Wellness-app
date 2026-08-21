import SwiftUI
import WellnessModels
import WellnessStores
import WellnessDomain

public struct OnboardingScreen: View {
    @Environment(ProfileFeatureStore.self) private var profileStore
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var sex = "male"
    @State private var ageYears = 25
    @State private var heightCm = 175
    @State private var weightKg = 75.0
    @State private var goal = "maintenance"
    @State private var activityLevel = "moderate"
    @State private var trainingDays = 3
    @State private var experience = "beginner"
    @State private var dietType = "omnivore"
    @State private var mealCount = "3"
    @State private var isSaving = false

    private let totalSteps = 4

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(step + 1), total: Double(totalSteps))
                .padding(.horizontal)
                .padding(.top, 8)

            Group {
                switch step {
                case 0: physicalStep
                case 1: goalStep
                case 2: trainingStep
                default: dietStep
                }
            }
            .animation(.default, value: step)

            HStack {
                if step > 0 {
                    Button("Back") { step -= 1 }
                        .buttonStyle(.bordered)
                }
                Spacer()
                if step < totalSteps - 1 {
                    Button("Next") { step += 1 }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Finish") { Task { await save() } }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSaving)
                }
            }
            .padding()
        }
        .navigationTitle("Welcome")
        .interactiveDismissDisabled()
    }

    private var physicalStep: some View {
        Form {
            Section("About You") {
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
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Text("kg")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var goalStep: some View {
        Form {
            Section("Your Goal") {
                Picker("Goal", selection: $goal) {
                    Text("Fat Loss").tag("fat_loss")
                    Text("Muscle Gain").tag("muscle_gain")
                    Text("Maintenance").tag("maintenance")
                    Text("Rehab").tag("mobility_rehab")
                }
                .pickerStyle(.inline)
            }
            Section("Activity Level") {
                Picker("Activity", selection: $activityLevel) {
                    Text("Sedentary").tag("sedentary")
                    Text("Light").tag("light")
                    Text("Moderate").tag("moderate")
                    Text("Active").tag("active")
                    Text("Very Active").tag("very_active")
                }
                .pickerStyle(.inline)
            }
        }
    }

    private var trainingStep: some View {
        Form {
            Section("Training") {
                Stepper("Days per week: \(trainingDays)", value: $trainingDays, in: 1...7)
                Picker("Experience", selection: $experience) {
                    Text("Beginner").tag("beginner")
                    Text("Intermediate").tag("intermediate")
                    Text("Advanced").tag("advanced")
                }
            }
        }
    }

    private var dietStep: some View {
        Form {
            Section("Diet") {
                Picker("Diet Type", selection: $dietType) {
                    Text("Omnivore").tag("omnivore")
                    Text("Vegetarian").tag("vegetarian")
                    Text("Vegan").tag("vegan")
                    Text("Pescatarian").tag("pescatarian")
                }
                Picker("Meals per Day", selection: $mealCount) {
                    Text("2 meals").tag("2")
                    Text("3 meals").tag("3")
                    Text("4 meals").tag("4")
                    Text("IF 16:8").tag("intermittent_fasting_16_8")
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let profile = SetupEngine.createUserProfile(
            sex: sex,
            ageYears: ageYears,
            heightCm: heightCm,
            weightKg: weightKg,
            goal: goal,
            activityLevel: activityLevel,
            trainingDaysPerWeek: trainingDays,
            trainingExperience: experience,
            dietType: dietType,
            mealCountPerDay: mealCount
        )
        try? await profileStore.save(profile)
        dismiss()
    }
}
