// tool/parity_dump.dart
//
// Golden-corpus generator for the Swift parity tests (§9.1).
//
// Run:  flutter test tool/parity_dump.dart
//
// Writes 11 canonical JSON files to parity/golden/.
// Gate: must regenerate byte-identically twice in a row.
//
// Canonicalisation:
//   - sorted keys on every map
//   - doubles rounded to 6 decimal places
//   - UUIDs replaced with sequential parity-NNNN ids (order of first
//     appearance, deterministic because generator selection order is
//     deterministic)
//   - DateTime fields that vary per run ("now") replaced with a fixed epoch

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wellness_app/core/app_language.dart';
import 'package:wellness_app/core/date_utils.dart';
import 'package:wellness_app/data/catalog/starter_foods.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/analytics/domain/aggregators.dart';
import 'package:wellness_app/features/analytics/domain/analytics_input.dart';
import 'package:wellness_app/features/analytics/domain/analytics_range.dart';
import 'package:wellness_app/features/analytics/domain/analytics_view.dart';
import 'package:wellness_app/features/analytics/domain/goal_scoring.dart';
import 'package:wellness_app/features/analytics/domain/series.dart';
import 'package:wellness_app/features/analytics/domain/strength_progress.dart';
import 'package:wellness_app/features/calendar/data/calendar_service.dart';
import 'package:wellness_app/features/meals/domain/food_nutrition_math.dart';
import 'package:wellness_app/features/meals/domain/food_serving_kind.dart';
import 'package:wellness_app/features/meals/domain/models.dart';
import 'package:wellness_app/features/workouts/domain/exercise_tags.dart';
import 'package:wellness_app/features/workouts/domain/rest_time.dart';
import 'package:wellness_app/services/calendar_schedule_generator.dart';
import 'package:wellness_app/services/export_import_service.dart';
import 'package:wellness_app/services/meal_portion_solver.dart';
import 'package:wellness_app/services/meal_template_generator.dart';
import 'package:wellness_app/services/setup_engine_service.dart';
import 'package:wellness_app/services/user_profile_service.dart';
import 'package:wellness_app/services/workout_programming.dart';
import 'package:wellness_app/services/workout_template_generator.dart';

// ---------------------------------------------------------------------------
// Fixed epoch — replaces every DateTime.now() artefact in the output.
// ---------------------------------------------------------------------------
final _epoch = DateTime.utc(2026, 1, 1);

// ---------------------------------------------------------------------------
// Profile matrix — eight representative profiles that cover all dimensions
// the generators branch on.
// ---------------------------------------------------------------------------
final _engine = SetupEngineService();

UserProfile _makeProfile({
  required String sex,
  required int age,
  required double weight,
  required int height,
  required String goal,
  required String activity,
  required int days,
  String experience = 'beginner',
  List<String> equipment = const ['bodyweight'],
  String diet = 'omnivore',
  String meals = '3',
  List<String> exclusions = const [],
  List<String> injuries = const [],
}) {
  final targets = _engine.calculateTargets(
    sex: sex,
    weightKg: weight,
    heightCm: height,
    ageYears: age,
    goal: goal,
    activityLevel: activity,
  );
  return UserProfile(
    sex: sex,
    ageYears: age,
    heightCm: height,
    weightKg: weight,
    goal: goal,
    activityLevel: activity,
    trainingDaysPerWeek: days,
    trainingExperience: experience,
    equipment: equipment,
    dietType: diet,
    mealCountPerDay: meals,
    exclusions: exclusions,
    injuries: injuries,
    energyUnit: 'kcal',
    weightUnit: 'kg',
    bmr: targets.bmr,
    tdee: targets.tdee,
    calorieTarget: targets.calories,
    proteinTargetG: targets.proteinG,
    fatTargetG: targets.fatG,
    carbsTargetG: targets.carbsG,
  );
}

