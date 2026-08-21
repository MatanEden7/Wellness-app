import Foundation
import WellnessModels
import WellnessPersistence

public struct BackupService: Sendable {
    private let food: any FoodStore
    private let meal: any MealStore
    private let mealTemplate: any MealTemplateStore
    private let exercise: any ExerciseStore
    private let workoutTemplate: any WorkoutTemplateStore
    private let workoutSession: any WorkoutSessionStore
    private let sleep: any SleepStore
    private let bodyWeight: any BodyWeightStore
    private let event: any ScheduledEventStore
    private let profile: any UserProfileStore
    private let prefs: Preferences?

    public init(
        food: any FoodStore,
        meal: any MealStore,
        mealTemplate: any MealTemplateStore,
        exercise: any ExerciseStore,
        workoutTemplate: any WorkoutTemplateStore,
        workoutSession: any WorkoutSessionStore,
        sleep: any SleepStore,
        bodyWeight: any BodyWeightStore,
        event: any ScheduledEventStore,
        profile: any UserProfileStore,
        prefs: Preferences? = nil
    ) {
        self.food = food; self.meal = meal; self.mealTemplate = mealTemplate
        self.exercise = exercise; self.workoutTemplate = workoutTemplate
        self.workoutSession = workoutSession; self.sleep = sleep
        self.bodyWeight = bodyWeight; self.event = event
        self.profile = profile; self.prefs = prefs
    }

    // MARK: - Export

    public func exportToJSON() async throws -> Data {
        let foods = try await food.allFoods()
        let meals = try await meal.allMeals()
        let mealItems = meals.flatMap(\.items)
        let mealTemplates = try await mealTemplate.allMealTemplates()
        let mealTemplateItems = mealTemplates.flatMap(\.items)
        let exercises = try await exercise.allExercises()
        let workoutTemplates = try await workoutTemplate.allWorkoutTemplates()
        let templateExercises = workoutTemplates.flatMap(\.exercises)
        let sessions = try await workoutSession.allWorkoutSessions()
        let setEntries = sessions.flatMap(\.sets)
        let sleepEntries = try await sleep.allSleepEntries()
        let bodyWeightEntries = try await bodyWeight.allBodyWeightEntries()
        let events = try await event.allScheduledEvents()
        let userProfile = try await profile.profile()

        var data: [String: Any] = [
            "foods": foods.map { encode($0) },
            "meals": meals.map { encodeMeal($0) },
            "mealItems": mealItems.map { encode($0) },
            "mealTemplates": mealTemplates.map { encodeMealTemplate($0) },
            "mealTemplateItems": mealTemplateItems.map { encode($0) },
            "exercises": exercises.map { encode($0) },
            "workoutTemplates": workoutTemplates.map { encodeWorkoutTemplate($0) },
            "templateExercises": templateExercises.map { encode($0) },
            "workoutSessions": sessions.map { encodeSession($0) },
            "setEntries": setEntries.map { encode($0) },
            "sleepEntries": sleepEntries.map { encode($0) },
            "bodyWeightEntries": bodyWeightEntries.map { encode($0) },
            "scheduledEvents": events.map { encode($0) },
        ]

        if let p = userProfile {
            let profileData = try JSONEncoder().encode(p)
            data["profile"] = String(data: profileData, encoding: .utf8)
        }

        if let prefs {
            data["preferences"] = prefs.encodeAll()
        }

        let envelope: [String: Any] = [
            "version": "1.4.0",
            "exportedAt": ISO8601DateFormatter().string(from: .now),
            "data": data,
        ]

        return try JSONSerialization.data(withJSONObject: envelope, options: [.sortedKeys, .prettyPrinted])
    }

    // MARK: - Import

