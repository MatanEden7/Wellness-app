@Tags(['profile', 'catalog'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/template_origin.dart';
import 'package:wellness_app/features/meals/domain/food_tags.dart';
import 'package:wellness_app/features/meals/domain/models.dart';
import 'package:wellness_app/features/workouts/domain/exercise_tags.dart';
import 'package:wellness_app/features/workouts/domain/models.dart';
import 'package:wellness_app/services/profile_fit.dart';
import 'package:wellness_app/services/user_profile_service.dart';

/// Coverage for [ProfileFit], the single source of truth for "does this
/// content suit this user?". Everything downstream -- catalog filtering, both
/// generators, and regenerate-on-profile-change -- reads through it, so its
/// rules are worth pinning precisely.
UserProfile _profile({
  String dietType = 'omnivore',
  List<String> exclusions = const [],
  List<String> equipment = const ['none'],
  List<String> injuries = const [],
  int trainingDaysPerWeek = 3,
  String mealCountPerDay = '3',
  String goal = 'maintenance',
  double weightKg = 80,
}) =>
    UserProfile(
      sex: 'male',
      ageYears: 30,
      heightCm: 180,
      weightKg: weightKg,
      goal: goal,
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
      fatTargetG: 70,
      carbsTargetG: 280,
    );

FoodItem _food(String name, Set<FoodTag> tags) => FoodItem(
      id: name,
      name: name,
      unit: '100g',
      kcalPerUnit: 100,
      proteinPerUnit: 10,
      carbsPerUnit: 10,
      fatPerUnit: 5,
      tags: tags,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Exercise _exercise(
  String name, {
  Set<Equipment> equipment = const {},
  Set<BodyPart> contraindicatedFor = const {},
}) =>
    Exercise(
      id: name,
      name: name,
      unit: 'kg',
      equipment: equipment,
      contraindicatedFor: contraindicatedFor,
    );

void main() {
  group('foods: exclusions', () {
    test('a food carrying an excluded allergen does not fit', () {
      final yogurt =
          _food('Greek Yogurt', {FoodTag.dairy, FoodTag.animalProduct});
      final result =
          ProfileFit.foodFit(yogurt, _profile(exclusions: ['dairy']));

      expect(result.fits, isFalse);
      expect(result.failure, FitFailure.exclusion);
      expect(result.detail, FoodTag.dairy,
          reason: 'the UI names the offending tag in its badge');
    });

    test('the same food fits when that exclusion is not set', () {
      final yogurt =
          _food('Greek Yogurt', {FoodTag.dairy, FoodTag.animalProduct});
      expect(ProfileFit.foodFits(yogurt, _profile()), isTrue);
    });

    test('every onboarding exclusion id maps to a tag', () {
      // If a new exclusion chip is ever added without a matching FoodTag,
      // it would silently filter nothing -- exactly the class of bug the
      // hardcoded name lists used to cause.
      for (final id in const [
        'dairy',
        'gluten',
        'nuts',
        'eggs',
        'shellfish',
        'soy'
      ]) {
        expect(FoodTag.forExclusion(id), isNotNull,
            reason: '$id has no FoodTag');
      }
    });

    test('the "none" chip is not treated as an allergen', () {
      final chicken = _food('Chicken', {FoodTag.meat});
      expect(
          ProfileFit.foodFits(chicken, _profile(exclusions: ['none'])), isTrue);
    });
  });

  group('foods: diet type', () {
    test('herbivore rejects meat, fish and non-flesh animal products alike',
        () {
      final profile = _profile(dietType: 'herbivore');

      expect(
          ProfileFit.foodFits(_food('Beef', {FoodTag.meat}), profile), isFalse);
      expect(ProfileFit.foodFits(_food('Salmon', {FoodTag.fish}), profile),
          isFalse);
      expect(
          ProfileFit.foodFits(
              _food('Eggs', {FoodTag.eggs, FoodTag.animalProduct}), profile),
          isFalse,
          reason: 'eggs come from an animal without being one -- this is the '
              'distinction animalProduct exists to draw');
    });

    test('herbivore accepts plant foods', () {
      final profile = _profile(dietType: 'herbivore');
      expect(ProfileFit.foodFits(_food('Lentils', {}), profile), isTrue);
      expect(
          ProfileFit.foodFits(_food('Tofu', {FoodTag.soy}), profile), isTrue);
    });

    test('carnivore does not hide plant foods', () {
      // Deliberate: carnivore says what the user eats, not what is unsafe.
      // Hiding vegetables would remove things they cook with.
      final profile = _profile(dietType: 'carnivore');
      expect(ProfileFit.foodFits(_food('Broccoli', {}), profile), isTrue);
    });

    test('diet failure is reported ahead of an exclusion failure', () {
      // A steak for a herbivore should say "you don't eat meat", not
      // something narrower.
      final profile = _profile(dietType: 'herbivore', exclusions: ['dairy']);
      final cheese = _food('Cheddar', {FoodTag.dairy, FoodTag.animalProduct});

      expect(ProfileFit.foodFit(cheese, profile).failure, FitFailure.diet);
    });
  });

  test('untagged food fits every profile', () {
    // A user's own un-labelled food must never vanish from their catalog.
    final profile =
        _profile(dietType: 'herbivore', exclusions: ['dairy', 'nuts']);
    expect(ProfileFit.foodFits(_food('My Recipe', {}), profile), isTrue);
  });

  group('exercises: equipment', () {
    test('bodyweight work fits even with no equipment', () {
      final pushups = _exercise('Push-ups', equipment: {Equipment.bodyweight});
      expect(ProfileFit.exerciseFits(pushups, _profile(equipment: ['none'])),
          isTrue);
    });

    test('barbell work does not fit someone with no equipment', () {
      final bench =
          _exercise('Bench Press', equipment: {Equipment.barbellRack});
      final result =
          ProfileFit.exerciseFit(bench, _profile(equipment: ['none']));

      expect(result.fits, isFalse);
      expect(result.failure, FitFailure.equipment);
    });

    test('an exercise fits if the user owns ANY of its listed equipment', () {
      // Exercises list every option they can be done with, so owning one is
      // enough -- a row can be done with dumbbells or a cable machine.
      final row =
          _exercise('Row', equipment: {Equipment.dumbbells, Equipment.cable});
      expect(
          ProfileFit.exerciseFits(row, _profile(equipment: ['cable'])), isTrue);
      expect(ProfileFit.exerciseFits(row, _profile(equipment: ['dumbbells'])),
          isTrue);
      expect(ProfileFit.exerciseFits(row, _profile(equipment: ['bands'])),
          isFalse);
    });

    test('every onboarding equipment id maps to an Equipment value', () {
      for (final id in const [
        'none',
        'dumbbells',
        'barbell_rack',
        'machines',
        'bands',
        'kettlebells',
        'cable',
        'pullup_bar',
      ]) {
        expect(Equipment.forProfileId(id), isNotNull, reason: '$id unmapped');
      }
    });
  });

  group('exercises: injuries', () {
    test('a contraindicated exercise does not fit', () {
      final ohp = _exercise('Overhead Press',
          equipment: {Equipment.barbellRack},
          contraindicatedFor: {BodyPart.shoulder, BodyPart.neck});
      final result = ProfileFit.exerciseFit(
          ohp, _profile(equipment: ['barbell_rack'], injuries: ['neck']));

      expect(result.fits, isFalse);
      expect(result.failure, FitFailure.injury);
      expect(result.detail, BodyPart.neck);
    });

    test('injury outranks equipment: unsafe is reported even if owned', () {
      final ohp = _exercise('Overhead Press',
          equipment: {Equipment.barbellRack},
          contraindicatedFor: {BodyPart.shoulder});
      expect(
        ProfileFit.exerciseFit(
            ohp, _profile(equipment: ['none'], injuries: ['shoulder'])).failure,
        FitFailure.injury,
      );
    });

    test('neck is a real, mappable injury', () {
      // Added specifically because heavy axial loading and overhead work are
      // documented aggravators of cervical strain, and several seeded
      // exercises fall in that category.
      expect(BodyPart.forProfileId('neck'), BodyPart.neck);
    });

    test('every onboarding injury id maps to a BodyPart', () {
      for (final id in const [
        'shoulder',
        'back',
        'knee',
        'ankle',
        'elbow',
        'hip',
        'neck',
      ]) {
        expect(BodyPart.forProfileId(id), isNotNull, reason: '$id unmapped');
      }
    });
  });

  group('templates', () {
    test('a meal template fails if any single item fails', () {
      final foods = {
        'oats': _food('oats', {FoodTag.gluten}),
        'banana': _food('banana', {}),
      };
      final template = MealTemplate(
        id: 't',
        name: 'Porridge',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        items: const [
          MealTemplateItem(
              id: 'i1', templateId: 't', foodId: 'banana', amount: 1),
          MealTemplateItem(
              id: 'i2', templateId: 't', foodId: 'oats', amount: 1),
        ],
      );

      final result = ProfileFit.mealTemplateFit(
          template, foods, _profile(exclusions: ['gluten']));
      expect(result.fits, isFalse);
      expect(result.detail, FoodTag.gluten);
    });

    test('a dangling foodId does not hide the whole template', () {
      final template = MealTemplate(
        id: 't',
        name: 'Broken',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        items: const [
          MealTemplateItem(
              id: 'i1', templateId: 't', foodId: 'ghost', amount: 1),
        ],
      );

      expect(
          ProfileFit.mealTemplateFits(
              template, {}, _profile(exclusions: ['gluten'])),
          isTrue,
          reason: 'referential integrity problems should not masquerade as '
              'dietary ones');
    });

    test('a workout template fails if any exercise is contraindicated', () {
      final exercises = {
        'ohp': _exercise('OHP', contraindicatedFor: {BodyPart.shoulder}),
        'squat': _exercise('Squat', equipment: {Equipment.bodyweight}),
      };
      const template = WorkoutTemplate(
        id: 'w',
        name: 'Upper',
        exercises: [
          TemplateExercise(
              id: 'e1', templateId: 'w', exerciseId: 'squat', orderIndex: 0),
          TemplateExercise(
              id: 'e2', templateId: 'w', exerciseId: 'ohp', orderIndex: 1),
        ],
      );

      final result = ProfileFit.workoutTemplateFit(
          template, exercises, _profile(injuries: ['shoulder']));
      expect(result.fits, isFalse);
      expect(result.failure, FitFailure.injury);
    });
  });

  group('regeneration triggers', () {
    test('content-affecting fields trigger regeneration', () {
      expect(
        ProfileFit.contentAffectingFieldsChanged(
            _profile(), _profile(dietType: 'herbivore')),
        isTrue,
      );
      expect(
        ProfileFit.contentAffectingFieldsChanged(
            _profile(), _profile(equipment: ['dumbbells'])),
        isTrue,
      );
      expect(
        ProfileFit.contentAffectingFieldsChanged(
            _profile(), _profile(injuries: ['knee'])),
        isTrue,
      );
      expect(
        ProfileFit.contentAffectingFieldsChanged(
            _profile(), _profile(trainingDaysPerWeek: 5)),
        isTrue,
      );
    });

    test('target-only fields do NOT trigger regeneration', () {
      // Per the product decision, goal drives calories and macros only --
      // not which templates you get. Weight/activity are likewise numeric.
      expect(
        ProfileFit.contentAffectingFieldsChanged(
            _profile(), _profile(goal: 'fat_loss')),
        isFalse,
        reason: 'goal is target-only by design',
      );
      expect(
        ProfileFit.contentAffectingFieldsChanged(
            _profile(), _profile(weightKg: 95)),
        isFalse,
      );
    });

    test('exclusion order does not count as a change', () {
      expect(
        ProfileFit.contentAffectingFieldsChanged(
          _profile(exclusions: ['dairy', 'nuts']),
          _profile(exclusions: ['nuts', 'dairy']),
        ),
        isFalse,
      );
    });

    test('only generated templates are replaceable', () {
      expect(ProfileFit.isReplaceable(TemplateOrigin.generated), isTrue);
      expect(ProfileFit.isReplaceable(TemplateOrigin.user), isFalse,
          reason: 'never destroy what the user built');
    });

    test('a template with no recorded origin is treated as the user\'s', () {
      expect(TemplateOrigin.fromKey(null), TemplateOrigin.user);
      expect(TemplateOrigin.fromKey('nonsense'), TemplateOrigin.user);
    });
  });
}
