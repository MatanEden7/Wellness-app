import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/app_language.dart';
import '../data/db/drift_database.dart';
import '../features/calendar/data/calendar_service.dart';
import '../features/workouts/domain/rest_time.dart';
import '../services/calendar_schedule_generator.dart';
import '../services/export_import_service.dart';
import '../services/meal_template_generator.dart';
import '../services/preferences_service.dart';
import '../services/setup_engine_service.dart';
import '../services/user_profile_service.dart';
import '../services/workout_template_generator.dart';

/// Builds a full, known dataset for hand-testing, and proves it survives a
/// backup round-trip.
///
/// Enabled with `--dart-define=DEMO_SEED=true`; it is a no-op otherwise, so
/// release builds never touch it. Every run **wipes and reseeds**, so each
/// build lands on an identical, predictable app -- the point is to know
/// exactly what every screen should show before you look at it.
///
/// The plan itself is not invented here. It comes from the same three
/// generators onboarding runs, driven by the same [SetupEngineService]
/// profile, so what you are testing is the app's own output. Only after that
/// does this layer on history and a handful of deliberate edits -- the cases
/// a freshly generated plan does not contain and therefore cannot exercise.
class DemoSeedService {
  DemoSeedService(this._database, this._prefs, this._calendarService);

  final AppDatabase _database;
  final SharedPreferences _prefs;
  final CalendarService _calendarService;

  static const _uuid = Uuid();

  /// Fixed seed: the same "random" history every build. A dataset that
  /// changes shape on every launch cannot be described in a test checklist.
  final _random = Random(20260809);

  /// How far back the history runs. Six months so the analytics 6M range and
  /// the strength-progress charts have something real to draw.
  static const historyDays = 183;

  static bool get isEnabled =>
      const String.fromEnvironment('DEMO_SEED') == 'true';

  Future<void> seed() async {
    final stopwatch = Stopwatch()..start();
    debugPrint('[DEMO] wiping and reseeding...');

    await _wipe();
    final profile = await _seedProfile();
    await _generatePlan(profile);
    await _applyEdits();
    await _seedHistory(profile);
    await _verifyBackupRoundTrip();

    debugPrint('[DEMO] done in ${stopwatch.elapsedMilliseconds}ms');
  }

  // ------------------------------------------------------------------ wipe

  Future<void> _wipe() async {
    // resetToFactoryState, not clearAllData: the latter leaves the food and
    // exercise catalogs empty, and nothing can be logged against nothing.
    await _database.resetToFactoryState();
    await _calendarService.clearAllEvents();
  }

  // --------------------------------------------------------------- profile

  Future<UserProfile> _seedProfile() async {
    final engine = SetupEngineService();
    await engine.initialize();

    // A profile with something in every axis: equipment across several
    // classes, a diet restriction, and an injury -- so the filtering,
    // substitution and rehab paths all have something to act on.
    final profile = engine.createUserProfile(
      sex: 'male',
      ageYears: 31,
      heightCm: 180,
      weightKg: 82.5,
      goal: 'muscle_gain',
      activityLevel: 'moderate',
      trainingDaysPerWeek: 4,
      trainingExperience: 'intermediate',
      equipment: const ['dumbbells', 'barbell_rack', 'pullup_bar', 'bands'],
      dietType: 'omnivore',
      mealCountPerDay: '4',
      exclusions: const ['shellfish'],
      injuries: const ['shoulder'],
      energyUnit: 'kcal',
      weightUnit: 'g',
    );

    await UserProfileService(_prefs).saveProfile(profile);

    final preferences = PreferencesService(_prefs);
    await preferences.setCalorieGoal(profile.calorieTarget);
    await preferences.setProteinGoal(profile.proteinTargetG);
    await preferences.setCarbsGoal(profile.carbsTargetG);
    await preferences.setFatGoal(profile.fatTargetG);

    return profile;
  }

  // ------------------------------------------------------------------ plan

  Future<void> _generatePlan(UserProfile profile) async {
    // The demo seed is an English fixture: it exists to populate a build for
    // screenshots and manual checks, not to exercise the language choice.
    const language = AppLanguage.english;
    await WorkoutTemplateGenerator(_database, profile, language)
        .generateTemplates();
    await MealTemplateGenerator(_database, profile, language)
        .generateTemplates();

    final schedule =
        await CalendarScheduleGenerator(_database, profile, language)
            .buildSchedule();
    for (final event in schedule) {
      await _calendarService.saveEvent(event);
    }
    debugPrint('[DEMO] generated plan + ${schedule.length} scheduled events');
  }

  // ----------------------------------------------------------------- edits