    public func importFromJSON(_ jsonData: Data) async throws {
        let root = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        let data = root["data"] as! [String: Any]

        let foods = readArray(data, "foods", decodeFoodItem)
        let meals = readArray(data, "meals", decodeMeal)
        let mealItems = readArray(data, "mealItems", decodeMealItem)
        let mealTemplates = readArray(data, "mealTemplates", decodeMealTemplate)
        let mealTemplateItems = readArray(data, "mealTemplateItems", decodeMealTemplateItem)
        let exercises = readArray(data, "exercises", decodeExercise)
        let workoutTemplates = readArray(data, "workoutTemplates", decodeWorkoutTemplate)
        let templateExercises = readArray(data, "templateExercises", decodeTemplateExercise)
        let sessions = readArray(data, "workoutSessions", decodeWorkoutSession)
        let setEntries = readArray(data, "setEntries", decodeSetEntry)
        let sleepEntries = readArray(data, "sleepEntries", decodeSleepEntry)
        let bodyWeightEntries = readArray(data, "bodyWeightEntries", decodeBodyWeightEntry)
        let events = readArray(data, "scheduledEvents", decodeScheduledEvent)

        for f in foods { try await food.insertFood(f) }
        for m in meals { try await meal.insertMeal(m) }
        for mi in mealItems { try await meal.insertMealItem(mi) }
        for t in mealTemplates { try await mealTemplate.insertMealTemplate(t) }
        for i in mealTemplateItems { try await mealTemplate.insertMealTemplateItem(i) }
        for e in exercises { try await exercise.insertExercise(e) }
        for t in workoutTemplates { try await workoutTemplate.insertWorkoutTemplate(t) }
        for te in templateExercises { try await workoutTemplate.insertTemplateExercise(te) }
        for s in sessions { try await workoutSession.insertWorkoutSession(s) }
        for se in setEntries { try await workoutSession.insertSetEntry(se) }
        for s in sleepEntries { try await sleep.insertSleepEntry(s) }
        for b in bodyWeightEntries { try await bodyWeight.insertBodyWeightEntry(b) }

        try await event.deleteAllScheduledEvents()
        for e in events { try await event.insertScheduledEvent(e) }

        if let profileJson = data["profile"] as? String,
           let profileData = profileJson.data(using: .utf8) {
            let p = try JSONDecoder().decode(UserProfile.self, from: profileData)
            try await profile.saveProfile(p)
        }

        if let prefs, let prefDict = data["preferences"] as? [String: Any] {
            prefs.restoreAll(from: prefDict)
        }
    }

    // MARK: - Row counts (for round-trip verification)

    public struct RowCounts: Equatable, Sendable {
        public var foods: Int
        public var meals: Int
        public var mealItems: Int
        public var mealTemplates: Int
        public var mealTemplateItems: Int
        public var exercises: Int
        public var workoutTemplates: Int
        public var templateExercises: Int
        public var workoutSessions: Int
        public var setEntries: Int
        public var sleepEntries: Int
        public var bodyWeightEntries: Int
        public var scheduledEvents: Int
        public var hasProfile: Bool
    }

    public func rowCounts() async throws -> RowCounts {
        let allMeals = try await meal.allMeals()
        let allMealTemplates = try await mealTemplate.allMealTemplates()
        let allWorkoutTemplates = try await workoutTemplate.allWorkoutTemplates()
        let allSessions = try await workoutSession.allWorkoutSessions()

        var mealItemCount = 0
        for m in allMeals { mealItemCount += try await meal.mealItems(byMealId: m.id).count }
        var mtItemCount = 0
        for t in allMealTemplates { mtItemCount += try await mealTemplate.mealTemplateItems(byTemplateId: t.id).count }
        var teCount = 0
        for t in allWorkoutTemplates { teCount += try await workoutTemplate.templateExercises(byTemplateId: t.id).count }
        var setCount = 0
        for s in allSessions { setCount += try await workoutSession.setEntries(bySessionId: s.id).count }

        return RowCounts(
            foods: try await food.allFoods().count,
            meals: allMeals.count,
            mealItems: mealItemCount,
            mealTemplates: allMealTemplates.count,
            mealTemplateItems: mtItemCount,
            exercises: try await exercise.allExercises().count,
            workoutTemplates: allWorkoutTemplates.count,
            templateExercises: teCount,
            workoutSessions: allSessions.count,
            setEntries: setCount,
            sleepEntries: try await sleep.allSleepEntries().count,
            bodyWeightEntries: try await bodyWeight.allBodyWeightEntries().count,
            scheduledEvents: try await event.allScheduledEvents().count,
            hasProfile: try await profile.profile() != nil
        )
    }
}

// MARK: - Encode helpers

private nonisolated(unsafe) let iso = ISO8601DateFormatter()

private func encode(_ f: FoodItem) -> [String: Any] {
    var d: [String: Any] = [
        "id": f.id, "name": f.name, "unit": f.unit,
        "kcalPerUnit": f.kcalPerUnit, "proteinPerUnit": f.proteinPerUnit,
        "carbsPerUnit": f.carbsPerUnit, "fatPerUnit": f.fatPerUnit,
        "isStarter": f.isStarter,
        "tags": f.tags.map(\.rawValue).sorted(),
        "category": f.category.rawValue,
        "createdAt": iso.string(from: f.createdAt),
        "updatedAt": iso.string(from: f.updatedAt),
    ]
    if let b = f.brand { d["brand"] = b }
    return d
}

