import Foundation
import WellnessModels

public struct WorkoutTemplateGenerator: Sendable {
    public let profile: UserProfile
    public let language: AppLanguage

    public init(profile: UserProfile, language: AppLanguage) {
        self.profile = profile
        self.language = language
    }

    private func text(_ english: String, _ hebrew: String) -> String {
        language == .hebrew ? hebrew : english
    }

    // MARK: - Muscle groups

    private static let push = ["Chest", "Shoulders", "Triceps"]
    private static let pull = ["Back", "Biceps"]
    private static let legs = ["Quadriceps", "Hamstrings", "Glutes", "Calves"]
    private static let core = ["Core"]
    private static let allTrained = push + pull + legs + core

    // MARK: - Movement patterns

    private static let pushPatterns: [MovementPattern] = [.horizontalPush, .verticalPush]
    private static let pullPatterns: [MovementPattern] = [.horizontalPull, .verticalPull]
    private static let legPatterns: [MovementPattern] = [.squat, .hinge, .lunge]
    private static let corePatterns: [MovementPattern] = [.coreBrace]

    private static let allPatterns: [MovementPattern] = [
        .squat, .horizontalPush, .horizontalPull, .hinge,
        .verticalPush, .verticalPull, .lunge, .coreBrace,
    ]

    // MARK: - Generate

    public func generateTemplates(
        allExercises: [Exercise],
        makeId: () -> String
    ) -> [(template: WorkoutTemplate, exercises: [TemplateExercise])] {
        let available = allExercises.filter { ProfileFit.exerciseFits($0, profile) }
        if available.isEmpty { return [] }

        let scheme = WorkoutProgramming.schemeFor(profile.goal)
        let perSession = WorkoutProgramming.exerciseBudget(scheme)

        var results: [(WorkoutTemplate, [TemplateExercise])] = []
        var allPicked: Set<String> = []

        let plan = Self.sessionsFor(profile.trainingDaysPerWeek)
        for day in plan {
            let picks = Self.pick(
                available: available,
                patterns: day.patterns,
                muscles: day.muscles,
                count: perSession,
                variant: day.variant
            )
            if picks.isEmpty { continue }

            let templateId = makeId()
            let template = WorkoutTemplate(
                id: templateId,
                name: text(day.name, day.nameHe),
                notes: text(day.notes, day.notesHe) + "\n\n" + progressionNote(scheme),
                origin: .generated
            )

            var templateExercises: [TemplateExercise] = []
            for (i, exercise) in picks.enumerated() {
                if let m = exercise.primaryMuscle { allPicked.insert(m) }
                templateExercises.append(TemplateExercise(
                    id: makeId(),
                    templateId: templateId,
                    exerciseId: exercise.id,
                    orderIndex: i,
                    defaultSets: scheme.sets,
                    defaultReps: scheme.reps,
                    defaultWeight: WorkoutProgramming.startingWeightKg(
                        loadClass: exercise.loadClassOrDefault,
                        unit: exercise.unit,
                        bodyweightKg: profile.weightKg,
                        sex: profile.sex,
                        experience: profile.trainingExperience,
                        ageYears: profile.ageYears,
                        reps: scheme.reps
                    ),
                    defaultRestSeconds: scheme.restFor(exercise.mechanicOrDefault)
                ))
            }
            results.append((template, templateExercises))
        }

        let rehabScheme = WorkoutProgramming.schemeFor("mobility_rehab")
        for injury in profile.injuries {
            guard let part = BodyPart.forProfileId(injury) else { continue }
            let rehab = allExercises.filter {
                $0.rehabFor.contains(part) && ProfileFit.exerciseFits($0, profile)
            }
            if rehab.isEmpty { continue }

            let templateId = makeId()
            let template = WorkoutTemplate(
                id: templateId,
                name: text(
                    "Physiotherapy — \(part.label(.english))",
                    "פיזיותרפיה — \(part.label(.hebrew))"
                ),
                notes: text(
                    "Rehab work for your \(part.label(.english).lowercased()). Low load; safe on a rest day.",
                    "עבודת שיקום ל\(part.label(.hebrew)). עומס נמוך; בטוח ליום מנוחה."
                ) + "\n\n" + progressionNote(rehabScheme),
                origin: .generated
            )

            var templateExercises: [TemplateExercise] = []
            for (i, exercise) in rehab.prefix(5).enumerated() {
                templateExercises.append(TemplateExercise(
                    id: makeId(),
                    templateId: templateId,
                    exerciseId: exercise.id,
                    orderIndex: i,
                    defaultSets: rehabScheme.sets,
                    defaultReps: rehabScheme.reps,
                    defaultWeight: WorkoutProgramming.startingWeightKg(
                        loadClass: exercise.loadClassOrDefault,
                        unit: exercise.unit,
                        bodyweightKg: profile.weightKg,
                        sex: profile.sex,
                        experience: profile.trainingExperience,
                        ageYears: profile.ageYears,
                        reps: rehabScheme.reps
                    ),
                    defaultRestSeconds: rehabScheme.restFor(exercise.mechanicOrDefault)
                ))
            }
            results.append((template, templateExercises))
        }

        return results
    }

