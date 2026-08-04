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

    test('fat_loss is a 400 kcal deficit', () {
      expect(engine.calculateCalorieTarget(tdee, 'fat_loss'), tdee - 400);
    });

    test('muscle_gain is a 250 kcal surplus', () {
      expect(engine.calculateCalorieTarget(tdee, 'muscle_gain'), tdee + 250);
    });

    test('maintenance and mobility_rehab hold at TDEE', () {
      expect(engine.calculateCalorieTarget(tdee, 'maintenance'), tdee);
      expect(engine.calculateCalorieTarget(tdee, 'mobility_rehab'), tdee);
    });

    test('an unrecognized goal defaults to TDEE, not a crash', () {
      expect(engine.calculateCalorieTarget(tdee, 'nonsense'), tdee);
    });
  });

  group('calculateProteinTarget', () {
    test('grams-per-kg scale with how aggressive the goal is', () {
      expect(engine.calculateProteinTarget(80, 'fat_loss'), 80 * 2.2);
      expect(engine.calculateProteinTarget(80, 'muscle_gain'), 80 * 2.0);
      expect(engine.calculateProteinTarget(80, 'maintenance'), 80 * 1.8);
      expect(engine.calculateProteinTarget(80, 'mobility_rehab'), 80 * 1.6);
    });

    test('an unrecognized goal defaults to the maintenance ratio', () {
      expect(engine.calculateProteinTarget(80, 'nonsense'), 80 * 1.8);
    });
  });

  test('calculateFatTarget is a flat 0.6g/kg floor regardless of calories/protein', () {
    expect(engine.calculateFatTarget(80, 1000, 999), 80 * 0.6);
    expect(engine.calculateFatTarget(80, 5000, 1), 80 * 0.6);
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

  group('getMacroPercentages', () {
    test('each goal has its own documented split', () {
      expect(SetupEngineService.getMacroPercentages('fat_loss'),
          {'protein': 35, 'fat': 30, 'carbs': 35});
      expect(SetupEngineService.getMacroPercentages('muscle_gain'),
          {'protein': 30, 'fat': 25, 'carbs': 45});
    });

    test('an unrecognized goal falls back to maintenance', () {
      expect(SetupEngineService.getMacroPercentages('nonsense'),
          SetupEngineService.getMacroPercentages('maintenance'));
    });
  });

  test('createUserProfile assembles a profile whose fields match the individual calculators', () {
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

    final bmr = engine.calculateBMR(sex: 'male', weightKg: 90, heightCm: 178, ageYears: 30);
    final tdee = engine.calculateTDEE(bmr, 'moderate');
    final cal = engine.calculateCalorieTarget(tdee, 'fat_loss');
    final pro = engine.calculateProteinTarget(90, 'fat_loss');
    final fat = engine.calculateFatTarget(90, cal, pro);
    final carbs = engine.calculateCarbsTarget(cal, pro, fat);

    expect(profile.bmr, bmr);
    expect(profile.tdee, tdee);
    expect(profile.calorieTarget, cal);
    expect(profile.proteinTargetG, pro);
    expect(profile.fatTargetG, fat);
    expect(profile.carbsTargetG, carbs);
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
