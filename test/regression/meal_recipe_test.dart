@Tags(['catalog', 'nutrition'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/services/meal_template_generator.dart';
import 'package:wellness_app/services/user_profile_service.dart';

/// Generated meals must read like food someone would cook, not a macro-legal
/// pile. The previous generator produced "Seitan, Avocado, White Rice and
/// Milk" for breakfast -- it hit its numbers and was not a breakfast.
UserProfile _p({String diet = 'omnivore', List<String> ex = const []}) =>
    UserProfile(
        sex: 'male',
        ageYears: 30,
        heightCm: 180,
        weightKg: 80,
        goal: 'maintenance',
        activityLevel: 'moderate',
        trainingDaysPerWeek: 3,
        equipment: const ['none'],
        dietType: diet,
        mealCountPerDay: '3',
        exclusions: ex,
        injuries: const [],
        energyUnit: 'kcal',
        weightUnit: 'g',
        bmr: 1800,
        tdee: 2500,
        calorieTarget: 2500,
        proteinTargetG: 150,
        fatTargetG: 70,
        carbsTargetG: 280);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(AppDatabase.resetForTesting);

  test('every generated meal is a named recipe, not a food pile', () async {
    final db = AppDatabase();
    final created = await MealTemplateGenerator(db, _p()).generateTemplates();
    for (final t in created) {
      expect(t.name, contains(':'),
          reason: 'expected "Breakfast: Eggs & Toast" style naming');
      expect(t.description, isNotNull, reason: '${t.name} has no description');
    }
  });

  test('breakfast is a breakfast', () async {
    final db = AppDatabase();
    final created = await MealTemplateGenerator(db, _p()).generateTemplates();
    final breakfast = created.firstWhere((t) => t.name.startsWith('Breakfast'));
    final foods = {for (final f in await db.getAllFoods()) f.id: f};
    final names = [
      for (final i in await db.getMealTemplateItemsByTemplateId(breakfast.id))
        foods[i.foodId]!.name,
    ];
    // Not an exhaustive definition of breakfast -- just that it draws from
    // breakfast foods rather than, say, salmon and pasta.
    const breakfastish = {
      'Eggs',
      'Egg Whites',
      'Greek Yogurt',
      'Cottage Cheese',
      'Oats',
      'Whole Wheat Bread',
      'Milk',
      'Soy Milk',
      'Tofu',
      'Tempeh',
      'Hemp Seeds',
      'Pumpkin Seeds',
      'Sunflower Seeds',
      'Buckwheat',
      'Quinoa',
    };
    expect(names.any(breakfastish.contains), isTrue,
        reason: 'breakfast was: $names');
  });

  test('countable foods come in whole units', () async {
    final db = AppDatabase();
    final created = await MealTemplateGenerator(db, _p()).generateTemplates();
    final foods = {for (final f in await db.getAllFoods()) f.id: f};
    for (final t in created) {
      for (final i in await db.getMealTemplateItemsByTemplateId(t.id)) {
        final f = foods[i.foodId]!;
        if (const ['piece', 'slice', 'tbsp'].contains(f.unit)) {
          expect(i.amount, i.amount.roundToDouble(),
              reason: '${f.name}: half a ${f.unit} is not a portion');
          expect(i.amount, greaterThanOrEqualTo(1));
        }
      }
    }
  });

  test('vegetables get a normal serving, not a solver-inflated one', () async {
    // 400g of spinach in a breakfast was the symptom of letting a near-zero
    // calorie food absorb a calorie target.
    final db = AppDatabase();
    final created = await MealTemplateGenerator(db, _p()).generateTemplates();
    final foods = {for (final f in await db.getAllFoods()) f.id: f};
    for (final t in created) {
      for (final i in await db.getMealTemplateItemsByTemplateId(t.id)) {
        final f = foods[i.foodId]!;
        if (const ['Spinach', 'Broccoli', 'Kale', 'Blueberries']
            .contains(f.name)) {
          expect(i.amount, lessThanOrEqualTo(1.5),
              reason: '${f.name} at ${i.amount * 100}g is not a serving');
        }
      }
    }
  });

  test('egg whites appear alongside whole eggs as the calorie lever', () async {
    final db = AppDatabase();
    final created = await MealTemplateGenerator(db, _p()).generateTemplates();
    final foods = {for (final f in await db.getAllFoods()) f.id: f};
    final breakfast =
        created.firstWhere((t) => t.name.contains('Eggs & Toast'));
    final names = [
      for (final i in await db.getMealTemplateItemsByTemplateId(breakfast.id))
        foods[i.foodId]!.name,
    ];
    expect(names, contains('Eggs'));
    expect(names, contains('Egg Whites'),
        reason: 'egg whites let the dish hold protein while calories drop');
  });

  test('a vegan gets vegan recipes, not omnivore ones with gaps', () async {
    final db = AppDatabase();
    final created = await MealTemplateGenerator(
            db, _p(diet: 'herbivore', ex: ['soy', 'gluten', 'nuts']))
        .generateTemplates();
    expect(created, isNotEmpty);
    for (final t in created) {
      final items = await db.getMealTemplateItemsByTemplateId(t.id);
      expect(items.length, greaterThanOrEqualTo(2),
          reason: '${t.name} is too thin to be a meal');
    }
  });
}