private func encodeMeal(_ m: Meal) -> [String: Any] {
    var d: [String: Any] = [
        "id": m.id, "date": m.date, "name": m.name,
        "createdAt": iso.string(from: m.createdAt),
        "updatedAt": iso.string(from: m.updatedAt),
    ]
    if let n = m.note { d["note"] = n }
    if let l = m.loggedAt { d["loggedAt"] = iso.string(from: l) }
    if let s = m.sourceEventId { d["sourceEventId"] = s }
    return d
}

private func encode(_ mi: MealItem) -> [String: Any] {
    ["id": mi.id, "mealId": mi.mealId, "foodId": mi.foodId,
     "amount": mi.amount, "kcal": mi.kcal, "protein": mi.protein,
     "carbs": mi.carbs, "fat": mi.fat]
}

private func encodeMealTemplate(_ t: MealTemplate) -> [String: Any] {
    var d: [String: Any] = [
        "id": t.id, "name": t.name, "origin": t.origin.rawValue,
        "createdAt": iso.string(from: t.createdAt),
        "updatedAt": iso.string(from: t.updatedAt),
    ]
    if let desc = t.description { d["description"] = desc }
    return d
}

private func encode(_ i: MealTemplateItem) -> [String: Any] {
    ["id": i.id, "templateId": i.templateId, "foodId": i.foodId, "amount": i.amount]
}

private func encode(_ e: Exercise) -> [String: Any] {
    var d: [String: Any] = ["id": e.id, "name": e.name, "unit": e.unit]
    if let m = e.primaryMuscle { d["primaryMuscle"] = m }
    if let n = e.notes { d["notes"] = n }
    if !e.equipment.isEmpty { d["equipment"] = e.equipment.map(\.rawValue).sorted() }
    if !e.contraindicatedFor.isEmpty { d["contraindicatedFor"] = e.contraindicatedFor.map(\.rawValue).sorted() }
    if !e.rehabFor.isEmpty { d["rehabFor"] = e.rehabFor.map(\.rawValue).sorted() }
    if let p = e.movementPattern { d["movementPattern"] = p.rawValue }
    if let m = e.mechanic { d["mechanic"] = m.rawValue }
    if let l = e.loadClass { d["loadClass"] = l.rawValue }
    return d
}

private func encodeWorkoutTemplate(_ t: WorkoutTemplate) -> [String: Any] {
    var d: [String: Any] = ["id": t.id, "name": t.name, "origin": t.origin.rawValue, "customRest": t.customRest]
    if let n = t.notes { d["notes"] = n }
    return d
}

private func encode(_ te: TemplateExercise) -> [String: Any] {
    var d: [String: Any] = [
        "id": te.id, "templateId": te.templateId, "exerciseId": te.exerciseId,
        "orderIndex": te.orderIndex, "defaultSets": te.defaultSets, "isRest": te.isRest,
    ]
    if let r = te.defaultReps { d["defaultReps"] = r }
    if let w = te.defaultWeight { d["defaultWeight"] = w }
    if let s = te.defaultRestSeconds { d["defaultRestSeconds"] = s }
    return d
}

private func encodeSession(_ s: WorkoutSession) -> [String: Any] {
    var d: [String: Any] = ["id": s.id, "startedAt": iso.string(from: s.startedAt)]
    if let t = s.templateId { d["templateId"] = t }
    if let e = s.endedAt { d["endedAt"] = iso.string(from: e) }
    if let n = s.note { d["note"] = n }
    if let s = s.sourceEventId { d["sourceEventId"] = s }
    return d
}

private func encode(_ se: SetEntry) -> [String: Any] {
    var d: [String: Any] = [
        "id": se.id, "sessionId": se.sessionId, "exerciseId": se.exerciseId,
        "orderIndex": se.orderIndex, "reps": se.reps,
    ]
    if let w = se.weight { d["weight"] = w }
    if let r = se.restSeconds { d["restSeconds"] = r }
    return d
}

private func encode(_ s: SleepEntry) -> [String: Any] {
    var d: [String: Any] = ["id": s.id, "startedAt": iso.string(from: s.startedAt)]
    if let e = s.endedAt { d["endedAt"] = iso.string(from: e) }
    if let q = s.quality { d["quality"] = q }
    if let n = s.note { d["note"] = n }
    if let s = s.sourceEventId { d["sourceEventId"] = s }
    return d
}

private func encode(_ b: BodyWeightEntry) -> [String: Any] {
    var d: [String: Any] = ["id": b.id, "recordedAt": iso.string(from: b.recordedAt), "kg": b.kg]
    if let n = b.note { d["note"] = n }
    return d
}

