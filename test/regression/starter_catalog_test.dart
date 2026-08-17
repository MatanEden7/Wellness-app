@Tags(['catalog'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/app_language.dart';
import 'package:wellness_app/services/meal_template_generator.dart';
import 'package:wellness_app/services/user_profile_service.dart';
import 'package:wellness_app/services/workout_template_generator.dart';

import 'package:wellness_app/data/db/drift_database.dart';

/// Regression coverage for the starter catalog -- the foods and exercises
/// seeded in the onboarding language (see `AppDatabase.seedCatalogFor` and
/// `_getSampleFoods`/`_getSampleExercises` in
/// lib/data/db/drift_database.dart).
///
/// The catalog is all that ships. There are no built-in templates any more:
/// what used to be asserted here as "built-ins exist" is now asserted as
/// "onboarding generation fills the Templates tab", which is the property
/// that actually mattered -- a new user must not land on an empty screen.
UserProfile _profile() => UserProfile(
      sex: 'male',
      ageYears: 30,
      heightCm: 180,
      weightKg: 80,
      goal: 'build_muscle',
      activityLevel: 'moderate',
      trainingDaysPerWeek: 4,
      trainingExperience: 'beginner',
      equipment: const ['full_gym'],
      dietType: 'omnivore',
      mealCountPerDay: '3',
      exclusions: const [],
      injuries: const [],
      bmr: 1800,
      tdee: 2500,
      calorieTarget: 2600,
      proteinTargetG: 160,
      carbsTargetG: 300,
      fatTargetG: 80,
      energyUnit: 'kcal',
      weightUnit: 'kg',
    );

void main() {
  late AppDatabase database;

  setUpAll(() {
    database = AppDatabase();
  });

  test('starter foods: at least 40, all marked isStarter', () async {
    final foods = await database.getStarterFoods();
    expect(foods.length, greaterThanOrEqualTo(40));
    expect(foods.every((f) => f.isStarter), isTrue);
  });

  test(
    'Chicken Breast keeps the exact values other tests rely on '
    '(165 kcal / 31g protein / 0g carbs / 3.6g fat per 100g)',
    () async {
      final foods = await database.getAllFoods();
      final chicken = foods.firstWhere((f) => f.name == 'Chicken Breast');

      expect(chicken.unit, '100g');
      expect(chicken.kcalPerUnit, 165);
      expect(chicken.proteinPerUnit, 31);
      expect(chicken.carbsPerUnit, 0);
      expect(chicken.fatPerUnit, 3.6);
      expect(chicken.isStarter, isTrue);
    },
  );

  test(
      'exercise library covers at least 16 exercises across multiple muscle groups',
      () async {
    final exercises = await database.getAllExercises();
    expect(exercises.length, greaterThanOrEqualTo(16));

    final muscleGroups =
        exercises.map((e) => e.primaryMuscle).whereType<String>().toSet();
    for (final expected in ['Chest', 'Back', 'Shoulders', 'Core']) {
      expect(muscleGroups, contains(expected),
          reason: 'missing $expected coverage');
    }
  });

  test('onboarding generation fills the workouts tab, each with exercises',
      () async {
    AppDatabase.resetForTesting();
    final db = AppDatabase();
    await WorkoutTemplateGenerator(db, _profile(), AppLanguage.english)
        .generateTemplates();
    final templates = await db.getAllWorkoutTemplates();
    expect(templates.length, greaterThanOrEqualTo(4));

    for (final template in templates) {
      final exercises = await db.getTemplateExercisesByTemplateId(template.id);
      expect(exercises, isNotEmpty,
          reason: '${template.name} has no exercises');
    }
  });

  test('onboarding generation fills the meals tab with real foods', () async {
    AppDatabase.resetForTesting();
    final db = AppDatabase();
    await MealTemplateGenerator(db, _profile(), AppLanguage.english)
        .generateTemplates();
    final templates = await db.getAllMealTemplates();
    expect(templates, isNotEmpty);

    final foodIds = (await db.getAllFoods()).map((f) => f.id).toSet();
    for (final template in templates) {
      final items = await db.getMealTemplateItemsByTemplateId(template.id);
      expect(items, isNotEmpty, reason: '${template.name} has no items');
      for (final item in items) {
        expect(foodIds, contains(item.foodId),
            reason:
                '${template.name} references an unknown food id ${item.foodId}');
      }
    }
  });
}