final _profiles = <String, UserProfile>{
  'young_male_muscle_bw3': _makeProfile(
    sex: 'male', age: 25, weight: 75, height: 175,
    goal: 'muscle_gain', activity: 'moderately_active', days: 3,
  ),
  'young_female_fatloss_gym4': _makeProfile(
    sex: 'female', age: 28, weight: 62, height: 165,
    goal: 'fat_loss', activity: 'moderately_active', days: 4,
    experience: 'intermediate',
    equipment: ['bodyweight', 'dumbbells', 'barbell_rack', 'cable'],
  ),
  'mid_male_maint_gym5': _makeProfile(
    sex: 'male', age: 45, weight: 90, height: 180,
    goal: 'maintenance', activity: 'moderately_active', days: 5,
    experience: 'advanced',
    equipment: ['bodyweight', 'dumbbells', 'barbell_rack', 'machines', 'cable'],
  ),
  'older_female_rehab_bands3': _makeProfile(
    sex: 'female', age: 60, weight: 65, height: 160,
    goal: 'mobility_rehab', activity: 'lightly_active', days: 3,
    equipment: ['bodyweight', 'bands'],
    injuries: ['knee', 'shoulder'],
  ),
  'young_male_muscle_gym5_veg': _makeProfile(
    sex: 'male', age: 22, weight: 70, height: 178,
    goal: 'muscle_gain', activity: 'very_active', days: 5,
    experience: 'intermediate',
    equipment: ['bodyweight', 'dumbbells', 'barbell_rack', 'cable', 'pullup_bar'],
    diet: 'vegetarian',
    exclusions: ['meat', 'fish'],
  ),
  'mid_female_fatloss_db3_nondairy': _makeProfile(
    sex: 'female', age: 40, weight: 72, height: 168,
    goal: 'fat_loss', activity: 'lightly_active', days: 3,
    equipment: ['bodyweight', 'dumbbells'],
    exclusions: ['dairy'],
  ),
  'young_male_maint_gym6': _makeProfile(
    sex: 'male', age: 30, weight: 82, height: 182,
    goal: 'maintenance', activity: 'very_active', days: 6,
    experience: 'advanced',
    equipment: ['bodyweight', 'dumbbells', 'barbell_rack', 'machines', 'cable',
                'kettlebells', 'pullup_bar'],
  ),
  'older_male_muscle_db4_shoulder': _makeProfile(
    sex: 'male', age: 55, weight: 85, height: 176,
    goal: 'muscle_gain', activity: 'moderately_active', days: 4,
    experience: 'intermediate',
    equipment: ['bodyweight', 'dumbbells'],
    injuries: ['shoulder'],
  ),
};

// ---------------------------------------------------------------------------
// Canonical JSON helpers
// ---------------------------------------------------------------------------
final _uuidRe = RegExp(
    r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}');