private func encode(_ e: ScheduledEvent) -> [String: Any] {
    var d: [String: Any] = [
        "id": e.id, "title": e.title, "type": e.type.rawValue,
        "scheduledAt": iso.string(from: e.scheduledAt),
        "status": e.status.rawValue, "recurrenceType": e.recurrenceType.rawValue,
    ]
    if let desc = e.description { d["description"] = desc }
    if let c = e.completedAt { d["completedAt"] = iso.string(from: c) }
    if !e.recurrenceDays.isEmpty { d["recurrenceDays"] = e.recurrenceDays }
    if let ci = e.customInterval { d["customInterval"] = ci }
    if let re = e.recurrenceEndDate { d["recurrenceEndDate"] = iso.string(from: re) }
    if let t = e.templateId { d["templateId"] = t }
    return d
}

// MARK: - Decode helpers

private func readArray<T>(_ data: [String: Any], _ key: String, _ decode: ([String: Any]) -> T?) -> [T] {
    guard let list = data[key] as? [[String: Any]] else { return [] }
    return list.compactMap(decode)
}

private func date(_ d: [String: Any], _ key: String) -> Date? {
    (d[key] as? String).flatMap(iso.date(from:))
}

private func decodeFoodItem(_ d: [String: Any]) -> FoodItem? {
    guard let id = d["id"] as? String, let name = d["name"] as? String else { return nil }
    return FoodItem(
        id: id, name: name, brand: d["brand"] as? String,
        unit: d["unit"] as? String ?? "100g",
        kcalPerUnit: d["kcalPerUnit"] as? Double ?? 0,
        proteinPerUnit: d["proteinPerUnit"] as? Double ?? 0,
        carbsPerUnit: d["carbsPerUnit"] as? Double ?? 0,
        fatPerUnit: d["fatPerUnit"] as? Double ?? 0,
        isStarter: d["isStarter"] as? Bool ?? false,
        tags: Set((d["tags"] as? [String] ?? []).compactMap(FoodTag.init(rawValue:))),
        category: (d["category"] as? String).flatMap(FoodCategory.init(rawValue:)) ?? .other,
        createdAt: date(d, "createdAt") ?? .now,
        updatedAt: date(d, "updatedAt") ?? .now
    )
}

private func decodeMeal(_ d: [String: Any]) -> Meal? {
    guard let id = d["id"] as? String else { return nil }
    return Meal(
        id: id, date: d["date"] as? Int ?? 0, name: d["name"] as? String ?? "",
        note: d["note"] as? String,
        createdAt: date(d, "createdAt") ?? .now,
        updatedAt: date(d, "updatedAt") ?? .now,
        loggedAt: date(d, "loggedAt"),
        sourceEventId: d["sourceEventId"] as? String
    )
}

private func decodeMealItem(_ d: [String: Any]) -> MealItem? {
    guard let id = d["id"] as? String else { return nil }
    return MealItem(
        id: id, mealId: d["mealId"] as? String ?? "",
        foodId: d["foodId"] as? String ?? "",
        amount: d["amount"] as? Double ?? 0,
        kcal: d["kcal"] as? Double ?? 0,
        protein: d["protein"] as? Double ?? 0,
        carbs: d["carbs"] as? Double ?? 0,
        fat: d["fat"] as? Double ?? 0
    )
}

private func decodeMealTemplate(_ d: [String: Any]) -> MealTemplate? {
    guard let id = d["id"] as? String else { return nil }
    return MealTemplate(
        id: id, name: d["name"] as? String ?? "",
        description: d["description"] as? String,
        origin: (d["origin"] as? String).flatMap(TemplateOrigin.init(rawValue:)) ?? .user,
        createdAt: date(d, "createdAt") ?? .now,
        updatedAt: date(d, "updatedAt") ?? .now
    )
}

private func decodeMealTemplateItem(_ d: [String: Any]) -> MealTemplateItem? {
    guard let id = d["id"] as? String else { return nil }
    return MealTemplateItem(
        id: id, templateId: d["templateId"] as? String ?? "",
        foodId: d["foodId"] as? String ?? "",
        amount: d["amount"] as? Double ?? 0
    )
}

