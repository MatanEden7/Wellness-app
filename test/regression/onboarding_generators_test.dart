@Tags(['profile'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/services/meal_template_generator.dart';
import 'package:wellness_app/services/user_profile_service.dart';
import 'package:wellness_app/services/workout_template_generator.dart';

/// Coverage for [WorkoutTemplateGenerator] and [MealTemplateGenerator]: the
/// two onboarding-time generators that turn a finished profile into real
/// workout/meal templates. Used only from onboarding_page.dart and had zero
/// test coverage.
///
/// Worth noting for anyone touching these: both generators' own
/// exercise/food generation is a no-op in normal operation --
/// `_generateExercises`/`_generateFoods` skip themselves once the database
/// already has more than 2 exercises or 10 foods, and `AppDatabase`'s
/// constructor always seeds 16 exercises and 40+ foods before either
/// generator runs. So "generate templates" in practice only ever builds
/// *templates* referencing the starter catalog, never new exercises/foods --
/// these tests assert against that real behavior, not the dead branch.
UserProfile _profile({
  int trainingDaysPerWeek = 3,
  List<String> injuries = const [],
  List<String> equipment = const ['dumbbells', 'barbell_rack', 'pullup_bar'],
  String dietType = 'omnivore',
  String mealCountPerDay = '3',
  List<String> exclusions = const [],
}) =>
    UserProfile(
      sex: 'male',
      ageYears: 30,
      heightCm: 178,
      weightKg: 80,
      goal: 'maintenance',
      activityLevel: 'moderate',
      trainingDaysPerWeek: trainingDaysPerWeek,
      equipment: equipment,
      dietType: dietType,
      mealCountPerDay: mealCountPerDay,
      exclusions: exclusions,
      injuries: injuries,
      energyUnit: 'kcal',
      weightUnit: 'g',
      bmr: 1800,
      tdee: 2500,
      calorieTarget: 2500,
      proteinTargetG: 150,
      fatTargetG: 60,
      carbsTargetG: 300,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(AppDatabase.resetForTesting);

  group('WorkoutTemplateGenerator', () {
    test('skips the equipment-based exercise set once the starter catalog exists, '
        'but the mobility pack still adds its own fixed exercises', () async {
      final database = AppDatabase();
      final before = (await database.getAllExercises()).length;

      await WorkoutTemplateGenerator(database, _profile()).generateTemplates();

      // _generateExercises itself is skipped (see class doc), but
      // _generateMobilityPack unconditionally inserts a handful of
      // stretch/mobility exercises the starter catalog doesn't carry.
      expect((await database.getAllExercises()).length, greaterThan(before));
    });

    test('adds a main-split template plus a mobility pack', () async {
      final database = AppDatabase();
      final beforeTemplates = (await database.getAllWorkoutTemplates()).length;

      await WorkoutTemplateGenerator(database, _profile(trainingDaysPerWeek: 3)).generateTemplates();

      final templates = await database.getAllWorkoutTemplates();
      expect(templates.length, greaterThan(beforeTemplates));
      expect(templates.any((t) => t.name.toLowerCase().contains('mobility')), isTrue);
    });

    test('5+ training days a week produces more split templates than 3 days', () async {
      final db3 = AppDatabase();
      await WorkoutTemplateGenerator(db3, _profile(trainingDaysPerWeek: 3)).generateTemplates();
      final count3 = (await db3.getAllWorkoutTemplates()).length;

      AppDatabase.resetForTesting();
      final db5 = AppDatabase();
      await WorkoutTemplateGenerator(db5, _profile(trainingDaysPerWeek: 5)).generateTemplates();
      final count5 = (await db5.getAllWorkoutTemplates()).length;

      expect(count5, greaterThan(count3),
          reason: 'a 5-day push/pull/legs split has more templates than a 3-day full-body split');
    });

    test('every exercise a template references actually exists in the database', () async {
      final database = AppDatabase();
      await WorkoutTemplateGenerator(database, _profile(injuries: ['shoulder'])).generateTemplates();

      final exerciseIds = (await database.getAllExercises()).map((e) => e.id).toSet();
      final templateExercises = await database.getAllTemplateExercises();

      expect(templateExercises, isNotEmpty);
      for (final te in templateExercises) {
        expect(exerciseIds, contains(te.exerciseId),
            reason: 'template exercise ${te.exerciseId} must resolve to a real seeded exercise');
      }
    });

    test('rehab templates are only generated when the profile reports an injury', () async {
      final withInjury = AppDatabase();
      await WorkoutTemplateGenerator(withInjury, _profile(injuries: ['knee'])).generateTemplates();
      final withInjuryTemplates = await withInjury.getAllWorkoutTemplates();
      expect(withInjuryTemplates.any((t) => t.name.toLowerCase().contains('rehab')), isTrue);

      AppDatabase.resetForTesting();
      final noInjury = AppDatabase();
      await WorkoutTemplateGenerator(noInjury, _profile(injuries: const [])).generateTemplates();
      final noInjuryTemplates = await noInjury.getAllWorkoutTemplates();
      expect(noInjuryTemplates.any((t) => t.name.toLowerCase().contains('rehab')), isFalse);
    });

    test('"none" in the injuries list is treated the same as no injuries', () async {
      final database = AppDatabase();
      await WorkoutTemplateGenerator(database, _profile(injuries: ['none'])).generateTemplates();
      final templates = await database.getAllWorkoutTemplates();
      expect(templates.any((t) => t.name.toLowerCase().contains('rehab')), isFalse);
    });
  });

  group('MealTemplateGenerator', () {
    test('does not touch the food catalog -- the starter seed already exceeds its skip threshold', () async {
      final database = AppDatabase();
      final before = (await database.getAllFoods()).length;

      await MealTemplateGenerator(database, _profile()).generateTemplates();

      expect(await database.getAllFoods(), hasLength(before));
    });

    test('generates a fixed set of diet-specific templates, independent of meal count', () async {
      // _getTemplateSuggestions() returns a hardcoded list per diet type
      // (3 for omnivore/herbivore, 2 for carnivore) -- mealCountPerDay only
      // scales portion sizes via the distribution average, it does not
      // change how many templates are created.
      final database = AppDatabase();
      final beforeTemplates = (await database.getAllMealTemplates()).length;

      await MealTemplateGenerator(database, _profile(dietType: 'omnivore')).generateTemplates();

      final newTemplateCount = (await database.getAllMealTemplates()).length - beforeTemplates;
      expect(newTemplateCount, 3);
    });

    test('every food a template item references actually exists in the database', () async {
      final database = AppDatabase();
      await MealTemplateGenerator(database, _profile()).generateTemplates();

      final foodIds = (await database.getAllFoods()).map((f) => f.id).toSet();
      final templateItems = await database.getAllMealTemplateItems();

      expect(templateItems, isNotEmpty);
      for (final item in templateItems) {
        expect(foodIds, contains(item.foodId),
            reason: 'meal template item ${item.foodId} must resolve to a real seeded food');
      }
    });

    test(
      'every diet type\'s template ingredients resolve to a real seeded food -- '
      'regression for a bug where "Rice", "Ribeye Steak", "Beef Liver", "Firm Tofu", '
      '"Rice Noodles" and "Mixed Veg" had no exact match in the starter catalog and '
      'were silently dropped from every new user\'s generated meal templates',
      () async {
        // Expected item count when every referenced food actually resolves.
        const expectedItemCounts = {'omnivore': 12, 'carnivore': 5, 'herbivore': 12};

        for (final dietType in ['omnivore', 'carnivore', 'herbivore']) {
          final database = AppDatabase();
          final beforeTemplateIds = (await database.getAllMealTemplates()).map((t) => t.id).toSet();

          await MealTemplateGenerator(database, _profile(dietType: dietType)).generateTemplates();

          final newTemplateIds = (await database.getAllMealTemplates())
              .map((t) => t.id)
              .where((id) => !beforeTemplateIds.contains(id))
              .toSet();
          final newItems = (await database.getAllMealTemplateItems())
              .where((item) => newTemplateIds.contains(item.templateId));

          expect(newItems.length, expectedItemCounts[dietType]!,
              reason: '$dietType templates should have every ingredient resolve, none dropped');
          AppDatabase.resetForTesting();
        }
      },
    );
  });
}
