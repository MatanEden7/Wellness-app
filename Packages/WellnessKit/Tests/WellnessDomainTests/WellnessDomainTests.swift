import Testing
@testable import WellnessDomain
import WellnessModels

// MARK: - BMR

@Test func bmrMale() {
    let bmr = SetupEngine.calculateBMR(sex: "male", weightKg: 80, heightCm: 180, ageYears: 30)
    #expect(abs(bmr - 1780) < 0.1)
}

@Test func bmrFemale() {
    let bmr = SetupEngine.calculateBMR(sex: "female", weightKg: 60, heightCm: 165, ageYears: 25)
    #expect(abs(bmr - (600 + 1031.25 - 125 - 161)) < 0.1)
}

// MARK: - TDEE

@Test func tdeeModerate() {
    let tdee = SetupEngine.calculateTDEE(1780, activityLevel: "moderate")
    #expect(abs(tdee - 1780 * 1.55) < 0.1)
}

// MARK: - Calorie targets

@Test func calorieTargetFatLoss() {
    let target = SetupEngine.calculateCalorieTarget(tdee: 2500, goal: "fat_loss", sex: "male")
    #expect(target == 2500 - 500) // 20% of 2500 = 500, under 750 cap
}

@Test func calorieTargetMuscleGain() {
    let target = SetupEngine.calculateCalorieTarget(tdee: 2500, goal: "muscle_gain", sex: "male")
    #expect(target == 2500 + 250) // 10% of 2500 = 250, within [150, 400]
}

@Test func calorieTargetFloorApplied() {
    let target = SetupEngine.calculateCalorieTarget(tdee: 1600, goal: "fat_loss", sex: "female")
    // 20% of 1600 = 320 → raw = 1280. Floor = 1200. 1280 > 1200 so no floor.
    #expect(target == 1280)
}

@Test func calorieTargetFloorKicksIn() {
    let target = SetupEngine.calculateCalorieTarget(tdee: 1400, goal: "fat_loss", sex: "female")
    // 20% of 1400 = 280 → raw = 1120. Floor = 1200. 1200 < 1400 so floor = 1200.
    #expect(target == 1200)
}

// MARK: - Protein

@Test func proteinReferenceWeightNormal() {
    let ref = SetupEngine.proteinReferenceWeight(weightKg: 75, heightCm: 175)
    #expect(ref == 75) // BMI ~24.5, under 27.5 threshold
}

@Test func proteinReferenceWeightHigh() {
    let ref = SetupEngine.proteinReferenceWeight(weightKg: 120, heightCm: 175)
    let heightM = 1.75
    let upper = 27.5 * heightM * heightM
    let expected = upper + 0.25 * (120 - upper)
    #expect(abs(ref - expected) < 0.01)
}

@Test func proteinTargetCapped() {
    let grams = SetupEngine.calculateProteinTarget(
        weightKg: 80, goal: "fat_loss", heightCm: 180, calorieTarget: 1500
    )
    let cap = 1500 * 0.40 / 4 // 150g
    #expect(grams <= cap)
}

// MARK: - Fat

@Test func fatTargetUsesFloor() {
    let fat = SetupEngine.calculateFatTarget(weightKg: 80, calorieTarget: 1200, goal: "fat_loss")
    let fromCal = 1200 * 0.28 / 9
    let floor = 80 * 0.6
    #expect(fat == max(fromCal, floor))
}

// MARK: - Full targets

@Test func calculateTargetsReconciled() {
    let t = SetupEngine.calculateTargets(
        sex: "male", weightKg: 80, heightCm: 180,
        ageYears: 30, goal: "maintenance", activityLevel: "moderate"
    )
    let macroKcal = t.proteinG * 4 + t.carbsG * 4 + t.fatG * 9
    #expect(abs(macroKcal - t.calorieTarget) < 10)
    #expect(t.carbsG > 0)
}

@Test func createUserProfileFillsTargets() {
    let p = SetupEngine.createUserProfile(
        sex: "male", ageYears: 25, heightCm: 175, weightKg: 75,
        goal: "muscle_gain", activityLevel: "active",
        trainingDaysPerWeek: 4
    )
    #expect(p.bmr > 0)
    #expect(p.tdee > p.bmr)
    #expect(p.calorieTarget > p.tdee) // muscle gain → surplus
    #expect(p.proteinTargetG > 0)
    #expect(p.fatTargetG > 0)
    #expect(p.carbsTargetG > 0)
}

// MARK: - Scheduling helpers

@Test func workoutSplit() {
    #expect(SetupEngine.workoutSplit(daysPerWeek: 5) == "ppl_5d")
    #expect(SetupEngine.workoutSplit(daysPerWeek: 3) == "full_body_3d")
}

@Test func mealDistributionCounts() {
    #expect(SetupEngine.mealDistribution(mealCount: "2").count == 2)
    #expect(SetupEngine.mealDistribution(mealCount: "4").count == 4)
    let three = SetupEngine.mealDistribution(mealCount: "3")
    #expect(abs(three.reduce(0, +) - 1.0) < 0.001)
}
