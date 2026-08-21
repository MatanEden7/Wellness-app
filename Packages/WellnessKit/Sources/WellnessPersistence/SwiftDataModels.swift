import Foundation
import SwiftData
import WellnessModels

// MARK: - Food

@Model final class SDFoodItem {
    @Attribute(.unique) var uid: String
    var name: String
    var brand: String?
    var unit: String
    var kcalPerUnit: Double
    var proteinPerUnit: Double
    var carbsPerUnit: Double
    var fatPerUnit: Double
    var isStarter: Bool
    var tagValues: [String]
    var categoryValue: String
    var createdAt: Date
    var updatedAt: Date

    init(_ m: FoodItem) {
        uid = m.id; name = m.name; brand = m.brand; unit = m.unit
        kcalPerUnit = m.kcalPerUnit; proteinPerUnit = m.proteinPerUnit
        carbsPerUnit = m.carbsPerUnit; fatPerUnit = m.fatPerUnit
        isStarter = m.isStarter
        tagValues = m.tags.map(\.rawValue).sorted()
        categoryValue = m.category.rawValue
        createdAt = m.createdAt; updatedAt = m.updatedAt
    }

    var asModel: FoodItem {
        FoodItem(
            id: uid, name: name, brand: brand, unit: unit,
            kcalPerUnit: kcalPerUnit, proteinPerUnit: proteinPerUnit,
            carbsPerUnit: carbsPerUnit, fatPerUnit: fatPerUnit,
            isStarter: isStarter,
            tags: Set(tagValues.compactMap(FoodTag.init(rawValue:))),
            category: FoodCategory(rawValue: categoryValue) ?? .other,
            createdAt: createdAt, updatedAt: updatedAt
        )
    }

    func apply(_ m: FoodItem) {
        uid = m.id; name = m.name; brand = m.brand; unit = m.unit
        kcalPerUnit = m.kcalPerUnit; proteinPerUnit = m.proteinPerUnit
        carbsPerUnit = m.carbsPerUnit; fatPerUnit = m.fatPerUnit
        isStarter = m.isStarter
        tagValues = m.tags.map(\.rawValue).sorted()
        categoryValue = m.category.rawValue
        createdAt = m.createdAt; updatedAt = m.updatedAt
    }
}

// MARK: - Meals

@Model final class SDMeal {
    @Attribute(.unique) var uid: String
    var date: Int
    var name: String
    var note: String?
    var createdAt: Date
    var updatedAt: Date
    var loggedAt: Date?
    var sourceEventId: String?

    init(_ m: Meal) {
        uid = m.id; date = m.date; name = m.name; note = m.note
        createdAt = m.createdAt; updatedAt = m.updatedAt
        loggedAt = m.loggedAt; sourceEventId = m.sourceEventId
    }

    func asModel(items: [MealItem]) -> Meal {
        Meal(id: uid, date: date, name: name, note: note,
             createdAt: createdAt, updatedAt: updatedAt,
             loggedAt: loggedAt, sourceEventId: sourceEventId, items: items)
    }

    func apply(_ m: Meal) {
        uid = m.id; date = m.date; name = m.name; note = m.note
        createdAt = m.createdAt; updatedAt = m.updatedAt
        loggedAt = m.loggedAt; sourceEventId = m.sourceEventId
    }
}

@Model final class SDMealItem {
    @Attribute(.unique) var uid: String
    var mealId: String
    var foodId: String
    var amount: Double
    var kcal: Double
    var protein: Double
    var carbs: Double
    var fat: Double

    init(_ m: MealItem) {
        uid = m.id; mealId = m.mealId; foodId = m.foodId
        amount = m.amount; kcal = m.kcal; protein = m.protein
        carbs = m.carbs; fat = m.fat
    }

    var asModel: MealItem {
        MealItem(id: uid, mealId: mealId, foodId: foodId, amount: amount,
                 kcal: kcal, protein: protein, carbs: carbs, fat: fat)
    }

    func apply(_ m: MealItem) {
        uid = m.id; mealId = m.mealId; foodId = m.foodId
        amount = m.amount; kcal = m.kcal; protein = m.protein
        carbs = m.carbs; fat = m.fat
    }
}

// MARK: - Meal Templates

@Model final class SDMealTemplate {
    @Attribute(.unique) var uid: String
    var name: String
    var descriptionText: String?
    var originValue: String
    var createdAt: Date
    var updatedAt: Date

    init(_ m: MealTemplate) {
        uid = m.id; name = m.name; descriptionText = m.description
        originValue = m.origin.rawValue
        createdAt = m.createdAt; updatedAt = m.updatedAt
    }

