@Tags(['profile', 'catalog', 'nutrition'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/template_origin.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/workouts/domain/exercise_tags.dart';
import 'package:wellness_app/services/meal_template_generator.dart';
import 'package:wellness_app/services/user_profile_service.dart';
import 'package:wellness_app/services/workout_template_generator.dart';

/// Quality, not just legality.
///
/// The earlier tests proved generated content *respected the constraints* --
/// no dairy for someone avoiding dairy, no barbell for someone without one.
/// They said nothing about whether the result was any good, and it wasn't:
/// a vegan's generated day came to 3676 kcal against a 2500 target (+47%),
/// with 276g of fat against a 70g target, and "Milk x1.00" meant one
/// millilitre. Every assertion here would have failed then.
UserProfile _profile({
  String dietType = 'omnivore',
  List<String> exclusions = const [],
  List<String> equipment = const ['dumbbells', 'barbell_rack', 'pullup_bar'],
  List<String> injuries = const [],
  int trainingDaysPerWeek = 3,
  String mealCountPerDay = '3',
}) =>
    UserProfile(
      sex: 'male', ageYears: 30, heightCm: 180, weightKg: 80,
      goal: 'maintenance', activityLevel: 'moderate',
      trainingDaysPerWeek: trainingDaysPerWeek, equipment: equipment,
      dietType: dietType, mealCountPerDay: mealCountPerDay,
      exclusions: exclusions, injuries: injuries,
      energyUnit: 'kcal', weightUnit: 'g',
      bmr: 1800, tdee: 2500, calorieTarget: 2500,
      proteinTargetG: 150, fatTargetG: 70, carbsTargetG: 280,
    );

/// Every profile combination worth asserting nutrition accuracy on.
final _profiles = <String, UserProfile>{
  'omnivore, 3 meals': _profile(),
  'omnivore, 2 meals': _profile(mealCountPerDay: '2'),
  'omnivore, 4 meals': _profile(mealCountPerDay: '4'),
  'intermittent fasting': _profile(mealCountPerDay: 'intermittent_fasting_16_8'),
  'vegan': _profile(dietType: 'herbivore'),
  'vegan, no soy/gluten/nuts': _profile(
    dietType: 'herbivore',
    exclusions: ['soy', 'gluten', 'nuts', 'dairy', 'eggs', 'shellfish'],
  ),
  'dairy + gluten free': _profile(exclusions: ['dairy', 'gluten']),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(AppDatabase.resetForTesting);

  group('meal nutrition accuracy', () {
    _profiles.forEach((label, profile) {
      test('$label: a generated day lands near every macro target', () async {
        AppDatabase.resetForTesting();
        final db = AppDatabase();
        final created =
            await MealTemplateGenerator(db, profile).generateTemplates();
        expect(created, isNotEmpty, reason: '$label got no meal templates');

        final foods = {for (final f in await db.getAllFoods()) f.id: f};
        var kcal = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0;
        for (final t in created) {
          for (final i in await db.getMealTemplateItemsByTemplateId(t.id)) {
            final f = foods[i.foodId]!;
            kcal += f.kcalPerUnit * i.amount;
            protein += f.proteinPerUnit * i.amount;
            carbs += f.carbsPerUnit * i.amount;
            fat += f.fatPerUnit * i.amount;
          }
        }

        // 20%, not tighter, and that is a real limitation rather than a
        // comfortable bound: with portion sizes clamped to sane servings
        // (<=400g of a 100g-unit food) and only 3-4 components per meal, the
        // solver cannot always hit protein AND calories at once. It
        // prioritises protein, so calories run high -- currently ~+17% worst
        // case, down from +47% before this pass. Closing the rest needs
        // either more components per meal or per-food serving sizes, both of
        // which are bigger changes than this one.
        expect(kcal, closeTo(2500, 2500 * 0.20),
            reason: '$label daily calories were $kcal against a 2500 target');
        // Protein is the anchor's job; looser because portion bounds can cap
        // a low-density anchor (400g of lentils is the sane maximum).
        expect(protein, greaterThan(150 * 0.7),
            reason: '$label protein was only $protein against 150');
        // Fat used to run 4x over. This is the assertion that would have
        // caught it.
        expect(fat, lessThan(70 * 2.0),
            reason: '$label fat was $fat against a 70g target');
        expect(carbs, greaterThan(280 * 0.4),
            reason: '$label carbs were only $carbs against 280');
      });
    });

    test('meal count always matches what the user asked for', () async {
      for (final entry in {'2': 2, '3': 3, '4': 4}.entries) {
        AppDatabase.resetForTesting();
        final db = AppDatabase();
        final created = await MealTemplateGenerator(
                db, _profile(mealCountPerDay: entry.key))
            .generateTemplates();
        expect(created.length, entry.value,
            reason: 'asked for ${entry.key} meals, got ${created.length}');
      }
    });

    test('no meal lists the same food twice', () async {
      final db = AppDatabase();
      final created = await MealTemplateGenerator(db, _profile()).generateTemplates();
      for (final t in created) {
        final ids = (await db.getMealTemplateItemsByTemplateId(t.id))
            .map((i) => i.foodId)
            .toList();
        expect(ids.toSet().length, ids.length,
            reason: '${t.name} repeats a food (kale classified as both a '
                'carb source and a vegetable)');
      }
    });

    test('portions are physically sensible for their unit', () async {
      final db = AppDatabase();
      final created = await MealTemplateGenerator(db, _profile()).generateTemplates();
      final foods = {for (final f in await db.getAllFoods()) f.id: f};
      for (final t in created) {
        for (final i in await db.getMealTemplateItemsByTemplateId(t.id)) {
          final f = foods[i.foodId]!;
          if (f.unit == 'ml') {
            // "Milk x1.00" used to mean one millilitre.
            expect(i.amount, greaterThanOrEqualTo(50),
                reason: '${f.name}: ${i.amount}ml is not a serving');
          } else if (f.unit == '100g') {
            expect(i.amount, inInclusiveRange(0.25, 4.0),
                reason: '${f.name}: ${i.amount * 100}g is implausible');
          } else {
            expect(i.amount, greaterThan(0));
            expect(i.amount, lessThanOrEqualTo(12));
          }
        }
      }
    });
  });

  group('workout plan matches the profile', () {
    test('one training session per requested day, for every frequency', () async {
      for (var days = 1; days <= 7; days++) {
        AppDatabase.resetForTesting();
        final db = AppDatabase();
        final created = await WorkoutTemplateGenerator(
                db, _profile(trainingDaysPerWeek: days))
            .generateTemplates();
        final training =
            created.where((t) => !t.name.startsWith('Physiotherapy')).length;
        expect(training, days,
            reason: 'asked to train $days days/week, got $training sessions');
      }
    });

    test('session names stay distinct when the split repeats', () async {
      final db = AppDatabase();
      final created =
          await WorkoutTemplateGenerator(db, _profile(trainingDaysPerWeek: 6))
              .generateTemplates();
      final names = created.map((t) => t.name).toList();
      expect(names.toSet().length, names.length, reason: 'duplicate names: $names');
    });

    test('every injury gets its own physiotherapy session', () async {
      for (final injury in BodyPart.values) {
        AppDatabase.resetForTesting();
        final db = AppDatabase();
        final created = await WorkoutTemplateGenerator(
                db, _profile(injuries: [injury.profileId]))
            .generateTemplates();
        final physio =
            created.where((t) => t.name.startsWith('Physiotherapy')).toList();
        expect(physio, hasLength(1),
            reason: 'no physiotherapy session for a ${injury.name} injury');
        expect(physio.single.name, contains(injury.label));
      }
    });

    test('physio sessions contain genuinely rehabilitative work', () async {
      final db = AppDatabase();
      final created =
          await WorkoutTemplateGenerator(db, _profile(injuries: ['shoulder']))
              .generateTemplates();
      final physio = created.firstWhere((t) => t.name.startsWith('Physiotherapy'));

      final exercises = {for (final e in await db.getAllExercises()) e.id: e};
      final items = await db.getTemplateExercisesByTemplateId(physio.id);
      expect(items, isNotEmpty);
      for (final item in items) {
        // Drawn from rehabFor, not merely "not contraindicated" -- being safe
        // with a bad shoulder is not the same as rehabilitating one.
        expect(exercises[item.exerciseId]!.rehabFor, contains(BodyPart.shoulder),
            reason: '${exercises[item.exerciseId]!.name} is not rehab work');
      }
    });

    test('no session is left nearly empty by contraindications', () async {
      // A shoulder+neck injury guts Push day; the backfill should top it up.
      final db = AppDatabase();
      final created = await WorkoutTemplateGenerator(
              db, _profile(injuries: ['shoulder', 'neck'], trainingDaysPerWeek: 5))
          .generateTemplates();
      for (final t in created.where((t) => !t.name.startsWith('Physiotherapy'))) {
        final count = (await db.getTemplateExercisesByTemplateId(t.id)).length;
        expect(count, greaterThanOrEqualTo(4),
            reason: '${t.name} only has $count exercises');
      }
    });
  });
}
