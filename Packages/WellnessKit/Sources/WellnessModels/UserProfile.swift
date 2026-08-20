import Foundation

public struct UserProfile: Codable, Hashable, Sendable {
    public var sex: String
    public var ageYears: Int
    public var heightCm: Int
    public var weightKg: Double
    public var goal: String
    public var activityLevel: String
    public var trainingDaysPerWeek: Int
    public var trainingExperience: String
    public var equipment: [String]
    public var dietType: String
    public var mealCountPerDay: String
    public var exclusions: [String]
    public var injuries: [String]
    public var energyUnit: String
    public var weightUnit: String
    public var bmr: Double
    public var tdee: Double
    public var calorieTarget: Double
    public var proteinTargetG: Double
    public var fatTargetG: Double
    public var carbsTargetG: Double

    public init(
        sex: String,
        ageYears: Int,
        heightCm: Int,
        weightKg: Double,
        goal: String,
        activityLevel: String,
        trainingDaysPerWeek: Int,
        trainingExperience: String = "beginner",
        equipment: [String] = [],
        dietType: String = "omnivore",
        mealCountPerDay: String = "3",
        exclusions: [String] = [],
        injuries: [String] = [],
        energyUnit: String = "kcal",
        weightUnit: String = "g",
        bmr: Double = 0,
        tdee: Double = 0,
        calorieTarget: Double = 0,
        proteinTargetG: Double = 0,
        fatTargetG: Double = 0,
        carbsTargetG: Double = 0
    ) {
        self.sex = sex
        self.ageYears = ageYears
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.goal = goal
        self.activityLevel = activityLevel
        self.trainingDaysPerWeek = trainingDaysPerWeek
        self.trainingExperience = trainingExperience
        self.equipment = equipment
        self.dietType = dietType
        self.mealCountPerDay = mealCountPerDay
        self.exclusions = exclusions
        self.injuries = injuries
        self.energyUnit = energyUnit
        self.weightUnit = weightUnit
        self.bmr = bmr
        self.tdee = tdee
        self.calorieTarget = calorieTarget
        self.proteinTargetG = proteinTargetG
        self.fatTargetG = fatTargetG
        self.carbsTargetG = carbsTargetG
    }
}