    func asModel(items: [MealTemplateItem]) -> MealTemplate {
        MealTemplate(id: uid, name: name, description: descriptionText,
                     origin: TemplateOrigin(rawValue: originValue) ?? .user,
                     createdAt: createdAt, updatedAt: updatedAt, items: items)
    }

    func apply(_ m: MealTemplate) {
        uid = m.id; name = m.name; descriptionText = m.description
        originValue = m.origin.rawValue
        createdAt = m.createdAt; updatedAt = m.updatedAt
    }
}

@Model final class SDMealTemplateItem {
    @Attribute(.unique) var uid: String
    var templateId: String
    var foodId: String
    var amount: Double

    init(_ m: MealTemplateItem) {
        uid = m.id; templateId = m.templateId; foodId = m.foodId; amount = m.amount
    }

    var asModel: MealTemplateItem {
        MealTemplateItem(id: uid, templateId: templateId, foodId: foodId, amount: amount)
    }

    func apply(_ m: MealTemplateItem) {
        uid = m.id; templateId = m.templateId; foodId = m.foodId; amount = m.amount
    }
}

// MARK: - Exercises

@Model final class SDExercise {
    @Attribute(.unique) var uid: String
    var name: String
    var primaryMuscle: String?
    var unit: String
    var notes: String?
    var equipmentValues: [String]
    var contraindicatedValues: [String]
    var rehabValues: [String]
    var movementPatternValue: String?
    var mechanicValue: String?
    var loadClassValue: String?

    init(_ m: Exercise) {
        uid = m.id; name = m.name; primaryMuscle = m.primaryMuscle
        unit = m.unit; notes = m.notes
        equipmentValues = m.equipment.map(\.rawValue).sorted()
        contraindicatedValues = m.contraindicatedFor.map(\.rawValue).sorted()
        rehabValues = m.rehabFor.map(\.rawValue).sorted()
        movementPatternValue = m.movementPattern?.rawValue
        mechanicValue = m.mechanic?.rawValue
        loadClassValue = m.loadClass?.rawValue
    }

    var asModel: Exercise {
        Exercise(
            id: uid, name: name, primaryMuscle: primaryMuscle, unit: unit, notes: notes,
            equipment: Set(equipmentValues.compactMap(Equipment.init(rawValue:))),
            contraindicatedFor: Set(contraindicatedValues.compactMap(BodyPart.init(rawValue:))),
            rehabFor: Set(rehabValues.compactMap(BodyPart.init(rawValue:))),
            movementPattern: movementPatternValue.flatMap(MovementPattern.init(rawValue:)),
            mechanic: mechanicValue.flatMap(Mechanic.init(rawValue:)),
            loadClass: loadClassValue.flatMap(LoadClass.init(rawValue:))
        )
    }

    func apply(_ m: Exercise) {
        uid = m.id; name = m.name; primaryMuscle = m.primaryMuscle
        unit = m.unit; notes = m.notes
        equipmentValues = m.equipment.map(\.rawValue).sorted()
        contraindicatedValues = m.contraindicatedFor.map(\.rawValue).sorted()
        rehabValues = m.rehabFor.map(\.rawValue).sorted()
        movementPatternValue = m.movementPattern?.rawValue
        mechanicValue = m.mechanic?.rawValue
        loadClassValue = m.loadClass?.rawValue
    }
}

// MARK: - Workout Templates

@Model final class SDWorkoutTemplate {
    @Attribute(.unique) var uid: String
    var name: String
    var notes: String?
    var originValue: String
    var customRest: Bool

    init(_ m: WorkoutTemplate) {
        uid = m.id; name = m.name; notes = m.notes
        originValue = m.origin.rawValue; customRest = m.customRest
    }

    func asModel(exercises: [TemplateExercise]) -> WorkoutTemplate {
        WorkoutTemplate(id: uid, name: name, notes: notes,
                        origin: TemplateOrigin(rawValue: originValue) ?? .user,
                        customRest: customRest, exercises: exercises)
    }

    func apply(_ m: WorkoutTemplate) {
        uid = m.id; name = m.name; notes = m.notes
        originValue = m.origin.rawValue; customRest = m.customRest
    }
}

@Model final class SDTemplateExercise {
    @Attribute(.unique) var uid: String
    var templateId: String
    var exerciseId: String
    var orderIndex: Int
    var defaultSets: Int
    var defaultReps: Int?
    var defaultWeight: Double?
    var defaultRestSeconds: Int?
    var isRest: Bool