private func decodeExercise(_ d: [String: Any]) -> Exercise? {
    guard let id = d["id"] as? String else { return nil }
    return Exercise(
        id: id, name: d["name"] as? String ?? "",
        primaryMuscle: d["primaryMuscle"] as? String,
        unit: d["unit"] as? String ?? "kg",
        notes: d["notes"] as? String,
        equipment: Set((d["equipment"] as? [String] ?? []).compactMap(Equipment.init(rawValue:))),
        contraindicatedFor: Set((d["contraindicatedFor"] as? [String] ?? []).compactMap(BodyPart.init(rawValue:))),
        rehabFor: Set((d["rehabFor"] as? [String] ?? []).compactMap(BodyPart.init(rawValue:))),
        movementPattern: (d["movementPattern"] as? String).flatMap(MovementPattern.init(rawValue:)),
        mechanic: (d["mechanic"] as? String).flatMap(Mechanic.init(rawValue:)),
        loadClass: (d["loadClass"] as? String).flatMap(LoadClass.init(rawValue:))
    )
}

private func decodeWorkoutTemplate(_ d: [String: Any]) -> WorkoutTemplate? {
    guard let id = d["id"] as? String else { return nil }
    return WorkoutTemplate(
        id: id, name: d["name"] as? String ?? "",
        notes: d["notes"] as? String,
        origin: (d["origin"] as? String).flatMap(TemplateOrigin.init(rawValue:)) ?? .user,
        customRest: d["customRest"] as? Bool ?? false
    )
}

private func decodeTemplateExercise(_ d: [String: Any]) -> TemplateExercise? {
    guard let id = d["id"] as? String else { return nil }
    return TemplateExercise(
        id: id, templateId: d["templateId"] as? String ?? "",
        exerciseId: d["exerciseId"] as? String ?? "",
        orderIndex: d["orderIndex"] as? Int ?? 0,
        defaultSets: d["defaultSets"] as? Int ?? 3,
        defaultReps: d["defaultReps"] as? Int,
        defaultWeight: d["defaultWeight"] as? Double,
        defaultRestSeconds: d["defaultRestSeconds"] as? Int,
        isRest: d["isRest"] as? Bool ?? false
    )
}

private func decodeWorkoutSession(_ d: [String: Any]) -> WorkoutSession? {
    guard let id = d["id"] as? String else { return nil }
    return WorkoutSession(
        id: id, templateId: d["templateId"] as? String,
        startedAt: date(d, "startedAt") ?? .now,
        endedAt: date(d, "endedAt"),
        note: d["note"] as? String,
        sourceEventId: d["sourceEventId"] as? String
    )
}

private func decodeSetEntry(_ d: [String: Any]) -> SetEntry? {
    guard let id = d["id"] as? String else { return nil }
    return SetEntry(
        id: id, sessionId: d["sessionId"] as? String ?? "",
        exerciseId: d["exerciseId"] as? String ?? "",
        orderIndex: d["orderIndex"] as? Int ?? 0,
        reps: d["reps"] as? Int ?? 0,
        weight: d["weight"] as? Double,
        restSeconds: d["restSeconds"] as? Int
    )
}

private func decodeSleepEntry(_ d: [String: Any]) -> SleepEntry? {
    guard let id = d["id"] as? String else { return nil }
    return SleepEntry(
        id: id, startedAt: date(d, "startedAt") ?? .now,
        endedAt: date(d, "endedAt"),
        quality: d["quality"] as? Int,
        note: d["note"] as? String,
        sourceEventId: d["sourceEventId"] as? String
    )
}

private func decodeBodyWeightEntry(_ d: [String: Any]) -> BodyWeightEntry? {
    guard let id = d["id"] as? String else { return nil }
    return BodyWeightEntry(
        id: id, recordedAt: date(d, "recordedAt") ?? .now,
        kg: d["kg"] as? Double ?? 0,
        note: d["note"] as? String
    )
}

private func decodeScheduledEvent(_ d: [String: Any]) -> ScheduledEvent? {
    guard let id = d["id"] as? String else { return nil }
    return ScheduledEvent(
        id: id, title: d["title"] as? String ?? "",
        description: d["description"] as? String,
        type: (d["type"] as? String).flatMap(EventType.init(rawValue:)) ?? .meal,
        scheduledAt: date(d, "scheduledAt") ?? .now,
        completedAt: date(d, "completedAt"),
        status: (d["status"] as? String).flatMap(EventStatus.init(rawValue:)) ?? .planned,
        recurrenceType: (d["recurrenceType"] as? String).flatMap(RecurrenceType.init(rawValue:)) ?? .none,
        recurrenceDays: d["recurrenceDays"] as? [Int] ?? [],
        customInterval: d["customInterval"] as? Int,
        recurrenceEndDate: date(d, "recurrenceEndDate"),
        templateId: d["templateId"] as? String
    )
}
