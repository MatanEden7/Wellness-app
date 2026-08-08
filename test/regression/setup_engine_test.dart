@Tags(['profile'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/services/setup_engine_service.dart';

/// Coverage for [SetupEngineService]: the Mifflin-St Jeor BMR formula, the
/// activity/goal multipliers that turn it into daily targets, and the
/// supporting lookups (workout split, meal distribution, food suggestions).
/// None of this had a fast test before -- it was only exercised indirectly
/// through onboarding and the Profile-page recompute, both of which need a
/// simulator to run.
void main() {
  late SetupEngineService engine;

  setUp(() => engine = SetupEngineService());

  group('calculateBMR', () {
    test('male uses the +5 constant', () {
      final bmr = engine.calculateBMR(sex: 'male', weightKg: 90, heightCm: 178, ageYears: 30);
      expect(bmr, 10 * 90 + 6.25 * 178 - 5 * 30 + 5);
    });

    test('female uses the -161 constant', () {
      final bmr = engine.calculateBMR(sex: 'female', weightKg: 65, heightCm: 165, ageYears: 28);
      expect(bmr, 10 * 65 + 6.25 * 165 - 5 * 28 - 161);
    });
  });

  group('calculateTDEE', () {
    const bmr = 1800.0;
    final expected = {
      'sedentary': bmr * 1.2,
      'light': bmr * 1.375,
      'moderate': bmr * 1.55,
      'active': bmr * 1.725,
      'very_active': bmr * 1.9,
    };

    for (final entry in expected.entries) {
      test('${entry.key} applies its documented multiplier', () {
        expect(engine.calculateTDEE(bmr, entry.key), entry.value);
      });
    }

    test('an unrecognized activity level falls back to sedentary (1.2x)', () {
      expect(engine.calculateTDEE(bmr, 'nonsense'), bmr * 1.2);
    });
  });

  group('calculateCalorieTarget', () {
    const tdee = 2500.0;

    test('fat_loss is a 20% deficit, not a flat 400 kcal', () {
      expect(engine.calculateCalorieTarget(tdee, 'fat_loss'), tdee * 0.8);
    });

    test('the fat_loss deficit is capped at 750 kcal for very high TDEEs', () {
      expect(engine.calculateCalorieTarget(5000, 'fat_loss'), 5000 - 750);
    });

    test('muscle_gain is a 10% surplus, floored at 150 and capped at 400', () {
      expect(engine.calculateCalorieTarget(tdee, 'muscle_gain'), tdee + 250);
      expect(engine.calculateCalorieTarget(1200, 'muscle_gain'), 1200 + 150);
      expect(engine.calculateCalorieTarget(5000, 'muscle_gain'), 5000 + 400);
    });

    test('maintenance and mobility_rehab hold at TDEE', () {
      expect(engine.calculateCalorieTarget(tdee, 'maintenance'), tdee);
      expect(engine.calculateCalorieTarget(tdee, 'mobility_rehab'), tdee);
    });

    test('an unrecognized goal defaults to TDEE, not a crash', () {
      expect(engine.calculateCalorieTarget(tdee, 'nonsense'), tdee);
    });

    test('never prescribes below the safe floor for the sex', () {
      // 1350 TDEE - 20% = 1080, under the 1200 kcal floor for women.
      expect(engine.calculateCalorieTarget(1350, 'fat_loss', sex: 'female'), 1200);
      // 1700 - 20% = 1360, under the 1500 kcal floor for men.
      expect(engine.calculateCalorieTarget(1700, 'fat_loss', sex: 'male'), 1500);
    });

    test('a TDEE already under the floor is not inflated up to it', () {
      expect(engine.calculateCalorieTarget(1100, 'fat_loss', sex: 'female'), 1100);
    });
  });

  group('calculateProteinTarget', () {
    test('grams-per-kg scale with how aggressive the goal is', () {
      expect(engine.calculateProteinTarget(80, 'fat_loss'), 80 * 2.2);
      expect(engine.calculateProteinTarget(80, 'muscle_gain'), 80 * 2.0);
      expect(engine.calculateProteinTarget(80, 'maintenance'), 80 * 1.8);
      expect(engine.calculateProteinTarget(80, 'mobility_rehab'), 80 * 1.8);
    });

    test('an unrecognized goal defaults to the maintenance ratio', () {
      expect(engine.calculateProteinTarget(80, 'nonsense'), 80 * 1.8);
    });

    test('scales against adjusted body weight above BMI 27.5', () {
      // 175cm -> BMI 27.5 is 84.2kg. A 120kg user counts only a quarter of
      // the 35.8kg excess, so ~93.1kg, not 120kg.
      final reference = SetupEngineService.proteinReferenceWeight(120, 175);
      expect(reference, closeTo(84.2 + 0.25 * (120 - 84.2), 0.1));
      expect(engine.calculateProteinTarget(120, 'fat_loss', heightCm: 175),
          closeTo(reference * 2.2, 0.1));
    });

    test('a healthy-BMI weight is used as-is', () {
      expect(SetupEngineService.proteinReferenceWeight(75, 180), 75);
    });

    test('caps at 40% of the calorie target when one is given', () {
      // 2.2 x 100kg = 220g = 880 kcal, over 40% of a 1800 kcal target.
      expect(
        engine.calculateProteinTarget(100, 'fat_loss', calorieTarget: 1800),
        1800 * 0.4 / 4,
      );
    });
  });

  group('calculateFatTarget', () {
    test('is a share of the calorie target, not a flat gram floor', () {
      expect(engine.calculateFatTarget(80, 2500, 'maintenance'),
          closeTo(2500 * 0.28 / 9, 0.01));
      expect(engine.calculateFatTarget(80, 2500, 'muscle_gain'),
          closeTo(2500 * 0.25 / 9, 0.01));
    });

    test('floors at the 0.6g/kg essential-fat minimum on very low budgets', () {
      // 0.28 x 1200 / 9 = 37g, under the 0.6 x 100 = 60g minimum.
      expect(engine.calculateFatTarget(100, 1200, 'fat_loss'), 60);
    });
  });

  group('calculateCarbsTarget', () {
    test('fills whatever calories protein and fat do not account for', () {
      // 2200 kcal, 180g protein (720 kcal), 70g fat (630 kcal) -> 850 kcal / 4
      final carbs = engine.calculateCarbsTarget(2200, 180, 70);
      expect(carbs, (2200 - 180 * 4 - 70 * 9) / 4);
    });

    test('floors at 0 instead of going negative when protein+fat exceed the target', () {
      // 180g protein (720) + 70g fat (630) = 1350 kcal, more than the 1000 target.
      final carbs = engine.calculateCarbsTarget(1000, 180, 70);
      expect(carbs, 0);
    });
  });

  group('calculateTargets', () {
    /// Every profile shape the onboarding form can actually produce.
    final profiles = [
      for (final sex in ['male', 'female'])
        for (final goal in ['fat_loss', 'muscle_gain', 'maintenance', 'mobility_rehab'])
          for (final activity in ['sedentary', 'moderate', 'very_active'])
            for (final body in [
              (age: 22, height: 155, weight: 45.0), // small and light
              (age: 35, height: 175, weight: 78.0), // mid
              (age: 60, height: 190, weight: 130.0), // large and heavy
            ])
              (sex: sex, goal: goal, activity: activity, body: body),
    ];

    for (final p in profiles) {
      final label = '${p.sex}/${p.goal}/${p.activity}/'
          '${p.body.weight.toInt()}kg@${p.body.height}cm';

      test('$label produces a coherent, safe target set', () {
        final t = engine.calculateTargets(
          sex: p.sex,
          weightKg: p.body.weight,
          heightCm: p.body.height,
          ageYears: p.body.age,
          goal: p.goal,
          activityLevel: p.activity,
        );

        // The four numbers agree with each other: this is what silently broke
        // before, when carbs clamped to 0 and nothing reconciled.
        expect(t.kcalFromMacros, closeTo(t.calories, 12),
            reason: '4P + 4C + 9F should reconstruct the calorie target');

        // Nothing is starvation-level or absurd.
        expect(t.calories, greaterThanOrEqualTo(1100));
        expect(t.calories, lessThan(6000));

        // Macros sit inside defensible ranges. Protein is checked per kg as
        // well as a share: a light, very active profile eats a lot of food
        // for its body weight, so an adequate 1.8 g/kg is legitimately only
        // ~13% of intake there.
        final proteinPct = t.proteinG * 4 / t.calories;
        final fatPct = t.fatG * 9 / t.calories;
        final carbsPct = t.carbsG * 4 / t.calories;
        expect(t.proteinG / p.body.weight, greaterThanOrEqualTo(1.2),
            reason: 'protein g/kg');
        expect(proteinPct, lessThanOrEqualTo(0.42), reason: 'protein share');
        expect(fatPct, inInclusiveRange(0.20, 0.45), reason: 'fat share');
        // Carbs are the remainder, so their share is widest: a 45kg very
        // active profile bulking needs ~2750 kcal but only ~80g of protein,
        // and the surplus has nowhere else to go.
        expect(carbsPct, inInclusiveRange(0.10, 0.65), reason: 'carb share');

        // Essential minimums are respected.
        expect(t.fatG, greaterThanOrEqualTo(p.body.weight * 0.6 - 1));
        expect(t.carbsG, greaterThan(0));
      });
    }

    test('the fat share is no longer a flat 0.6g/kg afterthought', () {
      final t = engine.calculateTargets(
        sex: 'male',
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        goal: 'maintenance',
        activityLevel: 'moderate',
      );
      // The old engine gave this profile a flat 48g of fat -- ~15% of intake,
      // with every calorie it did not claim dumped into carbs.
      expect(t.fatG, greaterThan(60));
      expect(t.fatG * 9 / t.calories, closeTo(0.28, 0.02));
    });

    test('a small sedentary woman cutting is not put under 1200 kcal', () {
      final t = engine.calculateTargets(
        sex: 'female',
        weightKg: 50,
        heightCm: 158,
        ageYears: 45,
        goal: 'fat_loss',
        activityLevel: 'sedentary',
      );
      // Old engine: TDEE 1322 - 400 = 922 kcal.
      expect(t.calories, greaterThanOrEqualTo(1200));
    });

    test('targets round to numbers a person can act on', () {
      final t = engine.calculateTargets(
        sex: 'male',
        weightKg: 90,
        heightCm: 178,
        ageYears: 30,
        goal: 'fat_loss',
        activityLevel: 'moderate',
      );
      expect(t.calories % 10, 0);
      expect(t.proteinG, t.proteinG.roundToDouble());
      expect(t.carbsG, t.carbsG.roundToDouble());
      expect(t.fatG, t.fatG.roundToDouble());
    });
  });

  test('createUserProfile assembles a profile whose fields match calculateTargets', () {
    final profile = engine.createUserProfile(
      sex: 'male',
      ageYears: 30,
      heightCm: 178,
      weightKg: 90,
      goal: 'fat_loss',
      activityLevel: 'moderate',
      trainingDaysPerWeek: 4,
      equipment: const ['dumbbells'],
      dietType: 'omnivore',
      mealCountPerDay: '3',
      exclusions: const [],
      injuries: const [],
    );

    final targets = engine.calculateTargets(
      sex: 'male',
      weightKg: 90,
      heightCm: 178,
      ageYears: 30,
      goal: 'fat_loss',
      activityLevel: 'moderate',
    );

    expect(profile.bmr, targets.bmr);
    expect(profile.tdee, targets.tdee);
    expect(profile.calorieTarget, targets.calories);
    expect(profile.proteinTargetG, targets.proteinG);
    expect(profile.fatTargetG, targets.fatG);
    expect(profile.carbsTargetG, targets.carbsG);
    // Defaults not passed explicitly.
    expect(profile.energyUnit, 'kcal');
    expect(profile.weightUnit, 'g');
  });

  group('getWorkoutSplit', () {
    test('5+ days a week gets a push/pull/legs split', () {
      expect(engine.getWorkoutSplit(5), 'ppl_5d');
      expect(engine.getWorkoutSplit(6), 'ppl_5d');
    });

    test('3-4 days a week gets a 3-day full body split', () {
      expect(engine.getWorkoutSplit(3), 'full_body_3d');
      expect(engine.getWorkoutSplit(4), 'full_body_3d');
    });

    test('fewer than 3 days still defaults to the 3-day split', () {
      expect(engine.getWorkoutSplit(1), 'full_body_3d');
      expect(engine.getWorkoutSplit(2), 'full_body_3d');
    });
  });

  group('getMealDistribution', () {
    test('each meal count has a distribution that sums to 1.0', () {
      for (final key in ['2', '3', '4', 'intermittent_fasting_16_8']) {
        final dist = engine.getMealDistribution(key);
        expect(dist.fold<double>(0, (a, b) => a + b), closeTo(1.0, 0.001),
            reason: '$key distribution should sum to 100%');
      }
    });

    test('an unrecognized meal count defaults to the 3-meal split', () {
      expect(engine.getMealDistribution('nonsense'), engine.getMealDistribution('3'));
    });
  });

  group('getWorkoutScheduleDays', () {
    test('day counts map to the documented weekday sets', () {
      expect(engine.getWorkoutScheduleDays(5), ['Mon', 'Tue', 'Thu', 'Fri', 'Sat']);
      expect(engine.getWorkoutScheduleDays(3), ['Mon', 'Wed', 'Fri']);
      expect(engine.getWorkoutScheduleDays(2), ['Mon', 'Thu']);
    });
  });

  group('getRehabExercises', () {
    test('returns exercises for every listed injury, concatenated', () {
      final exercises = engine.getRehabExercises(['shoulder', 'knee']);
      expect(exercises.any((e) => e['name'] == 'External Rotation (band)'), isTrue);
      expect(exercises.any((e) => e['name'] == 'Step-up (low box)'), isTrue);
      expect(exercises.length, 6); // 3 shoulder + 3 knee
    });

    test('"none" and unrecognized injuries contribute nothing', () {
      expect(engine.getRehabExercises(['none']), isEmpty);
      expect(engine.getRehabExercises(['elbow']), isEmpty); // not in rehabMap
    });
  });

  group('getFoodSuggestions', () {
    test('diet type picks the protein list; carnivore drops carbs/fats/veggies', () {
      final omni = engine.getFoodSuggestions('omnivore', []);
      expect(omni, contains('Chicken Breast'));
      expect(omni, contains('Rice'));

      final carnivore = engine.getFoodSuggestions('carnivore', []);
      expect(carnivore, contains('Ribeye Steak'));
      expect(carnivore, isNot(contains('Rice')));
      expect(carnivore, contains('Butter'));
    });

    test('exclusions filter out the matching foods regardless of diet type', () {
      final noDairy = engine.getFoodSuggestions('omnivore', ['dairy']);
      expect(noDairy, isNot(contains('Greek Yogurt')));

      final noGluten = engine.getFoodSuggestions('omnivore', ['gluten']);
      expect(noGluten, isNot(contains('Bread')));
      expect(noGluten, isNot(contains('Oats')));

      final noEggs = engine.getFoodSuggestions('omnivore', ['eggs']);
      expect(noEggs, isNot(contains('Eggs')));
    });
  });
}