    init(_ m: TemplateExercise) {
        uid = m.id; templateId = m.templateId; exerciseId = m.exerciseId
        orderIndex = m.orderIndex; defaultSets = m.defaultSets
        defaultReps = m.defaultReps; defaultWeight = m.defaultWeight
        defaultRestSeconds = m.defaultRestSeconds; isRest = m.isRest
    }

    var asModel: TemplateExercise {
        TemplateExercise(id: uid, templateId: templateId, exerciseId: exerciseId,
                         orderIndex: orderIndex, defaultSets: defaultSets,
                         defaultReps: defaultReps, defaultWeight: defaultWeight,
                         defaultRestSeconds: defaultRestSeconds, isRest: isRest)
    }

    func apply(_ m: TemplateExercise) {
        uid = m.id; templateId = m.templateId; exerciseId = m.exerciseId
        orderIndex = m.orderIndex; defaultSets = m.defaultSets
        defaultReps = m.defaultReps; defaultWeight = m.defaultWeight
        defaultRestSeconds = m.defaultRestSeconds; isRest = m.isRest
    }
}

// MARK: - Workout Sessions

@Model final class SDWorkoutSession {
    @Attribute(.unique) var uid: String
    var templateId: String?
    var startedAt: Date
    var endedAt: Date?
    var note: String?
    var sourceEventId: String?

    init(_ m: WorkoutSession) {
        uid = m.id; templateId = m.templateId; startedAt = m.startedAt
        endedAt = m.endedAt; note = m.note; sourceEventId = m.sourceEventId
    }

    func asModel(sets: [SetEntry]) -> WorkoutSession {
        WorkoutSession(id: uid, templateId: templateId, startedAt: startedAt,
                       endedAt: endedAt, note: note, sourceEventId: sourceEventId, sets: sets)
    }

    func apply(_ m: WorkoutSession) {
        uid = m.id; templateId = m.templateId; startedAt = m.startedAt
        endedAt = m.endedAt; note = m.note; sourceEventId = m.sourceEventId
    }
}

@Model final class SDSetEntry {
    @Attribute(.unique) var uid: String
    var sessionId: String
    var exerciseId: String
    var orderIndex: Int
    var reps: Int
    var weight: Double?
    var restSeconds: Int?

    init(_ m: SetEntry) {
        uid = m.id; sessionId = m.sessionId; exerciseId = m.exerciseId
        orderIndex = m.orderIndex; reps = m.reps
        weight = m.weight; restSeconds = m.restSeconds
    }

    var asModel: SetEntry {
        SetEntry(id: uid, sessionId: sessionId, exerciseId: exerciseId,
                 orderIndex: orderIndex, reps: reps,
                 weight: weight, restSeconds: restSeconds)
    }

    func apply(_ m: SetEntry) {
        uid = m.id; sessionId = m.sessionId; exerciseId = m.exerciseId
        orderIndex = m.orderIndex; reps = m.reps
        weight = m.weight; restSeconds = m.restSeconds
    }
}

// MARK: - Sleep

@Model final class SDSleepEntry {
    @Attribute(.unique) var uid: String
    var startedAt: Date
    var endedAt: Date?
    var quality: Int?
    var note: String?
    var sourceEventId: String?

    init(_ m: SleepEntry) {
        uid = m.id; startedAt = m.startedAt; endedAt = m.endedAt
        quality = m.quality; note = m.note; sourceEventId = m.sourceEventId
    }

    var asModel: SleepEntry {
        SleepEntry(id: uid, startedAt: startedAt, endedAt: endedAt,
                   quality: quality, note: note, sourceEventId: sourceEventId)
    }

    func apply(_ m: SleepEntry) {
        uid = m.id; startedAt = m.startedAt; endedAt = m.endedAt
        quality = m.quality; note = m.note; sourceEventId = m.sourceEventId
    }
}

// MARK: - Body Weight

@Model final class SDBodyWeightEntry {
    @Attribute(.unique) var uid: String
    var recordedAt: Date
    var kg: Double
    var note: String?

    init(_ m: BodyWeightEntry) {
        uid = m.id; recordedAt = m.recordedAt; kg = m.kg; note = m.note
    }

    var asModel: BodyWeightEntry {
        BodyWeightEntry(id: uid, recordedAt: recordedAt, kg: kg, note: note)
    }

    func apply(_ m: BodyWeightEntry) {
        uid = m.id; recordedAt = m.recordedAt; kg = m.kg; note = m.note
    }
}

// MARK: - Calendar

@Model final class SDScheduledEvent {
    @Attribute(.unique) var uid: String
    var title: String
    var descriptionText: String?
    var typeValue: String
    var scheduledAt: Date
    var completedAt: Date?
    var statusValue: String
    var recurrenceTypeValue: String
    var recurrenceDays: [Int]
    var customInterval: Int?
    var recurrenceEndDate: Date?
    var templateId: String?

