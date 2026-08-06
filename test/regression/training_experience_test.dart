@Tags(['profile'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/services/profile_fit.dart';
import 'package:wellness_app/services/setup_engine_service.dart';
import 'package:wellness_app/services/user_profile_service.dart';

/// `trainingExperience`: the field that turns a rep range into an actual
/// starting weight.
///
/// Deliberately separate from `activityLevel`, which is a calorie input and a
/// poor proxy for strength -- an active postman is not an experienced lifter.
/// Getting it wrong prescribes a load someone cannot safely handle, so the
/// absent-value behaviour is a safety property, not a convenience.
UserProfile _profile({String experience = 'beginner'}) => UserProfile(
      sex: 'male',
      ageYears: 30,
      heightCm: 178,
      weightKg: 80,
      goal: 'muscle_gain',
      activityLevel: 'moderate',
      trainingDaysPerWeek: 4,
      trainingExperience: experience,
      equipment: const ['dumbbells'],
      dietType: 'omnivore',
      mealCountPerDay: '3',
      exclusions: const [],
      injuries: const [],
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

  test('defaults to beginner, the lightest prescription', () {
    // Every profile saved before this field existed. Defaulting to anything
    // heavier would silently over-load users who never answered.
    final restored = UserProfile.fromJson({
      ...(_profile().toJson())..remove('trainingExperience'),
    });

    expect(restored.trainingExperience, 'beginner');
  });

  test('round-trips through JSON', () {
    final restored = UserProfile.fromJson(
        jsonDecode(jsonEncode(_profile(experience: 'advanced').toJson())));

    expect(restored.trainingExperience, 'advanced');
  });

  test('copyWith carries it', () {
    expect(_profile().copyWith(trainingExperience: 'intermediate').trainingExperience,
        'intermediate');
    expect(_profile(experience: 'advanced').copyWith(ageYears: 31).trainingExperience,
        'advanced',
        reason: 'an unrelated edit dropped it');
  });

  test('the setup engine carries it onto the profile it builds', () {
    final built = SetupEngineService().createUserProfile(
      sex: 'female',
      ageYears: 28,
      heightCm: 165,
      weightKg: 60,
      goal: 'muscle_gain',
      activityLevel: 'moderate',
      trainingDaysPerWeek: 4,
      trainingExperience: 'intermediate',
      equipment: const [],
      dietType: 'omnivore',
      mealCountPerDay: '3',
      exclusions: const [],
      injuries: const [],
      energyUnit: 'kcal',
      weightUnit: 'g',
    );

    expect(built.trainingExperience, 'intermediate',
        reason: 'onboarding collects it and it never reaches the profile');
  });

  test('changing it offers a regeneration', () {
    // Experience sets every prescribed load and the volume a plan targets, so
    // the existing templates are wrong the moment it changes.
    expect(
      ProfileFit.contentAffectingFieldsChanged(
          _profile(), _profile(experience: 'advanced')),
      isTrue,
    );
  });

  test('changing something cosmetic still does not offer one', () {
    expect(
      ProfileFit.contentAffectingFieldsChanged(
          _profile(), _profile().copyWith(ageYears: 31)),
      isFalse,
      reason: 'regeneration throws away templates; it must not be offered '
          'for a field that changes nothing about them',
    );
  });
}