    // MARK: - Progression note

    private func progressionNote(_ scheme: RepScheme) -> String {
        text(
            "Leave \(scheme.repsInReserve) rep(s) in reserve on every set. "
            + "When you hit \(scheme.reps) reps on all \(scheme.sets) sets, add "
            + "2.5kg upper body / 5kg lower body next time. "
            + "Weights shown are a starting estimate -- adjust on your first set.",
            "השאירו \(scheme.repsInReserve) חזרות במלאי בכל סט. "
            + "כשתגיעו ל-\(scheme.reps) חזרות בכל \(scheme.sets) הסטים, הוסיפו "
            + "2.5 ק\"ג בפלג הגוף העליון / 5 ק\"ג בתחתון בפעם הבאה. "
            + "המשקלים המוצגים הם הערכת פתיחה -- התאימו אותם בסט הראשון."
        )
    }

    // MARK: - Session plans

    private struct SessionPlan {
        let name: String
        let notes: String
        let patterns: [MovementPattern]
        let muscles: [String]
        let nameHe: String
        let notesHe: String
        let variant: Int

        init(
            _ name: String, _ notes: String,
            _ patterns: [MovementPattern], _ muscles: [String],
            nameHe: String, notesHe: String, variant: Int = 0
        ) {
            self.name = name; self.notes = notes
            self.patterns = patterns; self.muscles = muscles
            self.nameHe = nameHe; self.notesHe = notesHe
            self.variant = variant
        }
    }