    init(_ m: ScheduledEvent) {
        uid = m.id; title = m.title; descriptionText = m.description
        typeValue = m.type.rawValue; scheduledAt = m.scheduledAt
        completedAt = m.completedAt; statusValue = m.status.rawValue
        recurrenceTypeValue = m.recurrenceType.rawValue
        recurrenceDays = m.recurrenceDays; customInterval = m.customInterval
        recurrenceEndDate = m.recurrenceEndDate; templateId = m.templateId
    }

    var asModel: ScheduledEvent {
        ScheduledEvent(
            id: uid, title: title, description: descriptionText,
            type: EventType(rawValue: typeValue) ?? .meal,
            scheduledAt: scheduledAt, completedAt: completedAt,
            status: EventStatus(rawValue: statusValue) ?? .planned,
            recurrenceType: RecurrenceType(rawValue: recurrenceTypeValue) ?? .none,
            recurrenceDays: recurrenceDays,
            customInterval: customInterval,
            recurrenceEndDate: recurrenceEndDate,
            templateId: templateId
        )
    }

    func apply(_ m: ScheduledEvent) {
        uid = m.id; title = m.title; descriptionText = m.description
        typeValue = m.type.rawValue; scheduledAt = m.scheduledAt
        completedAt = m.completedAt; statusValue = m.status.rawValue
        recurrenceTypeValue = m.recurrenceType.rawValue
        recurrenceDays = m.recurrenceDays; customInterval = m.customInterval
        recurrenceEndDate = m.recurrenceEndDate; templateId = m.templateId
    }
}

// MARK: - User Profile

@Model final class SDUserProfile {
    @Attribute(.unique) var key: String
    var sex: String
    var ageYears: Int
    var heightCm: Int
    var weightKg: Double
    var goal: String
    var activityLevel: String
    var trainingDaysPerWeek: Int
    var trainingExperience: String
    var equipment: [String]
    var dietType: String
    var mealCountPerDay: String
    var exclusions: [String]
    var injuries: [String]
    var energyUnit: String
    var weightUnit: String
    var bmr: Double
    var tdee: Double
    var calorieTarget: Double
    var proteinTargetG: Double
    var fatTargetG: Double
    var carbsTargetG: Double

    init(_ m: UserProfile) {
        key = "profile"
        sex = m.sex; ageYears = m.ageYears; heightCm = m.heightCm
        weightKg = m.weightKg; goal = m.goal; activityLevel = m.activityLevel
        trainingDaysPerWeek = m.trainingDaysPerWeek
        trainingExperience = m.trainingExperience
        equipment = m.equipment; dietType = m.dietType
        mealCountPerDay = m.mealCountPerDay; exclusions = m.exclusions
        injuries = m.injuries; energyUnit = m.energyUnit; weightUnit = m.weightUnit
        bmr = m.bmr; tdee = m.tdee; calorieTarget = m.calorieTarget
        proteinTargetG = m.proteinTargetG; fatTargetG = m.fatTargetG
        carbsTargetG = m.carbsTargetG
    }

    var asModel: UserProfile {
        UserProfile(
            sex: sex, ageYears: ageYears, heightCm: heightCm, weightKg: weightKg,
            goal: goal, activityLevel: activityLevel,
            trainingDaysPerWeek: trainingDaysPerWeek,
            trainingExperience: trainingExperience,
            equipment: equipment, dietType: dietType,
            mealCountPerDay: mealCountPerDay, exclusions: exclusions,
            injuries: injuries, energyUnit: energyUnit, weightUnit: weightUnit,
            bmr: bmr, tdee: tdee, calorieTarget: calorieTarget,
            proteinTargetG: proteinTargetG, fatTargetG: fatTargetG,
            carbsTargetG: carbsTargetG
        )
    }

    func apply(_ m: UserProfile) {
        sex = m.sex; ageYears = m.ageYears; heightCm = m.heightCm
        weightKg = m.weightKg; goal = m.goal; activityLevel = m.activityLevel
        trainingDaysPerWeek = m.trainingDaysPerWeek
        trainingExperience = m.trainingExperience
        equipment = m.equipment; dietType = m.dietType
        mealCountPerDay = m.mealCountPerDay; exclusions = m.exclusions
        injuries = m.injuries; energyUnit = m.energyUnit; weightUnit = m.weightUnit
        bmr = m.bmr; tdee = m.tdee; calorieTarget = m.calorieTarget
        proteinTargetG = m.proteinTargetG; fatTargetG = m.fatTargetG
        carbsTargetG = m.carbsTargetG
    }
}
