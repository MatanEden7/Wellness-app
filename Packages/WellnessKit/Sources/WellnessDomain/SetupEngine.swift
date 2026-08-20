import Foundation
import WellnessModels

public enum SetupEngine: Sendable {

    // MARK: - BMR (Mifflin-St Jeor)

    public static func calculateBMR(
        sex: String,
        weightKg: Double,
        heightCm: Int,
        ageYears: Int
    ) -> Double {
        let base = 10 * weightKg + 6.25 * Double(heightCm) - 5 * Double(ageYears)
        return sex == "male" ? base + 5 : base - 161
    }

    // MARK: - Activity factor

    public static func activityFactor(_ level: String) -> Double {
        switch level {
        case "sedentary":   1.2
        case "light":       1.375
        case "moderate":    1.55
        case "active":      1.725
        case "very_active": 1.9
        default:            1.2
        }
    }

    // MARK: - TDEE

    public static func calculateTDEE(_ bmr: Double, activityLevel: String) -> Double {
        bmr * activityFactor(activityLevel)
    }

    // MARK: - Calorie target

    public static func minimumSafeCalories(sex: String) -> Double {
        sex == "male" ? 1500 : 1200
    }

    public static func calculateCalorieTarget(
        tdee: Double,
        goal: String,
        sex: String = "male"
    ) -> Double {
        let raw: Double
        switch goal {
        case "fat_loss":
            raw = tdee - min(max(tdee * 0.20, 0), 750)
        case "muscle_gain":
            raw = tdee + min(max(tdee * 0.10, 150), 400)
        case "maintenance", "mobility_rehab":
            raw = tdee
        default:
            raw = tdee
        }
        let floor = minimumSafeCalories(sex: sex)
        let effectiveFloor = floor < tdee ? floor : tdee
        return raw < effectiveFloor ? effectiveFloor : raw
    }

    // MARK: - Protein

    public static func proteinPerKgForGoal(_ goal: String) -> Double {
        switch goal {
        case "fat_loss":       2.2
        case "muscle_gain":    2.0
        case "maintenance":    1.8
        case "mobility_rehab": 1.8
        default:               1.8
        }
    }

    public static func proteinReferenceWeight(weightKg: Double, heightCm: Int) -> Double {
        guard heightCm > 0 else { return weightKg }
        let heightM = Double(heightCm) / 100
        let upperHealthy = 27.5 * heightM * heightM
        if weightKg <= upperHealthy { return weightKg }
        return upperHealthy + 0.25 * (weightKg - upperHealthy)
    }

    public static func calculateProteinTarget(
        weightKg: Double,
        goal: String,
        heightCm: Int = 0,
        calorieTarget: Double? = nil
    ) -> Double {
        let grams = proteinReferenceWeight(weightKg: weightKg, heightCm: heightCm)
            * proteinPerKgForGoal(goal)
        guard let cal = calorieTarget else { return grams }
        let cap = cal * 0.40 / 4
        return grams > cap ? cap : grams
    }

    // MARK: - Fat

    public static func fatFractionForGoal(_ goal: String) -> Double {
        switch goal {
        case "fat_loss":       0.28
        case "muscle_gain":    0.25
        case "maintenance":    0.28
        case "mobility_rehab": 0.30
        default:               0.28
        }
    }

    public static func minimumFatGrams(weightKg: Double) -> Double {
        weightKg * 0.6
    }

    public static func calculateFatTarget(
        weightKg: Double,
        calorieTarget: Double,
        goal: String
    ) -> Double {
        let fromCalories = calorieTarget * fatFractionForGoal(goal) / 9
        let floor = minimumFatGrams(weightKg: weightKg)
        return fromCalories < floor ? floor : fromCalories
    }

    // MARK: - Carbs (fills remaining)

    public static func calculateCarbsTarget(
        calorieTarget: Double,
        proteinG: Double,
        fatG: Double
    ) -> Double {
        let remaining = calorieTarget - proteinG * 4 - fatG * 9
        return max(remaining / 4, 0)
    }