    private static func sessionsFor(_ days: Int) -> [SessionPlan] {
        let count = min(max(days, 1), 7)
        switch count {
        case 1:
            return [
                SessionPlan("Full Body", "Everything, once a week", allPatterns, allTrained,
                            nameHe: "אימון גוף מלא", notesHe: "הכול, פעם בשבוע"),
            ]
        case 2:
            return [
                SessionPlan("Full Body A", "Every major pattern", allPatterns, allTrained,
                            nameHe: "גוף מלא א", notesHe: "כל דפוסי התנועה המרכזיים"),
                SessionPlan("Full Body B", "Same coverage, different lifts", allPatterns, allTrained,
                            nameHe: "גוף מלא ב", notesHe: "אותו כיסוי, תרגילים אחרים", variant: 1),
            ]
        case 3:
            return [
                SessionPlan("Full Body A", "Every major pattern", allPatterns, allTrained,
                            nameHe: "גוף מלא א", notesHe: "כל דפוסי התנועה המרכזיים"),
                SessionPlan("Full Body B", "Same coverage, different lifts", allPatterns, allTrained,
                            nameHe: "גוף מלא ב", notesHe: "אותו כיסוי, תרגילים אחרים", variant: 1),
                SessionPlan("Full Body C", "Third variation to keep it fresh", allPatterns, allTrained,
                            nameHe: "גוף מלא ג", notesHe: "וריאציה שלישית לשמירה על גיוון", variant: 2),
            ]
        case 4:
            return [
                SessionPlan("Upper Body A", "Chest, back, shoulders and arms",
                            pushPatterns + pullPatterns, push + pull,
                            nameHe: "פלג גוף עליון א", notesHe: "חזה, גב, כתפיים וידיים"),
                SessionPlan("Lower Body A", "Legs and trunk",
                            legPatterns + corePatterns, legs + core,
                            nameHe: "פלג גוף תחתון א", notesHe: "רגליים וליבה"),
                SessionPlan("Upper Body B", "Upper body, second variation",
                            pullPatterns + pushPatterns, pull + push,
                            nameHe: "פלג גוף עליון ב", notesHe: "פלג גוף עליון, וריאציה שנייה", variant: 1),
                SessionPlan("Lower Body B", "Lower body, second variation",
                            legPatterns + corePatterns, legs + core,
                            nameHe: "פלג גוף תחתון ב", notesHe: "פלג גוף תחתון, וריאציה שנייה", variant: 1),
            ]
        case 5:
            return [
                SessionPlan("Upper Body", "Chest, back, shoulders and arms",
                            pushPatterns + pullPatterns, push + pull,
                            nameHe: "פלג גוף עליון", notesHe: "חזה, גב, כתפיים וידיים"),
                SessionPlan("Lower Body", "Legs and trunk",
                            legPatterns + corePatterns, legs + core,
                            nameHe: "פלג גוף תחתון", notesHe: "רגליים וליבה"),
                SessionPlan("Push Day", "Chest, shoulders and triceps",
                            pushPatterns, push,
                            nameHe: "אימון דחיפה", notesHe: "חזה, כתפיים ותלת-ראשי"),
                SessionPlan("Pull Day", "Back and biceps",
                            pullPatterns, pull,
                            nameHe: "אימון משיכה", notesHe: "גב ודו-ראשי"),
                SessionPlan("Leg Day", "Quads, hamstrings, glutes and trunk",
                            legPatterns + corePatterns, legs + core,
                            nameHe: "אימון רגליים", notesHe: "ארבע-ראשי, ירך אחורית, ישבן וליבה", variant: 1),
            ]
        case 6:
            return [
                SessionPlan("Push Day A", "Chest, shoulders and triceps", pushPatterns, push,
                            nameHe: "אימון דחיפה א", notesHe: "חזה, כתפיים ותלת-ראשי"),
                SessionPlan("Pull Day A", "Back and biceps", pullPatterns, pull,
                            nameHe: "אימון משיכה א", notesHe: "גב ודו-ראשי"),
                SessionPlan("Leg Day A", "Quads, hamstrings, glutes and trunk",
                            legPatterns + corePatterns, legs + core,
                            nameHe: "אימון רגליים א", notesHe: "ארבע-ראשי, ירך אחורית, ישבן וליבה"),
                SessionPlan("Push Day B", "Push, second variation", pushPatterns, push,
                            nameHe: "אימון דחיפה ב", notesHe: "דחיפה, וריאציה שנייה", variant: 1),
                SessionPlan("Pull Day B", "Pull, second variation", pullPatterns, pull,
                            nameHe: "אימון משיכה ב", notesHe: "משיכה, וריאציה שנייה", variant: 1),
                SessionPlan("Leg Day B", "Legs, second variation",
                            legPatterns + corePatterns, legs + core,
                            nameHe: "אימון רגליים ב", notesHe: "רגליים, וריאציה שנייה", variant: 1),
            ]
        default:
            return [
                SessionPlan("Push Day A", "Chest, shoulders and triceps", pushPatterns, push,
                            nameHe: "אימון דחיפה א", notesHe: "חזה, כתפיים ותלת-ראשי"),
                SessionPlan("Pull Day A", "Back and biceps", pullPatterns, pull,
                            nameHe: "אימון משיכה א", notesHe: "גב ודו-ראשי"),
                SessionPlan("Leg Day A", "Quads, hamstrings, glutes and trunk",
                            legPatterns + corePatterns, legs + core,
                            nameHe: "אימון רגליים א", notesHe: "ארבע-ראשי, ירך אחורית, ישבן וליבה"),
                SessionPlan("Push Day B", "Push, second variation", pushPatterns, push,
                            nameHe: "אימון דחיפה ב", notesHe: "דחיפה, וריאציה שנייה", variant: 1),
                SessionPlan("Pull Day B", "Pull, second variation", pullPatterns, pull,
                            nameHe: "אימון משיכה ב", notesHe: "משיכה, וריאציה שנייה", variant: 1),
                SessionPlan("Leg Day B", "Legs, second variation",
                            legPatterns + corePatterns, legs + core,
                            nameHe: "אימון רגליים ב", notesHe: "רגליים, וריאציה שנייה", variant: 1),
                SessionPlan("Mobility & Core", "Light trunk and mobility work",
                            corePatterns, core,
                            nameHe: "ניידות וליבה", notesHe: "עבודת ליבה וניידות קלה"),
            ]
        }
    }

