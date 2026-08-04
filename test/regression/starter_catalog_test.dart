@Tags(['catalog'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:wellness_app/data/db/drift_database.dart';

/// Regression coverage for the expanded starter catalog: foods, exercises,
/// and the built-in workout/meal templates that ship on first launch (see
/// AppDatabase._getSampleFoods/_getSampleExercises/_getBuiltInWorkoutTemplates/
/// _getBuiltInMealTemplates in lib/data/db/drift_database.dart).
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

  test('exercise library covers at least 16 exercises across multiple muscle groups', () async {
    final exercises = await database.getAllExercises();
    expect(exercises.length, greaterThanOrEqualTo(16));

    final muscleGroups = exercises.map((e) => e.primaryMuscle).whereType<String>().toSet();
    for (final expected in ['Chest', 'Back', 'Shoulders', 'Core']) {
      expect(muscleGroups, contains(expected), reason: 'missing $expected coverage');
    }
  });

  test('built-in workout templates exist and each has exercises', () async {
    final templates = await database.getAllWorkoutTemplates();
    expect(templates.length, greaterThanOrEqualTo(4));

    for (final template in templates) {
      final exercises = await database.getTemplateExercisesByTemplateId(template.id);
      expect(exercises, isNotEmpty, reason: '${template.name} has no exercises');
    }
  });

  test('built-in meal templates exist and each references real foods', () async {
    final templates = await database.getAllMealTemplates();
    expect(templates.length, greaterThanOrEqualTo(4));

    final foodIds = (await database.getAllFoods()).map((f) => f.id).toSet();
    for (final template in templates) {
      final items = await database.getMealTemplateItemsByTemplateId(template.id);
      expect(items, isNotEmpty, reason: '${template.name} has no items');
      for (final item in items) {
        expect(foodIds, contains(item.foodId), reason: '${template.name} references an unknown food id ${item.foodId}');
      }
    }
  });
}