final _isoDateRe = RegExp(
    r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+');

String _canonicalJson(Object? value) {
  final json = const JsonEncoder.withIndent('  ').convert(_canonical(value));
  // Normalise UUIDs to sequential ids.
  final seen = <String, String>{};
  var counter = 0;
  final pass1 = json.replaceAllMapped(_uuidRe, (m) {
    final uuid = m.group(0)!;
    return seen.putIfAbsent(
        uuid, () => 'parity-${(++counter).toString().padLeft(4, '0')}');
  });
  return pass1.replaceAllMapped(_isoDateRe, (m) {
    return '2026-01-01T00:00:00.000000';
  });
}

Object? _canonical(Object? v) {
  if (v is Map) {
    final sorted = SplayTreeMap<String, Object?>();
    for (final e in v.entries) {
      sorted[e.key.toString()] = _canonical(e.value);
    }
    return sorted;
  }
  if (v is Iterable) return v.map(_canonical).toList();
  if (v is double) {
    if (v.isNaN || v.isInfinite) return v.toString();
    return double.parse(v.toStringAsFixed(6));
  }
  if (v is DateTime) return v.toUtc().toIso8601String();
  if (v is Duration) return v.inMilliseconds;
  if (v is Enum) return v.name;
  return v;
}

Future<void> _write(Directory dir, String name, Object? data) async {
  final contents = '${_canonicalJson(data)}\n';
  await File('${dir.path}/$name').writeAsString(contents);
}

// ---------------------------------------------------------------------------
// 1. nutrition_math.json
// ---------------------------------------------------------------------------
Future<void> _dumpNutritionMath(Directory out) async {
  final testAmounts = [0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 5.0, 10.0,
                       25.0, 50.0, 100.0, 150.0, 200.0, 300.0, 500.0];

  final results = <Map<String, Object?>>[];

  for (final starter in StarterFoodCatalog.all) {
    final food = FoodItem(
      id: starter.id,
      name: starter.name,
      brand: null,
      unit: starter.unit,
      kcalPerUnit: starter.kcal,
      proteinPerUnit: starter.protein,
      carbsPerUnit: starter.carbs,
      fatPerUnit: starter.fat,
      isStarter: true,
      tags: starter.tags,
      category: starter.category,
      createdAt: _epoch,
      updatedAt: _epoch,
    );
    final kind = FoodNutritionMath.kindFor(food);

    for (final amount in testAmounts) {
      final displayQ = FoodNutritionMath.displayQuantity(food, amount);
      final storedQ = FoodNutritionMath.storedQuantity(food, amount);
      final macros = FoodNutritionMath.computeMacros(food, amount);
      final macrosFromDisplay =
          FoodNutritionMath.computeMacrosFromDisplay(food, amount);

      results.add({
        'foodId': starter.id,
        'foodName': starter.name,
        'unit': starter.unit,
        'servingKind': kind.name,
        'inputAmount': amount,
        'displayQuantity': displayQ,
        'storedQuantity': storedQ,
        'macros': macros.toMap(),
        'macrosFromDisplay': macrosFromDisplay.toMap(),
        'macroMultiplier': FoodNutritionMath.macroMultiplier(kind, amount),
        'displayUnitLabel': FoodNutritionMath.displayUnitLabel(food),
        'localizedUnit_en': FoodNutritionMath.localizedUnit(
            AppLanguage.english, starter.unit),
        'localizedUnit_he': FoodNutritionMath.localizedUnit(
            AppLanguage.hebrew, starter.unit),
      });
    }
  }

  await _write(out, 'nutrition_math.json', results);
}

// ---------------------------------------------------------------------------
// 2. serving_kind_parsing.json
// ---------------------------------------------------------------------------
Future<void> _dumpServingKindParsing(Directory out) async {
  final unitStrings = <String>{};

  // Every unit in the catalog.
  for (final f in StarterFoodCatalog.all) {
    unitStrings.add(f.unit);
  }
  // Legacy oddities the parser must handle.
  unitStrings.addAll([
    '100g', 'g', 'ml', 'oz', 'piece', 'slice', 'tbsp', 'scoop',
    'serving', '30g', '50g', 'cup', 'tsp', 'bunch', 'clove',
  ]);

  final results = <Map<String, Object?>>[];
  for (final unit in unitStrings.toList()..sort()) {
    results.add({
      'unit': unit,
      'servingKind': FoodServingKindParser.fromLegacyUnit(unit).name,
      'normalized': FoodServingKindParser.normalizeToCatalogUnit(unit),
      'catalogUnitForKind': FoodServingUnits.catalogUnitForKind(
          FoodServingKindParser.fromLegacyUnit(unit), legacyUnit: unit),
    });
  }

  await _write(out, 'serving_kind_parsing.json', results);
}

// ---------------------------------------------------------------------------
// 3. setup_engine.json
// ---------------------------------------------------------------------------
Future<void> _dumpSetupEngine(Directory out) async {
  final results = <Map<String, Object?>>[];

  final sexes = ['male', 'female'];
  final ages = [20, 30, 45, 60];
  final weights = [50.0, 65.0, 80.0, 100.0, 120.0];
  final heights = [155, 165, 175, 185, 195];
  final goals = ['muscle_gain', 'fat_loss', 'maintenance', 'mobility_rehab'];
  final activities = [
    'sedentary', 'lightly_active', 'moderately_active',
    'very_active', 'extra_active',
  ];

  for (final sex in sexes) {
    for (final goal in goals) {
      for (final activity in activities) {
        // Pick representative weight/height/age combos rather than full product.
        for (var i = 0; i < weights.length; i++) {
          final weight = weights[i];
          final height = heights[i];
          final age = ages[i % ages.length];

          final bmr = _engine.calculateBMR(
              sex: sex, weightKg: weight, heightCm: height, ageYears: age);
          final tdee = _engine.calculateTDEE(bmr, activity);
          final targets = _engine.calculateTargets(
            sex: sex, weightKg: weight, heightCm: height,
            ageYears: age, goal: goal, activityLevel: activity,
          );

          results.add({
            'sex': sex,
            'ageYears': age,
            'weightKg': weight,
            'heightCm': height,
            'goal': goal,
            'activityLevel': activity,
            'bmr': bmr,
            'activityFactor': _engine.getActivityFactor(activity),
            'tdee': tdee,
            'calorieTarget': targets.calories,
            'proteinG': targets.proteinG,
            'carbsG': targets.carbsG,
            'fatG': targets.fatG,
            'kcalFromMacros': targets.kcalFromMacros,
            'minimumSafeCalories':
                SetupEngineService.minimumSafeCalories(sex),
            'proteinPerKg':
                SetupEngineService.proteinPerKgForGoal(goal),
            'proteinRefWeight':
                SetupEngineService.proteinReferenceWeight(weight, height),
            'fatFraction':
                SetupEngineService.fatFractionForGoal(goal),
            'minimumFatG':
                SetupEngineService.minimumFatGrams(weight),
          });
        }
      }
    }
  }

  await _write(out, 'setup_engine.json', results);
}

// ---------------------------------------------------------------------------
// 4. workout_generation.json
// ---------------------------------------------------------------------------
Future<void> _dumpWorkoutGeneration(Directory out) async {
  final results = <Map<String, Object?>>[];

  for (final entry in _profiles.entries) {
    AppDatabase.resetForTesting();
    final db = AppDatabase(seedLanguage: AppLanguage.english);
    final profile = entry.value;
    final gen = WorkoutTemplateGenerator(db, profile, AppLanguage.english);
    final templates = await gen.generateTemplates();

    final templateData = <Map<String, Object?>>[];
    for (final t in templates) {
      final exercises = await db.getTemplateExercisesByTemplateId(t.id);
      templateData.add({
        'name': t.name,
        'notes': t.notes,
        'origin': t.origin.key,
        'exercises': exercises.map((e) => {
          'exerciseId': e.exerciseId,
          'orderIndex': e.orderIndex,
          'defaultSets': e.defaultSets,
          'defaultReps': e.defaultReps,
          'defaultWeight': e.defaultWeight,
          'defaultRestSeconds': e.restSeconds,
          'isRest': e.isRest,
        }).toList(),
      });
    }

    results.add({
      'profileKey': entry.key,
      'profile': profile.toJson(),
      'templateCount': templates.length,
      'templates': templateData,
    });
    AppDatabase.resetForTesting();
  }

  await _write(out, 'workout_generation.json', results);
}

// ---------------------------------------------------------------------------
// 5. meal_generation.json
// ---------------------------------------------------------------------------
Future<void> _dumpMealGeneration(Directory out) async {
  final results = <Map<String, Object?>>[];

  for (final lang in AppLanguage.values) {
    for (final entry in _profiles.entries) {
      AppDatabase.resetForTesting();
      final db = AppDatabase(seedLanguage: lang);
      final profile = entry.value;
      final gen = MealTemplateGenerator(db, profile, lang);
      final templates = await gen.generateTemplates();

      final templateData = <Map<String, Object?>>[];
      for (final t in templates) {
        final items = await db.getMealTemplateItemsByTemplateId(t.id);
        templateData.add({
          'name': t.name,
          'description': t.description,
          'origin': t.origin.key,
          'items': items.map((item) => {
            'foodId': item.foodId,
            'amount': item.amount,
          }).toList(),
        });
      }

      results.add({
        'language': lang.code,
        'profileKey': entry.key,
        'templateCount': templates.length,
        'templates': templateData,
      });
      AppDatabase.resetForTesting();
    }
  }

  await _write(out, 'meal_generation.json', results);
}

// ---------------------------------------------------------------------------
// 6. portion_solver.json
// ---------------------------------------------------------------------------
Future<void> _dumpPortionSolver(Directory out) async {
  // Build food items from the catalog for the solver.
  final db = AppDatabase(seedLanguage: AppLanguage.english);
  final allFoods = await db.getAllFoods();
  AppDatabase.resetForTesting();

  // Pick representative foods by role.
  FoodItemData? findFood(String name) {
    try {
      return allFoods.firstWhere((f) => f.name == name);
    } catch (_) {
      return null;
    }
  }

  final proteins = ['Chicken Breast', 'Eggs', 'Tofu', 'Salmon'];
  final carbs = ['White Rice', 'Sweet Potato', 'Whole Wheat Bread', 'Oats'];
  final fats = ['Olive Oil', 'Peanut Butter', 'Avocado'];
  final vegs = ['Broccoli', 'Spinach', 'Tomato'];

  final targetSets = <Map<String, double>>[
    {'kcal': 500, 'protein': 40, 'carbs': 50, 'fat': 15},
    {'kcal': 700, 'protein': 50, 'carbs': 80, 'fat': 20},
    {'kcal': 400, 'protein': 30, 'carbs': 40, 'fat': 12},
    {'kcal': 900, 'protein': 60, 'carbs': 100, 'fat': 30},
  ];

  final results = <Map<String, Object?>>[];

  for (final proteinName in proteins) {
    final pFood = findFood(proteinName);
    if (pFood == null) continue;

    for (final carbName in carbs) {
      final cFood = findFood(carbName);
      if (cFood == null) continue;

      for (final target in targetSets) {
        final fatFood = findFood(fats[0]);
        final vegFood = findFood(vegs[0]);

        final portions = MealPortionSolver.solve(
          protein: pFood,
          carb: cFood,
          fat: fatFood,
          veg: vegFood,
          extras: const [],
          kcalTarget: target['kcal']!,
          proteinTarget: target['protein']!,
          carbsTarget: target['carbs']!,
          fatTarget: target['fat']!,
        );

        final totals = MacroTotals.of(portions);

        results.add({
          'protein': proteinName,
          'carb': carbName,
          'fat': fats[0],
          'veg': vegs[0],
          'targets': target,
          'portions': portions.map((p) => {
            'foodId': p.food.id,
            'foodName': p.food.name,
            'amount': p.amount,
            'role': p.role.name,
            'kcal': p.kcal,
            'protein': p.protein,
            'carbs': p.carbs,
            'fat': p.fat,
          }).toList(),
          'totals': {
            'kcal': totals.kcal,
            'protein': totals.protein,
            'carbs': totals.carbs,
            'fat': totals.fat,
          },
        });
      }
    }
  }

  await _write(out, 'portion_solver.json', results);
}

// ---------------------------------------------------------------------------
// 7. schedule_generation.json
// ---------------------------------------------------------------------------
Future<void> _dumpScheduleGeneration(Directory out) async {
  final results = <Map<String, Object?>>[];

  for (final entry in _profiles.entries) {
    AppDatabase.resetForTesting();
    final db = AppDatabase(seedLanguage: AppLanguage.english);
    final profile = entry.value;

    // Generate workout templates first (schedule needs them).
    final wGen = WorkoutTemplateGenerator(db, profile, AppLanguage.english);
    await wGen.generateTemplates();

    // Generate meal templates.
    final mGen = MealTemplateGenerator(db, profile, AppLanguage.english);
    await mGen.generateTemplates();

    final sGen = CalendarScheduleGenerator(db, profile, AppLanguage.english);
    final events = await sGen.buildSchedule();

    results.add({
      'profileKey': entry.key,
      'eventCount': events.length,
      'events': events.map((e) => {
        'type': e.type.name,
        'title': e.title,
        'dayOfWeek': e.scheduledAt.weekday,
        'hour': e.scheduledAt.hour,
        'minute': e.scheduledAt.minute,
        'templateId': e.templateId,
        'recurrenceType': e.recurrenceType.name,
        'recurrenceDays': e.recurrenceDays,
      }).toList(),
    });
    AppDatabase.resetForTesting();
  }

  await _write(out, 'schedule_generation.json', results);
}

// ---------------------------------------------------------------------------
// 8. analytics.json
// ---------------------------------------------------------------------------
Future<void> _dumpAnalytics(Directory out) async {
  // Build a fixed 365-day synthetic dataset.
  final baseDay = DateTime.utc(2025, 1, 1);
  final rng = math.Random(42); // Seeded for reproducibility.

  final nutrition = <DailyNutrition>[];
  final sessions = <TrainingSession>[];
  final sleep = <SleepNight>[];
  final weighIns = <WeighIn>[];

  final exercises = {
    'bench': const ExerciseRef(
        id: 'bench', name: 'Bench Press', primaryMuscle: 'Chest'),
    'squat': const ExerciseRef(
        id: 'squat', name: 'Barbell Squat', primaryMuscle: 'Quadriceps'),
    'deadlift': const ExerciseRef(
        id: 'deadlift', name: 'Deadlift', primaryMuscle: 'Hamstrings'),
    'row': const ExerciseRef(
        id: 'row', name: 'Barbell Row', primaryMuscle: 'Back'),
    'ohp': const ExerciseRef(
        id: 'ohp', name: 'Overhead Press', primaryMuscle: 'Shoulders'),
    'curl': const ExerciseRef(
        id: 'curl', name: 'Bicep Curl', primaryMuscle: 'Biceps'),
  };

  for (var d = 0; d < 365; d++) {
    final day = baseDay.add(Duration(days: d));
    final dateInt = AppDateUtils.dateToInt(day);

    // Nutrition: ~80% of days logged.
    if (rng.nextDouble() < 0.80) {
      nutrition.add(DailyNutrition(
        dateInt: dateInt,
        kcal: 1800 + rng.nextInt(800).toDouble(),
        protein: 100 + rng.nextInt(80).toDouble(),
        carbs: 150 + rng.nextInt(150).toDouble(),
        fat: 50 + rng.nextInt(40).toDouble(),
        logged: true,
      ));
    }

    // Training: 4 days/week pattern (Mon/Tue/Thu/Fri).
    if ([1, 2, 4, 5].contains(day.weekday) && rng.nextDouble() < 0.85) {
      final exIds = exercises.keys.toList();
      final sessionExercises = exIds.sublist(0, 3 + rng.nextInt(2));
      final sets = <TrainingSet>[];

      for (final exId in sessionExercises) {
        for (var s = 0; s < 3 + rng.nextInt(2); s++) {
          final reps = 5 + rng.nextInt(8);
          // Gradual progression over the year.
          final baseWeight = exId == 'bench' ? 60.0
              : exId == 'squat' ? 80.0
              : exId == 'deadlift' ? 100.0
              : exId == 'row' ? 50.0
              : exId == 'ohp' ? 35.0
              : 15.0;
          final progression = d / 365.0 * 20.0;
          sets.add(TrainingSet(
            exerciseId: exId,
            reps: reps,
            weightKg: baseWeight + progression,
          ));
        }
      }

      sessions.add(TrainingSession(
        id: 'session-${d.toString().padLeft(3, '0')}',
        startedAt: day.add(const Duration(hours: 7)),
        duration: Duration(minutes: 40 + rng.nextInt(30)),
        sets: sets,
      ));
    }

    // Sleep: ~90% of days.
    if (rng.nextDouble() < 0.90) {
      final hours = 5.5 + rng.nextDouble() * 3.5;
      sleep.add(SleepNight(
        day: day,
        hours: hours,
        quality: 1 + rng.nextInt(5),
        startedAt: day.subtract(Duration(hours: (24 - 23).abs(),
            minutes: rng.nextInt(60))),
      ));
    }

    // Body weight: weekly.
    if (day.weekday == 1) {
      final trend = 85.0 - d / 365.0 * 3.0;
      weighIns.add(WeighIn(day: day, kg: trend + rng.nextDouble() - 0.5));
    }
  }

  // One in-progress session to test exclusion.
  sessions.add(TrainingSession(
    id: 'session-in-progress',
    startedAt: baseDay.add(const Duration(days: 364, hours: 7)),
    duration: Duration.zero,
    sets: [
      const TrainingSet(exerciseId: 'bench', reps: 5, weightKg: 80),
    ],
  ));

  final snapshot = AnalyticsSnapshot(
    nutrition: nutrition,
    sessions: sessions,
    sleep: sleep,
    weighIns: weighIns,
    exercises: exercises,
  );

  final targets = GoalTargets(
    calorieGoal: 2200,
    proteinGoal: 150,
    trainingDaysPerWeek: 4,
    sleepGoalHours: 7.5,
    profileGoal: 'muscle_gain',
  );

  final ranges = AnalyticsRange.values;
  final endDate = baseDay.add(const Duration(days: 364));
  final results = <Map<String, Object?>>[];

  for (final range in ranges) {
    final dateRange = range.rangeEndingOn(endDate);
    final bucket = range.bucket;

    final view = AnalyticsView.compute(
      range: dateRange,
      bucket: bucket,
      targets: targets,
      snapshot: snapshot,
    );

    results.add({
      'range': range.name,
      'rangeDays': range.days,
      'bucket': bucket.name,
      'startDate': dateRange.start.toIso8601String(),
      'endDate': dateRange.endExclusive.toIso8601String(),
      'hasData': !view.hasNoData,
      'calories': _seriesData(view.calories),
      'caloriesTrend': _seriesData(view.caloriesTrend),
      'protein': _seriesData(view.protein),
      'carbs': _seriesData(view.carbs),
      'fat': _seriesData(view.fat),
      'volume': _seriesData(view.volume),
      'sessionCount': _seriesData(view.sessionCount),
      'trainingMinutes': _seriesData(view.trainingMinutes),
      'sleepHours': _seriesData(view.sleepHours),
      'sleepQuality': _seriesData(view.sleepQuality),
      'bodyWeight': _seriesData(view.bodyWeight),
      'bodyWeightTrend': _seriesData(view.bodyWeightTrend),
      'setsPerMuscle': view.setsPerMuscle,
      'goalDays': view.goalDays.map((d) => {
        'day': d.day.toIso8601String(),
        'score': d.score,
        'isPerfect': d.isPerfect,
        'met': d.met.map((g) => g.name).toList()..sort(),
        'applicable': d.applicable.map((g) => g.name).toList()..sort(),
      }).toList(),
      'currentStreak': view.currentStreak,
      'bestStreak': view.bestStreak,
      'averageScore': view.averageScore,
      'insights': view.insights.map((i) => {
        'kind': i.kind.name,
        'tone': i.tone.name,
        'subjectId': i.subjectId,
        'values': i.values,
        'priority': i.priority,
      }).toList(),
      'defaultStrengthExerciseId': view.defaultStrengthExerciseId,
    });
  }

  // Also dump standalone functions.
  final benchProgress = buildExerciseProgress(sessions);
  final plateaus = detectPlateaus(benchProgress);

  results.add({
    'range': '_standalone',
    'estimatedOneRepMax_80kg_5reps': estimatedOneRepMax(80, 5),
    'estimatedOneRepMax_60kg_10reps': estimatedOneRepMax(60, 10),
    'estimatedOneRepMax_100kg_1rep': estimatedOneRepMax(100, 1),
    'exerciseProgress': benchProgress.map((id, p) => MapEntry(id, {
      'sessionCount': p.sessionCount,
      'totalVolume': p.totalVolume,
      'bestE1rm': p.bestE1rm,
    })),
    'plateaus': plateaus.map((p) => {
      'exerciseId': p.exerciseId,
      'lastTopWeightKg': p.lastTopWeightKg,
      'sessionsAtWeight': p.sessionsAtWeight,
      'daysSinceIncrease': p.daysSinceIncrease,
      'isPlateau': p.isPlateau,
      'isPersonalBest': p.isPersonalBest,
    }).toList(),
    'bedtimeConsistency': bedtimeConsistencyHours(sleep),
    'standardDeviation_sample': standardDeviation([1, 2, 3, 4, 5]),
  });

  await _write(out, 'analytics.json', results);
}

Map<String, Object?> _seriesData(MetricSeries s) => {
  'isEmpty': s.isEmpty,
  'observedCount': s.observedCount,
  'average': s.average,
  'total': s.total,
  'min': s.min,
  'max': s.max,
  'latest': s.latest,
  'earliest': s.earliest,
  'slopePerDay': s.slopePerDay,
};

// ---------------------------------------------------------------------------
// 9. rest_prescription.json
// ---------------------------------------------------------------------------
Future<void> _dumpRestPrescription(Directory out) async {
  final results = <Map<String, Object?>>[];

  // restSecondsForReps over a range.
  for (var reps = 1; reps <= 20; reps++) {
    results.add({
      'type': 'restSecondsForReps',
      'reps': reps,
      'seconds': restSecondsForReps(reps),
      'formatted': formatRest(restSecondsForReps(reps)),
    });
  }

  // resolveRestSeconds combinations.
  for (final explicit in [null, 60, 90, 120, 180]) {
    for (final reps in [null, 5, 8, 12, 15]) {
      for (final globalDefault in [90, 120]) {
        results.add({
          'type': 'resolveRestSeconds',
          'explicitSeconds': explicit,
          'reps': reps,
          'globalDefaultSeconds': globalDefault,
          'resolved': resolveRestSeconds(
            explicitSeconds: explicit,
            reps: reps,
            globalDefaultSeconds: globalDefault,
          ),
        });
      }
    }
  }

  // WorkoutProgramming scheme data for all goals.
  for (final goal in ['muscle_gain', 'fat_loss', 'maintenance', 'mobility_rehab']) {
    final scheme = WorkoutProgramming.schemeFor(goal);
    results.add({
      'type': 'schemeFor',
      'goal': goal,
      'sets': scheme.sets,
      'reps': scheme.reps,
      'compoundRestMs': scheme.compoundRest.inMilliseconds,
      'isolationRestMs': scheme.isolationRest.inMilliseconds,
      'repsInReserve': scheme.repsInReserve,
      'exerciseBudget': WorkoutProgramming.exerciseBudget(scheme),
    });
  }

  // Starting weight for representative profiles.
  for (final loadClass in LoadClass.values) {
    for (final sex in ['male', 'female']) {
      for (final experience in ['beginner', 'intermediate', 'advanced']) {
        results.add({
          'type': 'startingWeight',
          'loadClass': loadClass.name,
          'sex': sex,
          'experience': experience,
          'bodyweightKg': 75.0,
          'ageYears': 30,
          'reps': 8,
          'unit': 'kg',
          'weightKg': WorkoutProgramming.startingWeightKg(
            loadClass: loadClass,
            unit: 'kg',
            bodyweightKg: 75.0,
            sex: sex,
            experience: experience,
            ageYears: 30,
            reps: 8,
          ),
        });
      }
    }
  }

  await _write(out, 'rest_prescription.json', results);
}

// ---------------------------------------------------------------------------
// 10. content_language_switch.json
// ---------------------------------------------------------------------------
Future<void> _dumpContentLanguageSwitch(Directory out) async {
  final results = <Map<String, Object?>>[];

  for (final startLang in AppLanguage.values) {
    final endLang =
        startLang == AppLanguage.english ? AppLanguage.hebrew : AppLanguage.english;

    AppDatabase.resetForTesting();
    final db = AppDatabase(seedLanguage: startLang);

    // Snapshot before the switch.
    final foodsBefore = await db.getAllFoods();
    final exercisesBefore = await db.getAllExercises();

    // Switch.
    final changed = await db.relanguageCatalog(endLang);

    // Snapshot after the switch.
    final foodsAfter = await db.getAllFoods();
    final exercisesAfter = await db.getAllExercises();

    // Also test that a generated template is replaced correctly.
    final profile = _profiles.values.first;
    final wGen = WorkoutTemplateGenerator(db, profile, endLang);
    final wTemplates = await wGen.generateTemplates();

    final mGen = MealTemplateGenerator(db, profile, endLang);
    final mTemplates = await mGen.generateTemplates();

    results.add({
      'startLanguage': startLang.code,
      'endLanguage': endLang.code,
      'catalogRowsChanged': changed,
      'foodsBefore': foodsBefore.map((f) => {
        'id': f.id,
        'name': f.name,
        'unit': f.unit,
      }).toList(),
      'foodsAfter': foodsAfter.map((f) => {
        'id': f.id,
        'name': f.name,
        'unit': f.unit,
      }).toList(),
      'exercisesBefore': exercisesBefore.map((e) => {
        'id': e.id,
        'name': e.name,
        'primaryMuscle': e.primaryMuscle,
      }).toList(),
      'exercisesAfter': exercisesAfter.map((e) => {
        'id': e.id,
        'name': e.name,
        'primaryMuscle': e.primaryMuscle,
      }).toList(),
      'workoutTemplatesGenerated': wTemplates.length,
      'mealTemplatesGenerated': mTemplates.length,
      'workoutTemplateNames': wTemplates.map((t) => t.name).toList(),
      'mealTemplateNames': mTemplates.map((t) => t.name).toList(),
    });
    AppDatabase.resetForTesting();
  }

  await _write(out, 'content_language_switch.json', results);
}

// ---------------------------------------------------------------------------
// 11. export_roundtrip.json
// ---------------------------------------------------------------------------
Future<void> _dumpExportRoundtrip(Directory out) async {
  AppDatabase.resetForTesting();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(seedLanguage: AppLanguage.english);
  final calendarService = CalendarService(prefs, db);

  // Populate with a known dataset by generating templates for a profile.
  final profile = _profiles['young_male_muscle_bw3']!;
  final wGen = WorkoutTemplateGenerator(db, profile, AppLanguage.english);
  await wGen.generateTemplates();
  final mGen = MealTemplateGenerator(db, profile, AppLanguage.english);
  await mGen.generateTemplates();

  // Add some meals and sessions so the export is non-trivial.
  final foods = await db.getAllFoods();
  if (foods.isNotEmpty) {
    final meal = MealData(
      id: 'test-meal-001',
      date: 20260101,
      name: 'Test Breakfast',
      createdAt: _epoch,
      updatedAt: _epoch,
    );
    await db.insertMeal(meal);
    await db.insertMealItem(MealItemData(
      id: 'test-mealitem-001',
      mealId: 'test-meal-001',
      foodId: foods.first.id,
      amount: 1.5,
      kcal: 200,
      protein: 30,
      carbs: 10,
      fat: 5,
    ));
  }

  final exportService = ExportImportService(db, calendarService, prefs);
  final exported = await exportService.exportToJson();

  // Parse, canonicalize, and capture the structure.
  final parsed = jsonDecode(exported) as Map<String, dynamic>;

  // Count rows per collection.
  final collectionCounts = <String, int>{};
  for (final key in parsed.keys) {
    final val = parsed[key];
    if (val is List) {
      collectionCounts[key] = val.length;
    }
  }

  // Round-trip: import into a fresh DB and compare counts.
  AppDatabase.resetForTesting();
  final db2 = AppDatabase(seedLanguage: null);
  SharedPreferences.setMockInitialValues({});
  final prefs2 = await SharedPreferences.getInstance();
  final calendarService2 = CalendarService(prefs2, db2);
  final importService = ExportImportService(db2, calendarService2, prefs2);
  await importService.importFromJson(exported);

  final reimported = await importService.exportToJson();
  final reparsed = jsonDecode(reimported) as Map<String, dynamic>;
  final reimportCounts = <String, int>{};
  for (final key in reparsed.keys) {
    final val = reparsed[key];
    if (val is List) {
      reimportCounts[key] = val.length;
    }
  }

  await _write(out, 'export_roundtrip.json', {
    'exportVersion': parsed['version'],
    'collectionCounts': collectionCounts,
    'reimportCounts': reimportCounts,
    'roundTripMatch': collectionCounts.keys.every(
        (k) => collectionCounts[k] == reimportCounts[k]),
    'exportedKeys': parsed.keys.toList()..sort(),
    'exportPayload': parsed,
  });
  AppDatabase.resetForTesting();
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate golden corpus → parity/golden/', () async {
    final out = Directory('parity/golden');
    await out.create(recursive: true);

    await _dumpNutritionMath(out);
    await _dumpServingKindParsing(out);
    await _dumpSetupEngine(out);
    await _dumpWorkoutGeneration(out);
    await _dumpMealGeneration(out);
    await _dumpPortionSolver(out);
    await _dumpScheduleGeneration(out);
    await _dumpAnalytics(out);
    await _dumpRestPrescription(out);
    await _dumpContentLanguageSwitch(out);
    await _dumpExportRoundtrip(out);

    // Verify all 11 files exist.
    final expected = [
      'nutrition_math.json',
      'serving_kind_parsing.json',
      'setup_engine.json',
      'workout_generation.json',
      'meal_generation.json',
      'portion_solver.json',
      'schedule_generation.json',
      'analytics.json',
      'rest_prescription.json',
      'content_language_switch.json',
      'export_roundtrip.json',
    ];
    for (final name in expected) {
      expect(File('${out.path}/$name').existsSync(), isTrue,
          reason: '$name was not generated');
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