    // MARK: - Full target set

    public static func calculateTargets(
        sex: String,
        weightKg: Double,
        heightCm: Int,
        ageYears: Int,
        goal: String,
        activityLevel: String
    ) -> NutritionTargets {
        let bmr = calculateBMR(sex: sex, weightKg: weightKg, heightCm: heightCm, ageYears: ageYears)
        let tdee = calculateTDEE(bmr, activityLevel: activityLevel)
        let calories = calculateCalorieTarget(tdee: tdee, goal: goal, sex: sex)

        var protein = calculateProteinTarget(
            weightKg: weightKg, goal: goal,
            heightCm: heightCm, calorieTarget: calories
        )
        var fat = calculateFatTarget(weightKg: weightKg, calorieTarget: calories, goal: goal)

        let minCarbsG = 50.0
        let fatFloor = minimumFatGrams(weightKg: weightKg)
        let proteinFloor = proteinReferenceWeight(weightKg: weightKg, heightCm: heightCm) * 1.6
        let budget = calories - minCarbsG * 4

        if protein * 4 + fat * 9 > budget {
            fat = min(max((budget - protein * 4) / 9, fatFloor), fat)
        }
        if protein * 4 + fat * 9 > budget {
            protein = min(max((budget - fat * 9) / 4, proteinFloor), protein)
        }

        let roundedCalories = (calories / 10).rounded() * 10
        let roundedProtein = protein.rounded()
        let roundedFat = fat.rounded()
        let carbs = calculateCarbsTarget(
            calorieTarget: roundedCalories,
            proteinG: roundedProtein,
            fatG: roundedFat
        ).rounded()

        return NutritionTargets(
            bmr: bmr,
            tdee: tdee,
            calorieTarget: roundedCalories,
            proteinG: roundedProtein,
            fatG: roundedFat,
            carbsG: carbs
        )
    }

    // MARK: - Profile factory

    public static func createUserProfile(
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
        weightUnit: String = "g"
    ) -> UserProfile {
        let targets = calculateTargets(
            sex: sex, weightKg: weightKg, heightCm: heightCm,
            ageYears: ageYears, goal: goal, activityLevel: activityLevel
        )
        return UserProfile(
            sex: sex,
            ageYears: ageYears,
            heightCm: heightCm,
            weightKg: weightKg,
            goal: goal,
            activityLevel: activityLevel,
            trainingDaysPerWeek: trainingDaysPerWeek,
            trainingExperience: trainingExperience,
            equipment: equipment,
            dietType: dietType,
            mealCountPerDay: mealCountPerDay,
            exclusions: exclusions,
            injuries: injuries,
            energyUnit: energyUnit,
            weightUnit: weightUnit,
            bmr: targets.bmr,
            tdee: targets.tdee,
            calorieTarget: targets.calorieTarget,
            proteinTargetG: targets.proteinG,
            fatTargetG: targets.fatG,
            carbsTargetG: targets.carbsG
        )
    }

    // MARK: - Workout split

    public static func workoutSplit(daysPerWeek: Int) -> String {
        daysPerWeek >= 5 ? "ppl_5d" : "full_body_3d"
    }

    // MARK: - Meal distribution

    public static func mealDistribution(mealCount: String) -> [Double] {
        switch mealCount {
        case "2":                         [0.45, 0.55]
        case "3":                         [0.30, 0.40, 0.30]
        case "4":                         [0.25, 0.30, 0.25, 0.20]
        case "intermittent_fasting_16_8": [0.40, 0.35, 0.25]
        default:                          [0.30, 0.40, 0.30]
        }
    }

    // MARK: - Workout schedule days

    public static func workoutScheduleDays(daysPerWeek: Int) -> [String] {
        if daysPerWeek >= 5 {
            return ["Mon", "Tue", "Thu", "Fri", "Sat"]
        } else if daysPerWeek >= 3 {
            return ["Mon", "Wed", "Fri"]
        } else {
            return ["Mon", "Thu"]
        }
    }
}
