#if DEBUG
import Foundation
import WellnessModels
import WellnessCatalog
import WellnessDomain
import WellnessPersistence

public struct DemoSeedService: Sendable {
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
    private let prefs: Preferences

    public static let historyDays = 183

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
        prefs: Preferences
    ) {
        self.food = food; self.meal = meal; self.mealTemplate = mealTemplate
        self.exercise = exercise; self.workoutTemplate = workoutTemplate
        self.workoutSession = workoutSession; self.sleep = sleep
        self.bodyWeight = bodyWeight; self.event = event
        self.profile = profile; self.prefs = prefs
    }

    public func seed() async throws {
        let p = seedProfile()
        try await profile.saveProfile(p)

        prefs.calorieGoal = Double(p.calorieTarget)
        prefs.proteinGoal = Double(p.proteinTargetG)
        prefs.carbsGoal = Double(p.carbsTargetG)
        prefs.fatGoal = Double(p.fatTargetG)

        try await seedCatalog()
        try await generatePlan(p)
        try await applyEdits()
        try await seedHistory(p)
        try await verifyBackupRoundTrip()
    }

    // MARK: - Profile

    private func seedProfile() -> UserProfile {
        SetupEngine.createUserProfile(
            sex: "male", ageYears: 31, heightCm: 180, weightKg: 82.5,
            goal: "muscle_gain", activityLevel: "moderate",
            trainingDaysPerWeek: 4, trainingExperience: "intermediate",
            equipment: ["dumbbells", "barbell_rack", "pullup_bar", "bands"],
            dietType: "omnivore", mealCountPerDay: "4",
            exclusions: ["shellfish"], injuries: ["shoulder"],
            energyUnit: "kcal", weightUnit: "g"
        )
    }

    // MARK: - Catalog

    private func seedCatalog() async throws {
        let language: AppLanguage = .english
        for starter in Catalog.foods {
            try await food.insertFood(starter.toFoodItem(language: language))
        }
        for starter in Catalog.exercises {
            try await exercise.insertExercise(starter.toExercise(language: language))
        }
    }

    // MARK: - Plan

    private func generatePlan(_ p: UserProfile) async throws {
        let language: AppLanguage = .english
        let allFoods = try await food.allFoods()
        let allExercises = try await exercise.allExercises()

        let catalogNameById = Dictionary(
            uniqueKeysWithValues: Catalog.foods.map { ($0.id, $0.name) }
        )

        let workoutGen = WorkoutTemplateGenerator(profile: p, language: language)
        let workoutResults = workoutGen.generateTemplates(
            allExercises: allExercises, makeId: { UUID().uuidString }
        )
        for (template, exercises) in workoutResults {
            var t = template
            t.exercises = exercises
            try await workoutTemplate.insertWorkoutTemplate(t)
            for ex in exercises {
                try await workoutTemplate.insertTemplateExercise(ex)
            }
        }

        let mealGen = MealTemplateGenerator(profile: p, language: language)
        let mealResults = mealGen.generateTemplates(
            availableFoods: allFoods, catalogNameById: catalogNameById,
            makeId: { UUID().uuidString }
        )
        for result in mealResults {
            var t = result.template
            t.items = result.items
            try await mealTemplate.insertMealTemplate(t)
            for item in result.items {
                try await mealTemplate.insertMealTemplateItem(item)
            }
        }

        let wRefs = workoutResults.map {
            CalendarScheduleGenerator.WorkoutTemplateRef(
                id: $0.0.id, name: $0.0.name, origin: $0.0.origin
            )
        }
        let mRefs = mealResults.map {
            CalendarScheduleGenerator.MealTemplateRef(
                id: $0.template.id, name: $0.template.name, origin: $0.template.origin
            )
        }
        let calGen = CalendarScheduleGenerator(profile: p, language: language)
        let events = calGen.buildSchedule(
            workoutTemplates: wRefs, mealTemplates: mRefs,
            makeId: { UUID().uuidString }
        )
        for ev in events {
            try await event.insertScheduledEvent(ev)
        }
    }

    // MARK: - Edits

    private func applyEdits() async throws {
        let templates = try await workoutTemplate.allWorkoutTemplates()
        guard let first = templates.first else { return }

        var updated = first
        updated.customRest = true
        try await workoutTemplate.updateWorkoutTemplate(updated)

        let rows = try await workoutTemplate.templateExercises(byTemplateId: first.id)
        if rows.count >= 3 {
            for row in rows {
                try await workoutTemplate.deleteTemplateExercise(id: row.id)
            }
            var rebuilt: [TemplateExercise] = []
            for (i, row) in rows.enumerated() {
                rebuilt.append(reindex(row, index: rebuilt.count))
                if i == 0 || i == rows.count / 2 {
                    rebuilt.append(TemplateExercise(
                        id: UUID().uuidString, templateId: first.id,
                        exerciseId: "", orderIndex: rebuilt.count,
                        defaultSets: 0, defaultRestSeconds: i == 0 ? 90 : 210,
                        isRest: true
                    ))
                }
            }
            for row in rebuilt {
                try await workoutTemplate.insertTemplateExercise(row)
            }
        }

        if templates.count > 1 {
            let second = templates[1]
            let sRows = try await workoutTemplate.templateExercises(byTemplateId: second.id)
            if let first = sRows.first {
                var u = first
                u.defaultSets = 5; u.defaultReps = 5; u.defaultWeight = 92.5
                u.defaultRestSeconds = 225
                try await workoutTemplate.updateTemplateExercise(u)
            }
            if sRows.count > 1 {
                var u = sRows[1]
                u.defaultSets = 3; u.defaultReps = 15
                u.defaultWeight = nil; u.defaultRestSeconds = nil
                try await workoutTemplate.updateTemplateExercise(u)
            }
        }

        try await food.insertFood(FoodItem(
            id: "demo-user-food", name: "Nonna's Lasagne", brand: "Home",
            unit: "100g", kcalPerUnit: 182, proteinPerUnit: 11.4,
            carbsPerUnit: 14.2, fatPerUnit: 8.9
        ))
        try await exercise.insertExercise(Exercise(
            id: "demo-user-exercise", name: "Sandbag Carry",
            primaryMuscle: "Full Body", unit: "kg",
            notes: "Added by hand — tests the user-created exercise path."
        ))
    }

    private func reindex(_ row: TemplateExercise, index: Int) -> TemplateExercise {
        var r = row; r.orderIndex = index; return r
    }

    // MARK: - History

    private func seedHistory(_ p: UserProfile) async throws {
        let templates = try await workoutTemplate.allWorkoutTemplates()
        let mealTemplates = try await mealTemplate.allMealTemplates()
        let today = Date()
        let cal = Calendar.current
        var rng = SeededRNG(seed: 20260809)

        for daysAgo in stride(from: Self.historyDays, through: 0, by: -1) {
            let day = cal.date(byAdding: .day, value: -daysAgo, to: cal.startOfDay(for: today))!
            let progress = 1.0 - Double(daysAgo) / Double(Self.historyDays)
            let isToday = daysAgo == 0
            let skipped = !isToday && rng.nextInt(bound: 14) == 0

            if !skipped && !mealTemplates.isEmpty {
                try await seedDayMeals(day, mealTemplates, p, alwaysOnTarget: isToday, rng: &rng)
            }
            if !skipped && !templates.isEmpty && (isToday || trainsOn(day)) {
                try await seedSession(day, templates, progress, rng: &rng)
            }
            if !skipped {
                try await seedNight(day, guaranteedGood: isToday, rng: &rng)
            }
            if cal.component(.weekday, from: day) == 2 { // Monday
                let bw = BodyWeightEntry(
                    id: UUID().uuidString,
                    recordedAt: cal.date(bySettingHour: 7, minute: 30, second: 0, of: day)!,
                    kg: p.weightKg - 4.5 + progress * 4.5 + (rng.nextDouble() - 0.5) * 0.6
                )
                try await bodyWeight.insertBodyWeightEntry(bw)
            }
        }
    }

    private func trainsOn(_ day: Date) -> Bool {
        let wd = Calendar.current.component(.weekday, from: day)
        return [2, 3, 5, 6].contains(wd) // Mon, Tue, Thu, Fri
    }

    private func seedDayMeals(
        _ day: Date, _ templates: [MealTemplate], _ p: UserProfile,
        alwaysOnTarget: Bool, rng: inout SeededRNG
    ) async throws {
        let cal = Calendar.current
        let dateInt = cal.component(.year, from: day) * 10000
            + cal.component(.month, from: day) * 100
            + cal.component(.day, from: day)

        let missed = !alwaysOnTarget && rng.nextInt(bound: 5) == 0
        let factor = missed
            ? 0.78 + rng.nextDouble() * 0.15
            : 0.98 + rng.nextDouble() * 0.14
        let targetKcal = Double(p.calorieTarget) * factor

        struct PlannedItem {
            let mealName: String; let at: Date; let food: FoodItem; let amount: Double
        }
        var planned: [PlannedItem] = []
        let mealCount = 3 + rng.nextInt(bound: 2)
        for i in 0..<mealCount {
            let template = templates[rng.nextInt(bound: templates.count)]
            let at = cal.date(bySettingHour: 8 + i * 4, minute: rng.nextInt(bound: 60), second: 0, of: day)!
            for item in template.items {
                if let f = try await food.food(byId: item.foodId) {
                    planned.append(PlannedItem(
                        mealName: template.name, at: at, food: f,
                        amount: item.amount * (0.9 + rng.nextDouble() * 0.2)
                    ))
                }
            }
        }
        guard !planned.isEmpty else { return }

        let rawKcal = planned.reduce(0.0) { $0 + $1.food.kcalPerUnit * $1.amount }
        let scale = rawKcal <= 0 ? 1.0 : targetKcal / rawKcal

        var byMeal: [Date: String] = [:]
        for p in planned {
            var mealId = byMeal[p.at]
            if mealId == nil {
                mealId = UUID().uuidString
                byMeal[p.at] = mealId
                try await meal.insertMeal(Meal(
                    id: mealId!, date: dateInt, name: p.mealName,
                    createdAt: p.at, updatedAt: p.at, loggedAt: p.at
                ))
            }
            let amount = p.amount * scale
            try await meal.insertMealItem(MealItem(
                id: UUID().uuidString, mealId: mealId!,
                foodId: p.food.id, amount: amount,
                kcal: p.food.kcalPerUnit * amount,
                protein: p.food.proteinPerUnit * amount,
                carbs: p.food.carbsPerUnit * amount,
                fat: p.food.fatPerUnit * amount
            ))
        }
    }

    private func seedSession(
        _ day: Date, _ templates: [WorkoutTemplate],
        _ progress: Double, rng: inout SeededRNG
    ) async throws {
        let cal = Calendar.current
        let ref = Calendar.current.dateComponents([.day], from: Date(timeIntervalSinceReferenceDate: 0), to: day).day ?? 0
        let template = templates[ref % templates.count]
        let rows = try await workoutTemplate.templateExercises(byTemplateId: template.id)
        guard !rows.isEmpty else { return }

        let startedAt = cal.date(bySettingHour: 18, minute: rng.nextInt(bound: 40), second: 0, of: day)!
        let sessionId = UUID().uuidString
        var sets: [SetEntry] = []
        var order = 0

        for row in rows where !row.isRest {
            guard let _ = try await exercise.exercise(byId: row.exerciseId) else { continue }
            for setIndex in 0..<row.defaultSets {
                let reps = row.defaultReps ?? 10
                let base = row.defaultWeight
                sets.append(SetEntry(
                    id: UUID().uuidString, sessionId: sessionId,
                    exerciseId: row.exerciseId, orderIndex: order,
                    reps: setIndex == row.defaultSets - 1
                        ? max(1, reps - rng.nextInt(bound: 2))
                        : reps,
                    weight: base.map { (($0 * (0.75 + progress * 0.35)) / 2.5).rounded() * 2.5 },
                    restSeconds: resolveRestSeconds(
                        explicitSeconds: row.defaultRestSeconds,
                        reps: row.defaultReps,
                        globalDefaultSeconds: 90
                    )
                ))
                order += 1
            }
        }

        let endedAt = startedAt.addingTimeInterval(Double(45 + rng.nextInt(bound: 30)) * 60)
        try await workoutSession.insertWorkoutSession(WorkoutSession(
            id: sessionId, templateId: template.id,
            startedAt: startedAt, endedAt: endedAt, sets: sets
        ))
        for s in sets {
            try await workoutSession.insertSetEntry(s)
        }
    }

    private func seedNight(_ day: Date, guaranteedGood: Bool, rng: inout SeededRNG) async throws {
        let cal = Calendar.current
        let bedtime = cal.date(byAdding: .day, value: -1, to: cal.date(
            bySettingHour: 22, minute: rng.nextInt(bound: 120), second: 0, of: day
        )!)!
        let hours = guaranteedGood
            ? 8.0 + rng.nextDouble() * 0.5
            : 6.0 + rng.nextDouble() * 2.5
        let entry = SleepEntry(
            id: UUID().uuidString, startedAt: bedtime,
            endedAt: bedtime.addingTimeInterval(hours * 3600),
            quality: 2 + rng.nextInt(bound: 4)
        )
        try await sleep.insertSleepEntry(entry)
    }

    // MARK: - Round-trip

    private func verifyBackupRoundTrip() async throws {
        let backup = BackupService(
            food: food, meal: meal, mealTemplate: mealTemplate,
            exercise: exercise, workoutTemplate: workoutTemplate,
            workoutSession: workoutSession, sleep: sleep,
            bodyWeight: bodyWeight, event: event, profile: profile,
            prefs: prefs
        )
        let before = try await backup.rowCounts()
        let json = try await backup.exportToJSON()

        // Import into the same stores (idempotent due to unique constraints)
        try await backup.importFromJSON(json)
        let after = try await backup.rowCounts()

        if before != after {
            print("[DEMO] BACKUP ROUND-TRIP MISMATCH: \(before) vs \(after)")
        }
    }
}

// MARK: - Deterministic RNG

struct SeededRNG: Sendable {
    private var state: UInt64

    init(seed: UInt64) { self.state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func nextInt(bound: Int) -> Int {
        guard bound > 0 else { return 0 }
        return Int(next() % UInt64(bound))
    }

    mutating func nextDouble() -> Double {
        Double(next() & 0x1F_FFFF_FFFF_FFFF) / Double(1 << 53)
    }
}
#endif
