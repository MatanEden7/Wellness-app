@Tags(['catalog', 'profile'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/meals/data/repositories.dart';
import 'package:wellness_app/features/meals/domain/models.dart';
import 'package:wellness_app/features/workouts/domain/exercise_tags.dart';
import 'package:wellness_app/features/workouts/domain/models.dart';
import 'package:wellness_app/services/profile_fit.dart';
import 'package:wellness_app/services/user_profile_service.dart';

/// Proves the seeded catalog is actually *sufficient* -- that every profile
/// a user can build in onboarding has enough food to eat and enough
/// exercises to train with.
///
/// This is the test that makes "add more content" an objective requirement
/// rather than a judgement call. Before the tagging work, a herbivore who
/// also excluded soy had essentially nothing: tofu was the only plant
/// protein in the catalog. Rather than eyeballing whether the additions were
/// enough, this walks the whole combination space and fails with the exact
/// profile that came up short.
///
/// It is deliberately a *coverage* test, not a snapshot test: it asserts
/// "at least one usable option per muscle group", never "exactly these
/// items", so adding or renaming catalog content doesn't break it -- only
/// leaving a real gap does.
void main() {
  late List<FoodItem> foods;
  late List<Exercise> exercises;

  setUpAll(() {
    AppDatabase.resetForTesting();
    final db = AppDatabase();
    // Read through the same converter the app uses, so the test exercises
    // the real data path rather than a parallel one.
    foods = db.debugSeededFoods.map(foodItemFromData).toList();
    exercises = db.debugSeededExercises
        .map((d) => Exercise(
              id: d.id,
              name: d.name,
              primaryMuscle: d.primaryMuscle,
              unit: d.unit,
              notes: d.notes,
              equipment: d.equipment,
              contraindicatedFor: d.contraindicatedFor,
            ))
        .toList();
  });

  UserProfile profileWith({
    required String dietType,
    required List<String> exclusions,
    required List<String> equipment,
    required List<String> injuries,
  }) =>
      UserProfile(
        sex: 'male',
        ageYears: 30,
        heightCm: 180,
        weightKg: 80,
        goal: 'maintenance',
        activityLevel: 'moderate',
        trainingDaysPerWeek: 3,
        equipment: equipment,
        dietType: dietType,
        mealCountPerDay: '3',
        exclusions: exclusions,
        injuries: injuries,
        energyUnit: 'kcal',
        weightUnit: 'g',
        bmr: 1800,
        tdee: 2500,
        calorieTarget: 2500,
        proteinTargetG: 150,
        fatTargetG: 70,
        carbsTargetG: 280,
      );

  /// Every subset of the six exclusion chips -- 64 combinations, including
  /// the worst case of excluding all of them at once.
  List<List<String>> allExclusionSubsets() {
    const all = ['dairy', 'gluten', 'nuts', 'eggs', 'shellfish', 'soy'];
    final subsets = <List<String>>[];
    for (var mask = 0; mask < (1 << all.length); mask++) {
      final subset = <String>[];
      for (var i = 0; i < all.length; i++) {
        if (mask & (1 << i) != 0) subset.add(all[i]);
      }
      subsets.add(subset);
    }
    return subsets;
  }

  group('food coverage', () {
    /// A food worth building a meal around. Compared per *unit* rather than
    /// per 100g because the catalog mixes units (piece, tbsp, ml), and a
    /// blanket per-100g threshold would wrongly discount a whole egg.
    bool isProteinSource(FoodItem f) => f.proteinPerUnit >= 5;

    test('every diet x exclusion combination leaves real food available', () {
      for (final diet in const ['omnivore', 'carnivore', 'herbivore']) {
        for (final exclusions in allExclusionSubsets()) {
          final profile = profileWith(
            dietType: diet,
            exclusions: exclusions,
            equipment: const ['none'],
            injuries: const [],
          );

          final available =
              foods.where((f) => ProfileFit.foodFits(f, profile)).toList();
          final proteins = available.where(isProteinSource).toList();

          final label = '$diet + excluding ${exclusions.isEmpty ? "nothing" : exclusions.join("/")}';

          expect(proteins.length, greaterThanOrEqualTo(3),
              reason: '$label has only ${proteins.length} protein source(s): '
                  '${proteins.map((f) => f.name).toList()}');
          expect(available.length, greaterThanOrEqualTo(15),
              reason: '$label leaves only ${available.length} foods in total');
        }
      }
    });

    test('the hardest realistic case is specifically covered', () {
      // Vegan who also avoids soy, gluten and nuts -- the combination that
      // had almost nothing before the catalog additions, and the reason
      // hemp/pumpkin/sunflower/chia seeds were added.
      final profile = profileWith(
        dietType: 'herbivore',
        exclusions: const ['soy', 'gluten', 'nuts', 'dairy', 'eggs', 'shellfish'],
        equipment: const ['none'],
        injuries: const [],
      );

      final proteins = foods
          .where((f) => ProfileFit.foodFits(f, profile) && f.proteinPerUnit >= 8)
          .map((f) => f.name)
          .toList();

      expect(proteins.length, greaterThanOrEqualTo(5),
          reason: 'a vegan avoiding soy, gluten and nuts still needs real '
              'protein options; found: $proteins');
    });
  });

  group('exercise coverage', () {
    /// The muscle groups a program needs to cover to be worth calling one.
    /// Cardio is checked separately since it is optional for strength work
    /// but essential for the mobility/rehab and no-equipment cases.
    const requiredGroups = {
      'Chest': ['Chest'],
      'Back': ['Back'],
      'Legs': ['Quadriceps', 'Hamstrings', 'Glutes', 'Calves'],
      'Core': ['Core'],
    };

    void expectFullBodyCoverage(UserProfile profile, String label) {
      final available =
          exercises.where((e) => ProfileFit.exerciseFits(e, profile)).toList();

      requiredGroups.forEach((groupName, muscles) {
        final hit = available.where((e) => muscles.contains(e.primaryMuscle));
        expect(hit, isNotEmpty,
            reason: '$label has no $groupName exercise available');
      });
    }

    test('every equipment option supports a full-body program', () {
      for (final equipment in const [
        ['none'],
        ['dumbbells'],
        ['barbell_rack'],
        ['machines'],
        ['bands'],
        ['kettlebells'],
        ['cable'],
        ['pullup_bar'],
      ]) {
        expectFullBodyCoverage(
          profileWith(
            dietType: 'omnivore',
            exclusions: const [],
            equipment: equipment,
            injuries: const [],
          ),
          'equipment=${equipment.join("/")}',
        );
      }
    });

    test('every single injury still leaves a full-body program, even with no equipment', () {
      for (final injury in const [
        'shoulder',
        'back',
        'knee',
        'ankle',
        'elbow',
        'hip',
        'neck',
      ]) {
        expectFullBodyCoverage(
          profileWith(
            dietType: 'omnivore',
            exclusions: const [],
            equipment: const ['none'],
            injuries: [injury],
          ),
          'no equipment + $injury injury',
        );
      }
    });

    test('the worst case -- no equipment and every injury at once -- still trains', () {
      // Not a realistic user, but it is reachable through the UI, and it is
      // the single strongest guarantee that joint-sparing alternatives exist
      // for every muscle group.
      final profile = profileWith(
        dietType: 'omnivore',
        exclusions: const [],
        equipment: const ['none'],
        injuries: const ['shoulder', 'back', 'knee', 'ankle', 'elbow', 'hip', 'neck'],
      );

      expectFullBodyCoverage(profile, 'no equipment + every injury');
    });

    test('a neck injury rules out overhead and heavy axial loading', () {
      // Guards the clinically-motivated tagging rather than just the count:
      // if someone later untags these, filtering would quietly start
      // recommending the exact movements a cervical strain should avoid.
      final profile = profileWith(
        dietType: 'omnivore',
        exclusions: const [],
        equipment: const ['barbell_rack', 'dumbbells'],
        injuries: const ['neck'],
      );

      final availableNames = exercises
          .where((e) => ProfileFit.exerciseFits(e, profile))
          .map((e) => e.name)
          .toSet();

      expect(availableNames, isNot(contains('Overhead Press')));
      expect(availableNames, isNot(contains('Deadlift')));
      expect(availableNames, isNot(contains('Squats')),
          reason: 'the barbell back squat loads the cervical spine');
      expect(availableNames, contains('Landmine Press'),
          reason: 'pressing at 45 degrees is the standard neck-safe swap and '
              'must survive the filter');
    });
  });

  test('every seeded food and exercise carries deliberate tagging', () {
    // Untagged content fits everyone by design (see ProfileFit), which is
    // right for user-added entries but would be a silent hole in the seeded
    // catalog -- an untagged steak would show up for vegans.
    final untaggedExercises =
        exercises.where((e) => e.equipment.isEmpty).map((e) => e.name).toList();
    expect(untaggedExercises, isEmpty,
        reason: 'seeded exercises must declare their equipment');

    // Foods legitimately have no tags when they are plain plants (rice,
    // broccoli), so the assertion is narrower: anything obviously of animal
    // origin must be tagged, checked via a spot list.
    for (final name in const ['Chicken Breast', 'Salmon', 'Eggs', 'Milk', 'Honey']) {
      final food = foods.firstWhere((f) => f.name == name);
      expect(food.tags, isNotEmpty, reason: '$name must carry origin tags');
    }
  });
}