    // MARK: - Exercise selection

    private static func rotated(_ options: [Exercise], round: Int, variant: Int) -> Exercise? {
        if options.isEmpty || round >= options.count { return nil }
        return options[(round + variant) % options.count]
    }

    static func pick(
        available: [Exercise],
        patterns: [MovementPattern],
        muscles: [String],
        count: Int,
        variant: Int
    ) -> [Exercise] {
        let isolationSlots = min(max((count + 1) / 3, 1), count - 1)
        let compoundCap = count - isolationSlots

        func ofPattern(_ p: MovementPattern, _ m: Mechanic) -> [Exercise] {
            available
                .filter { $0.pattern == p && $0.mechanicOrDefault == m }
                .sorted { ($0.unit == "kg" ? 0 : 1) < ($1.unit == "kg" ? 0 : 1) }
        }

        func isolationFor(_ muscle: String) -> [Exercise] {
            available
                .filter { $0.mechanicOrDefault == .isolation && $0.primaryMuscle == muscle }
                .sorted { ($0.unit == "kg" ? 0 : 1) < ($1.unit == "kg" ? 0 : 1) }
        }

        var picked: [Exercise] = []

        func takeCompoundRound(_ round: Int, cap: Int? = nil) {
            for pattern in patterns {
                if picked.count >= count { return }
                if let cap, picked.count >= cap { return }
                let options = ofPattern(pattern, .compound)
                if let choice = rotated(options, round: round, variant: variant),
                   !picked.contains(where: { $0.id == choice.id }) {
                    picked.append(choice)
                }
            }
        }

        func takeIsolationRound(_ round: Int) {
            for muscle in muscles {
                if picked.count >= count { return }
                let options = isolationFor(muscle)
                if let choice = rotated(options, round: round, variant: variant),
                   !picked.contains(where: { $0.id == choice.id }) {
                    picked.append(choice)
                }
            }
        }

        takeCompoundRound(0, cap: compoundCap)
        takeIsolationRound(0)

        for round in 1..<4 where picked.count < count {
            takeCompoundRound(round)
            takeIsolationRound(round)
        }

        if picked.count < count {
            for exercise in available {
                if picked.count >= count { break }
                if !picked.contains(where: { $0.id == exercise.id }) {
                    picked.append(exercise)
                }
            }
        }

        picked.sort {
            WorkoutProgramming.orderRank($0.pattern, $0.mechanicOrDefault)
            < WorkoutProgramming.orderRank($1.pattern, $1.mechanicOrDefault)
        }
        return picked
    }
}