  /// The cases a freshly generated plan cannot produce on its own.
  ///
  /// Everything here exists to make some code path reachable by hand: custom
  /// breaks, an explicit odd rest, a prescribed weight, a bodyweight-only
  /// prescription, and content marked as the user's own rather than
  /// generated (which is what the "Your Foods" tab and the regeneration
  /// guard key off).
  Future<void> _applyEdits() async {
    final templates = await _database.getAllWorkoutTemplates();
    if (templates.isEmpty) return;

    // 1. First template: custom breaks, with two breaks placed mid-workout.
    final first = templates.first;
    await _database.updateWorkoutTemplate(WorkoutTemplateData(
      id: first.id,
      name: first.name,
      notes: first.notes,
      origin: first.origin,
      customRest: true,
    ));

    final rows = await _database.getTemplateExercisesByTemplateId(first.id);
    if (rows.length >= 3) {
      // Rebuilt wholesale: order index is position, so inserting anything
      // means renumbering everything after it.
      for (final row in rows) {
        await _database.deleteTemplateExercise(row.id);
      }
      final rebuilt = <TemplateExerciseData>[];
      for (var i = 0; i < rows.length; i++) {
        rebuilt.add(_reindex(rows[i], rebuilt.length));
        // A break after the first exercise and another in the middle.
        if (i == 0 || i == rows.length ~/ 2) {
          rebuilt.add(TemplateExerciseData(
            id: _uuid.v4(),
            templateId: first.id,
            exerciseId: '',
            orderIndex: rebuilt.length,
            defaultSets: 0,
            defaultRestSeconds: i == 0 ? 90 : 210,
            isRest: true,
          ));
        }
      }
      for (final row in rebuilt) {
        await _database.insertTemplateExercise(row);
      }
      debugPrint('[DEMO] "${first.name}" now has custom breaks');
    }

    // 2. Second template: an explicit odd rest and a prescribed weight on its
    //    first exercise, plus a bodyweight-only one -- so the row summary has
    //    all three shapes to render.
    if (templates.length > 1) {
      final second = templates[1];
      final rows = await _database.getTemplateExercisesByTemplateId(second.id);
      if (rows.isNotEmpty) {
        await _database.updateTemplateExercise(TemplateExerciseData(
          id: rows.first.id,
          templateId: second.id,
          exerciseId: rows.first.exerciseId,
          orderIndex: rows.first.orderIndex,
          defaultSets: 5,
          defaultReps: 5,
          defaultWeight: 92.5,
          defaultRestSeconds: 225,
        ));
      }
      if (rows.length > 1) {
        await _database.updateTemplateExercise(TemplateExerciseData(
          id: rows[1].id,
          templateId: second.id,
          exerciseId: rows[1].exerciseId,
          orderIndex: rows[1].orderIndex,
          defaultSets: 3,
          defaultReps: 15,
          // No weight and no rest: the "Bodyweight" + derived-rest row.
        ));
      }
    }

    // 3. Content the user owns, which generation must never replace.
    await _database.insertFood(FoodItemData(
      id: 'demo-user-food',
      name: 'Nonna\'s Lasagne',
      brand: 'Home',
      unit: '100g',
      kcalPerUnit: 182,
      proteinPerUnit: 11.4,
      carbsPerUnit: 14.2,
      fatPerUnit: 8.9,
      isStarter: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    await _database.insertExercise(ExerciseData(
      id: 'demo-user-exercise',
      name: 'Sandbag Carry',
      primaryMuscle: 'Full Body',
      unit: 'kg',
      notes: 'Added by hand -- tests the user-created exercise path.',
    ));
    debugPrint('[DEMO] added user-owned food + exercise');
  }

  TemplateExerciseData _reindex(TemplateExerciseData row, int index) =>
      TemplateExerciseData(
        id: row.id,
        templateId: row.templateId,
        exerciseId: row.exerciseId,
        orderIndex: index,
        defaultSets: row.defaultSets,
        defaultReps: row.defaultReps,
        defaultWeight: row.defaultWeight,
        defaultRestSeconds: row.defaultRestSeconds,
        isRest: row.isRest,
      );

  // --------------------------------------------------------------- history

  Future<void> _seedHistory(UserProfile profile) async {
    final templates = await _database.getAllWorkoutTemplates();
    final mealTemplates = await _database.getAllMealTemplates();
    final today = DateTime.now();

    var meals = 0;
    var sessions = 0;
    var nights = 0;

    for (var daysAgo = historyDays; daysAgo >= 0; daysAgo--) {
      final day = DateTime(today.year, today.month, today.day - daysAgo);
      // How far through the six months we are, 0..1 -- everything that should
      // improve over time is driven off this.
      final progress = 1 - (daysAgo / historyDays);

      // Today is always complete. The goal rings score *today* specifically,
      // so a demo that opens on a rest day with a light breakfast shows four
      // empty rings and looks broken rather than seeded.
      final isToday = daysAgo == 0;

      // A missed day every couple of weeks: a history with no gaps in it
      // cannot exercise the empty-day states or the streak logic.
      final skipped = !isToday && _random.nextInt(14) == 0;

      if (!skipped && mealTemplates.isNotEmpty) {
        meals += await _seedDayMeals(day, mealTemplates, profile,
            alwaysOnTarget: isToday);
      }
      if (!skipped && templates.isNotEmpty && (isToday || _trainsOn(day))) {
        sessions += await _seedSession(day, templates, progress);
      }
      if (!skipped) {
        nights += await _seedNight(day, guaranteedGood: isToday);
      }
      // Weekly weigh-in, trending with the goal.
      if (day.weekday == DateTime.monday) {
        await _database.insertBodyWeightEntry(BodyWeightEntryData(
          id: _uuid.v4(),
          recordedAt: DateTime(day.year, day.month, day.day, 7, 30),
          kg: profile.weightKg -
              4.5 +
              progress * 4.5 +
              (_random.nextDouble() - 0.5) * 0.6,
        ));
      }
    }

    debugPrint('[DEMO] $meals meals, $sessions sessions, $nights nights '
        'over $historyDays days');
  }

  /// Four training days a week, matching the profile.
  bool _trainsOn(DateTime day) => const {
        DateTime.monday,
        DateTime.tuesday,
        DateTime.thursday,
        DateTime.friday,
      }.contains(day.weekday);

  /// Builds a day of meals that actually lands on the calorie target.
  ///
  /// Portions used to be the template's amount ±15%, which summed to whatever
  /// it summed to -- roughly half the target, so the calorie goal was never
  /// met on any day in six months and the hero chart had no orange in it. The
  /// day is now assembled first and then scaled as a whole onto a target
  /// drawn per day, which is what makes "most days hit, some days don't" true
  /// rather than accidental.
  Future<int> _seedDayMeals(
    DateTime day,
    List<MealTemplateData> templates,
    UserProfile profile, {
    bool alwaysOnTarget = false,
  }) async {
    final date = _dateInt(day);

    // Muscle gain counts >=95% of target as a hit. Aim most days just over,
    // and let roughly one in five fall short -- a demo where every single day
    // is perfect cannot show what a missed day looks like.
    final missed = !alwaysOnTarget && _random.nextInt(5) == 0;
    final factor = missed
        ? 0.78 + _random.nextDouble() * 0.15
        : 0.98 + _random.nextDouble() * 0.14;
    final targetKcal = profile.calorieTarget * factor;

    // Assemble first, weigh, then scale.
    final planned =
        <({String mealName, DateTime at, FoodItemData food, double amount})>[];
    final mealCount = 3 + _random.nextInt(2);
    for (var i = 0; i < mealCount; i++) {
      final template = templates[_random.nextInt(templates.length)];
      final at = DateTime(
          day.year, day.month, day.day, 8 + i * 4, _random.nextInt(60));
      final items =
          await _database.getMealTemplateItemsByTemplateId(template.id);
      for (final item in items) {
        final food = await _database.getFoodById(item.foodId);
        if (food == null) continue;
        planned.add((
          mealName: template.name,
          at: at,
          food: food,
          amount: item.amount * (0.9 + _random.nextDouble() * 0.2),
        ));
      }
    }
    if (planned.isEmpty) return 0;

    final rawKcal = planned.fold<double>(
        0, (sum, p) => sum + p.food.kcalPerUnit * p.amount);
    final scale = rawKcal <= 0 ? 1.0 : targetKcal / rawKcal;

    // One Meal row per distinct sitting.
    final byMeal = <DateTime, String>{};
    var count = 0;
    for (final p in planned) {
      var mealId = byMeal[p.at];
      if (mealId == null) {
        mealId = _uuid.v4();
        byMeal[p.at] = mealId;
        await _database.insertMeal(MealData(
          id: mealId,
          date: date,
          name: p.mealName,
          note: null,
          createdAt: p.at,
          updatedAt: p.at,
          loggedAt: p.at,
        ));
        count++;
      }
      final amount = p.amount * scale;
      await _database.insertMealItem(MealItemData(
        id: _uuid.v4(),
        mealId: mealId,
        foodId: p.food.id,
        amount: amount,
        kcal: p.food.kcalPerUnit * amount,
        protein: p.food.proteinPerUnit * amount,
        carbs: p.food.carbsPerUnit * amount,
        fat: p.food.fatPerUnit * amount,
      ));
    }
    return count;
  }

  Future<int> _seedSession(
    DateTime day,
    List<WorkoutTemplateData> templates,
    double progress,
  ) async {
    // Rotate through the plan rather than picking at random, so the split
    // reads like a split.
    final template =
        templates[day.difference(DateTime(2020)).inDays % templates.length];
    final rows = await _database.getTemplateExercisesByTemplateId(template.id);
    if (rows.isEmpty) return 0;

    final startedAt =
        DateTime(day.year, day.month, day.day, 18, _random.nextInt(40));
    final sessionId = _uuid.v4();

    final sets = <SetEntryData>[];
    var order = 0;
    for (final row in rows) {
      // Breaks are planned, not performed.
      if (row.isRest) continue;
      final exercise = await _database.getExerciseById(row.exerciseId);
      if (exercise == null) continue;

      for (var setIndex = 0; setIndex < row.defaultSets; setIndex++) {
        final reps = row.defaultReps ?? 10;
        final base = row.defaultWeight;
        sets.add(SetEntryData(
          id: _uuid.v4(),
          sessionId: sessionId,
          exerciseId: exercise.id,
          orderIndex: order++,
          // Slightly fewer reps on the last set, as actually happens.
          reps: setIndex == row.defaultSets - 1
              ? (reps - _random.nextInt(2)).clamp(1, reps)
              : reps,
          // Linear progression across the six months, rounded to the plate.
          weight: base == null
              ? null
              : ((base * (0.75 + progress * 0.35)) / 2.5).round() * 2.5,
          restSeconds: resolveRestSeconds(
            explicitSeconds: row.defaultRestSeconds,
            reps: row.defaultReps,
            globalDefaultSeconds: 90,
          ),
        ));
      }
    }

    await _database.insertWorkoutSession(WorkoutSessionData(
      id: sessionId,
      templateId: template.id,
      startedAt: startedAt,
      // 45-75 minutes.
      endedAt: startedAt.add(Duration(minutes: 45 + _random.nextInt(30))),
      note: null,
    ));
    for (final set in sets) {
      await _database.insertSetEntry(set);
    }
    return 1;
  }

  Future<int> _seedNight(DateTime day, {bool guaranteedGood = false}) async {
    // Bedtime the evening before, waking on [day].
    final bedtime =
        DateTime(day.year, day.month, day.day - 1, 22, _random.nextInt(120));
    // The sleep goal is 8h with half an hour of slack, so a guaranteed-good
    // night has to clear 7.5.
    final hours = guaranteedGood
        ? 8.0 + _random.nextDouble() * 0.5
        : 6.0 + _random.nextDouble() * 2.5;
    await _database.insertSleepEntry(SleepEntryData(
      id: _uuid.v4(),
      startedAt: bedtime,
      endedAt: bedtime.add(Duration(minutes: (hours * 60).round())),
      quality: 2 + _random.nextInt(4),
    ));
    return 1;
  }

  int _dateInt(DateTime day) => day.year * 10000 + day.month * 100 + day.day;

  // ------------------------------------------------------------ round-trip

  /// Exports everything just seeded and imports it straight back.
  ///
  /// This is the part that earns its keep: it runs the real backup path over
  /// a six-month dataset on every build, so a field that silently fails to
  /// serialise shows up here rather than the first time someone restores a
  /// backup. A mismatch is logged loudly and left in place -- the app still
  /// has the data, and the point is to notice.
  Future<void> _verifyBackupRoundTrip() async {
    final service = ExportImportService(_database, _calendarService, _prefs);

    final before = await _counts();
    final json = await service.exportToJson();
    await service.importFromJson(json);
    final after = await _counts();

    if (mapEquals(before, after)) {
      debugPrint('[DEMO] backup round-trip OK: $before');
    } else {
      debugPrint('[DEMO] ⚠️ BACKUP ROUND-TRIP MISMATCH');
      for (final key in before.keys) {
        if (before[key] != after[key]) {
          debugPrint('[DEMO]   $key: ${before[key]} -> ${after[key]}');
        }
      }
    }
  }

  Future<Map<String, int>> _counts() async => {
        'foods': (await _database.getAllFoods()).length,
        'meals': (await _database.getAllMeals()).length,
        'mealTemplates': (await _database.getAllMealTemplates()).length,
        'exercises': (await _database.getAllExercises()).length,
        'workoutTemplates': (await _database.getAllWorkoutTemplates()).length,
        'sessions':
            (await _database.getRecentWorkoutSessions(limit: 100000)).length,
        'sleep': (await _database.getRecentSleepEntries(limit: 100000)).length,
        'bodyWeight':
            (await _database.getRecentBodyWeightEntries(limit: 100000)).length,
        'events': (await _calendarService.getEvents()).length,
      };
}
