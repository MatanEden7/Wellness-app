import SwiftUI
import WellnessModels
import WellnessStores
import WellnessDomain

public struct OnboardingScreen: View {
    @Environment(ProfileFeatureStore.self) private var profileStore
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var language: AppLanguage = .english
    @State private var sex = "male"
    @State private var ageYears = 25
    @State private var heightCm = 175
    @State private var weightKg = 75.0
    @State private var goal = "maintenance"
    @State private var activityLevel = "moderate"
    @State private var trainingDays = 3
    @State private var experience = "beginner"
    @State private var selectedEquipment: Set<Equipment> = []
    @State private var dietType = "omnivore"
    @State private var mealCount = "3"
    @State private var exclusions: Set<String> = []
    @State private var injuries: Set<BodyPart> = []
    @State private var generateSchedule = true
    @State private var isSaving = false

    private let totalSteps = 7

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(step + 1), total: Double(totalSteps))
                .padding(.horizontal)
                .padding(.top, 8)

            Group {
                switch step {
                case 0: languageStep
                case 1: physicalStep
                case 2: goalStep
                case 3: equipmentStep
                case 4: dietStep
                case 5: injuryStep
                default: summaryStep
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
                    Button("Complete Setup") { Task { await save() } }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSaving)
                }
            }
            .padding()
        }
        .navigationTitle("Welcome")
        .interactiveDismissDisabled()
    }

    // MARK: - Step 0: Language

    private var languageStep: some View {
        Form {
            Section("Choose Your Language") {
                Picker("Language", selection: $language) {
                    Text("English").tag(AppLanguage.english)
                    Text("עברית (Hebrew)").tag(AppLanguage.hebrew)
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
        }
    }

    // MARK: - Step 1: Physical

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
                        .multilineTextAlignment(.trailing)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    Text("kg")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Step 2: Goals + Training

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

    // MARK: - Step 3: Equipment

    private var equipmentStep: some View {
        Form {
            Section("Available Equipment") {
                Text("Select all equipment you have access to.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(Equipment.allCases, id: \.self) { item in
                    Toggle(equipmentLabel(item), isOn: Binding(
                        get: { selectedEquipment.contains(item) },
                        set: { on in
                            if on { selectedEquipment.insert(item) }
                            else { selectedEquipment.remove(item) }
                        }
                    ))
                }
            }
        }
    }

    private func equipmentLabel(_ e: Equipment) -> String {
        switch e {
        case .bodyweight:  "Bodyweight Only"
        case .dumbbells:   "Dumbbells"
        case .barbellRack: "Barbell & Rack"
        case .machines:    "Machines"
        case .bands:       "Resistance Bands"
        case .kettlebells: "Kettlebells"
        case .cable:       "Cable Machine"
        case .pullupBar:   "Pull-up Bar"
        }
    }

    // MARK: - Step 4: Diet

    private var dietStep: some View {
        Form {
            Section("Diet Type") {
                Picker("Diet", selection: $dietType) {
                    Text("Omnivore").tag("omnivore")
                    Text("Vegetarian").tag("vegetarian")
                    Text("Vegan").tag("vegan")
                    Text("Pescatarian").tag("pescatarian")
                    Text("Keto").tag("keto")
                    Text("Paleo").tag("paleo")
                }
                .pickerStyle(.inline)
            }
            Section("Meals Per Day") {
                Picker("Meals", selection: $mealCount) {
                    Text("2 meals").tag("2")
                    Text("3 meals").tag("3")
                    Text("4 meals").tag("4")
                    Text("IF 16:8").tag("intermittent_fasting_16_8")
                }
            }
            Section("Food Exclusions") {
                ForEach(FoodTag.allergens, id: \.self) { tag in
                    if let exId = tag.exclusionId {
                        Toggle(exId.capitalized, isOn: Binding(
                            get: { exclusions.contains(exId) },
                            set: { on in
                                if on { exclusions.insert(exId) }
                                else { exclusions.remove(exId) }
                            }
                        ))
                    }
                }
            }
        }
    }

    // MARK: - Step 5: Injuries

    private var injuryStep: some View {
        Form {
            Section("Any Injuries?") {
                Text("Select body parts with active injuries to avoid contraindicated exercises.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(BodyPart.allCases, id: \.self) { part in
                    Toggle(part.label(language), isOn: Binding(
                        get: { injuries.contains(part) },
                        set: { on in
                            if on { injuries.insert(part) }
                            else { injuries.remove(part) }
                        }
                    ))
                }
            }
        }
    }

    // MARK: - Step 6: Summary

    private var summaryStep: some View {
        let targets = SetupEngine.calculateTargets(
            sex: sex, weightKg: weightKg, heightCm: heightCm,
            ageYears: ageYears, goal: goal, activityLevel: activityLevel
        )
        return Form {
            Section("Your Profile") {
                LabeledContent("Sex", value: sex.capitalized)
                LabeledContent("Age", value: "\(ageYears)")
                LabeledContent("Height", value: "\(heightCm) cm")
                LabeledContent("Weight", value: String(format: "%.1f kg", weightKg))
            }
            Section("Computed Targets") {
                LabeledContent("BMR", value: "\(Int(targets.bmr)) kcal")
                LabeledContent("TDEE", value: "\(Int(targets.tdee)) kcal")
                LabeledContent("Calorie Target", value: "\(Int(targets.calorieTarget)) kcal")
                LabeledContent("Protein", value: "\(Int(targets.proteinG))g")
                LabeledContent("Fat", value: "\(Int(targets.fatG))g")
                LabeledContent("Carbs", value: "\(Int(targets.carbsG))g")
            }
            Section {
                Toggle("Generate starting schedule", isOn: $generateSchedule)
            }
            if isSaving {
                Section {
                    HStack {
                        ProgressView()
                        Text("Setting up your plan...")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Save

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
            equipment: selectedEquipment.map(\.profileId),
            dietType: dietType,
            mealCountPerDay: mealCount,
            exclusions: Array(exclusions),
            injuries: injuries.map(\.profileId)
        )
        try? await profileStore.save(profile)
        dismiss()
    }
}
