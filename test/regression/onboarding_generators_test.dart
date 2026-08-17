@Tags(['profile', 'catalog'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/app_language.dart';
import 'package:wellness_app/core/template_origin.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/meals/data/repositories.dart';
import 'package:wellness_app/features/meals/domain/food_tags.dart';
import 'package:wellness_app/features/workouts/domain/exercise_tags.dart';
import 'package:wellness_app/services/meal_template_generator.dart';
import 'package:wellness_app/services/user_profile_service.dart';
import 'package:wellness_app/services/workout_template_generator.dart';

/// Coverage for the two onboarding-time generators.
///
/// Both were rewritten to **select from the tagged catalog** via
/// `ProfileFit` rather than inventing their own content. The tests here
/// changed shape accordingly: the old ones asserted against the previous
/// design (a fixed "mobility pack", separate "rehab addons", and food
/// lookup by exact English name), all of which were the mechanism of the
/// bug rather than behaviour worth preserving -- name matching in
/// particular silently dropped items whenever a name didn't match exactly.
///
/// What these assert now is the property that actually matters and that the
/// old design could not provide: **everything generated is something this
/// specific user can eat or do.**
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
    test('does not invent exercises -- every pick comes from the library',
        () async {
      final db = AppDatabase();
      final libraryBefore =
          (await db.getAllExercises()).map((e) => e.id).toSet();

      await WorkoutTemplateGenerator(db, _profile(), AppLanguage.english)
          .generateTemplates();

      final libraryAfter =
          (await db.getAllExercises()).map((e) => e.id).toSet();
      expect(libraryAfter, libraryBefore,
          reason: 'the old generator inserted its own near-duplicate '
              "exercises ('Barbell Bench Press' alongside 'Bench Press')");

      for (final template in await db.getAllWorkoutTemplates()) {
        for (final te
            in await db.getTemplateExercisesByTemplateId(template.id)) {
          expect(libraryBefore, contains(te.exerciseId),
              reason: 'template references an exercise outside the library');
        }
      }
    });

    test('never picks an exercise the user lacks equipment for', () async {
      final db = AppDatabase();
      // Bodyweight only -- the case the old generator handled worst.
      await WorkoutTemplateGenerator(
              db, _profile(equipment: ['none']), AppLanguage.english)
          .generateTemplates();

      final byId = {for (final e in await db.getAllExercises()) e.id: e};
      var checked = 0;
      for (final template in await db.getAllWorkoutTemplates()) {
        // Built-ins are seeded before a profile exists and are filtered at
        // display time rather than deleted -- only assert on what this
        // generator produced.
        if (template.origin != TemplateOrigin.generated) continue;
        for (final te
            in await db.getTemplateExercisesByTemplateId(template.id)) {
          final exercise = byId[te.exerciseId]!;
          expect(exercise.equipment, contains(Equipment.bodyweight),
              reason: '${exercise.name} needs equipment this user lacks');
          checked++;
        }
      }
      expect(checked, greaterThan(0), reason: 'nothing was generated to check');
    });

    test('never picks an exercise contraindicated by an injury', () async {
      final db = AppDatabase();
      await WorkoutTemplateGenerator(
              db, _profile(injuries: ['shoulder', 'neck']), AppLanguage.english)
          .generateTemplates();

      final byId = {for (final e in await db.getAllExercises()) e.id: e};
      var checked = 0;
      for (final template in await db.getAllWorkoutTemplates()) {
        if (template.origin != TemplateOrigin.generated) continue;
        for (final te
            in await db.getTemplateExercisesByTemplateId(template.id)) {
          final exercise = byId[te.exerciseId]!;
          expect(
              exercise.contraindicatedFor, isNot(contains(BodyPart.shoulder)),
              reason: '${exercise.name} is unsafe for this shoulder injury');
          expect(exercise.contraindicatedFor, isNot(contains(BodyPart.neck)),
              reason: '${exercise.name} is unsafe for this neck injury');
          checked++;
        }
      }
      expect(checked, greaterThan(0));
    });

    test('more training days produces more distinct sessions', () async {
      final db = AppDatabase();
      final builtIn = (await db.getAllWorkoutTemplates()).length;

      await WorkoutTemplateGenerator(
              db, _profile(trainingDaysPerWeek: 3), AppLanguage.english)
          .generateTemplates();
      final afterThree = (await db.getAllWorkoutTemplates()).length - builtIn;

      AppDatabase.resetForTesting();
      final db2 = AppDatabase();
      final builtIn2 = (await db2.getAllWorkoutTemplates()).length;
      await WorkoutTemplateGenerator(
              db2, _profile(trainingDaysPerWeek: 5), AppLanguage.english)
          .generateTemplates();
      final afterFive = (await db2.getAllWorkoutTemplates()).length - builtIn2;

      expect(afterFive, greaterThan(afterThree));
    });

    test('generated templates are marked generated, so they stay replaceable',
        () async {
      final db = AppDatabase();
      final created =
          await WorkoutTemplateGenerator(db, _profile(), AppLanguage.english)
              .generateTemplates();

      expect(created, isNotEmpty);
      for (final template in created) {
        expect(template.origin, TemplateOrigin.generated);
      }
    });
  });

  group('MealTemplateGenerator', () {
    test('does not invent foods -- every item comes from the catalog',
        () async {
      final db = AppDatabase();
      final catalogBefore = (await db.getAllFoods()).map((f) => f.id).toSet();

      await MealTemplateGenerator(db, _profile(), AppLanguage.english)
          .generateTemplates();

      expect((await db.getAllFoods()).map((f) => f.id).toSet(), catalogBefore,
          reason: 'the old generator inserted its own per-diet food lists');

      for (final template in await db.getAllMealTemplates()) {
        for (final item
            in await db.getMealTemplateItemsByTemplateId(template.id)) {
          expect(catalogBefore, contains(item.foodId));
        }
      }
    });

    test('never includes a food the user excludes', () async {
      final db = AppDatabase();
      await MealTemplateGenerator(
              db,
              _profile(exclusions: ['dairy', 'gluten', 'nuts']),
              AppLanguage.english)
          .generateTemplates();

      final byId = {for (final f in await db.getAllFoods()) f.id: f};
      var checked = 0;
      for (final template in await db.getAllMealTemplates()) {
        // Built-in templates are seeded before any profile exists and are
        // filtered at display time, not deleted -- only assert on what this
        // generator produced.
        if (template.origin != TemplateOrigin.generated) continue;
        for (final item
            in await db.getMealTemplateItemsByTemplateId(template.id)) {
          final food = byId[item.foodId]!;
          expect(food.tags, isNot(contains(FoodTag.dairy)));
          expect(food.tags, isNot(contains(FoodTag.gluten)));
          expect(food.tags, isNot(contains(FoodTag.nuts)));
          checked++;
        }
      }
      expect(checked, greaterThan(0), reason: 'nothing was generated to check');
    });

    test('a vegan gets nothing of animal origin', () async {
      final db = AppDatabase();
      await MealTemplateGenerator(
              db, _profile(dietType: 'herbivore'), AppLanguage.english)
          .generateTemplates();

      final byId = {for (final f in await db.getAllFoods()) f.id: f};
      var checked = 0;
      for (final template in await db.getAllMealTemplates()) {
        if (template.origin != TemplateOrigin.generated) continue;
        for (final item
            in await db.getMealTemplateItemsByTemplateId(template.id)) {
          final food = byId[item.foodId]!;
          expect(food.tags, isNot(contains(FoodTag.meat)),
              reason: '${food.name} is meat');
          expect(food.tags, isNot(contains(FoodTag.fish)),
              reason: '${food.name} is fish');
          expect(food.tags, isNot(contains(FoodTag.animalProduct)),
              reason: '${food.name} is an animal product');
          checked++;
        }
      }
      expect(checked, greaterThan(0));
    });

    test('the hardest profile still gets fed', () async {
      // Vegan avoiding soy, gluten and nuts -- the combination that had
      // essentially nothing before the catalog was expanded.
      final db = AppDatabase();
      final created = await MealTemplateGenerator(
              db,
              _profile(
                dietType: 'herbivore',
                exclusions: [
                  'soy',
                  'gluten',
                  'nuts',
                  'dairy',
                  'eggs',
                  'shellfish'
                ],
              ),
              AppLanguage.english)
          .generateTemplates();

      expect(created, isNotEmpty,
          reason: 'this profile must still receive meal templates');

      for (final template in created) {
        final items = await db.getMealTemplateItemsByTemplateId(template.id);
        expect(items, isNotEmpty, reason: '${template.name} is empty');
      }
    });

    test('meal count drives how many templates are generated', () async {
      final db = AppDatabase();
      final two = await MealTemplateGenerator(
              db, _profile(mealCountPerDay: '2'), AppLanguage.english)
          .generateTemplates();

      AppDatabase.resetForTesting();
      final db2 = AppDatabase();
      final four = await MealTemplateGenerator(
              db2, _profile(mealCountPerDay: '4'), AppLanguage.english)
          .generateTemplates();

      expect(two.length, 2);
      expect(four.length, 4);
    });

    test('generated templates are marked generated', () async {
      final db = AppDatabase();
      final created =
          await MealTemplateGenerator(db, _profile(), AppLanguage.english)
              .generateTemplates();

      expect(created, isNotEmpty);
      for (final template in created) {
        expect(template.origin, TemplateOrigin.generated);
      }
    });

    test('portions land in a sane range, not 2kg of rice', () async {
      final db = AppDatabase();
      final created =
          await MealTemplateGenerator(db, _profile(), AppLanguage.english)
              .generateTemplates();

      final byId = {for (final f in await db.getAllFoods()) f.id: f};
      for (final template in created) {
        for (final item
            in await db.getMealTemplateItemsByTemplateId(template.id)) {
          final food = byId[item.foodId]!;
          expect(item.amount, greaterThan(0));
          // Bounds are per unit, because `amount` means different things per
          // food: 4.0 of a `100g` food is 400g, but 4.0 of Milk is four
          // millilitres. This assertion used to apply the 100g bound to
          // everything, which is the same unit-blindness that produced the
          // original "Milk x1.00" bug -- see MealPortionSolver.
          final max = food.unit == 'ml' || food.unit == 'g' ? 500.0 : 12.0;
          expect(item.amount, lessThanOrEqualTo(max),
              reason: '${food.name} (${food.unit}) portion '
                  '${item.amount} is implausible');
        }
      }
    });
  });

  test('generators leave the food catalog usable by ProfileFit end to end',
      () async {
    // Guards the seam the shared converter bug lived in: if foodItemFromData
    // ever stops carrying tags again, generation silently stops filtering.
    final db = AppDatabase();
    final tagged = (await db.getAllFoods())
        .map(foodItemFromData)
        .where((f) => f.tags.isNotEmpty);

    expect(tagged, isNotEmpty,
        reason: 'the converter dropped tags once already -- see '
            'tag_round_trip_test.dart');
  });
}
