@Tags(['i18n'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:wellness_app/features/meals/domain/models.dart';
import 'package:wellness_app/features/workouts/domain/models.dart';
import 'package:wellness_app/services/language_service.dart';

/// Regression coverage for the nameHe/displayName() bilingual fallback
/// added to FoodItem, Exercise, WorkoutTemplate, and MealTemplate: English
/// always shows the English name; Hebrew shows the Hebrew name only when
/// one has actually been set (and isn't just whitespace), otherwise it
/// falls back to English rather than showing a blank/missing label.
void main() {
  group('FoodItem.displayName', () {
    test('always shows English for AppLanguage.english', () {
      final food = FoodItem.create(
          name: 'Chicken Breast',
          nameHe: 'חזה עוף',
          unit: '100g',
          kcalPerUnit: 165,
          proteinPerUnit: 31,
          carbsPerUnit: 0,
          fatPerUnit: 3.6);
      expect(food.displayName(AppLanguage.english), 'Chicken Breast');
    });

    test('shows Hebrew for AppLanguage.hebrew when set', () {
      final food = FoodItem.create(
          name: 'Chicken Breast',
          nameHe: 'חזה עוף',
          unit: '100g',
          kcalPerUnit: 165,
          proteinPerUnit: 31,
          carbsPerUnit: 0,
          fatPerUnit: 3.6);
      expect(food.displayName(AppLanguage.hebrew), 'חזה עוף');
    });

    test(
        'falls back to English for Hebrew when nameHe is null (current seed data state)',
        () {
      final food = FoodItem.create(
          name: 'Chicken Breast',
          unit: '100g',
          kcalPerUnit: 165,
          proteinPerUnit: 31,
          carbsPerUnit: 0,
          fatPerUnit: 3.6);
      expect(food.displayName(AppLanguage.hebrew), 'Chicken Breast');
    });

    test('falls back to English for Hebrew when nameHe is blank', () {
      final food = FoodItem.create(
          name: 'Chicken Breast',
          nameHe: '   ',
          unit: '100g',
          kcalPerUnit: 165,
          proteinPerUnit: 31,
          carbsPerUnit: 0,
          fatPerUnit: 3.6);
      expect(food.displayName(AppLanguage.hebrew), 'Chicken Breast');
    });
  });

  group('Exercise.displayName / displayPrimaryMuscle', () {
    test('falls back to English when untranslated', () {
      final exercise = Exercise.create(
          name: 'Push-ups', primaryMuscle: 'Chest', unit: 'bodyweight');
      expect(exercise.displayName(AppLanguage.hebrew), 'Push-ups');
      expect(exercise.displayPrimaryMuscle(AppLanguage.hebrew), 'Chest');
    });

    test('shows Hebrew when set', () {
      final exercise = Exercise.create(
        name: 'Push-ups',
        nameHe: 'שכיבות סמיכה',
        primaryMuscle: 'Chest',
        primaryMuscleHe: 'חזה',
        unit: 'bodyweight',
      );
      expect(exercise.displayName(AppLanguage.hebrew), 'שכיבות סמיכה');
      expect(exercise.displayPrimaryMuscle(AppLanguage.hebrew), 'חזה');
      expect(exercise.displayName(AppLanguage.english), 'Push-ups');
    });
  });

  group('WorkoutTemplate.displayName / displayNotes', () {
    test('falls back to English when untranslated', () {
      final template = WorkoutTemplate.create(
          name: 'Full-Body Beginner', notes: 'A simple starting point.');
      expect(template.displayName(AppLanguage.hebrew), 'Full-Body Beginner');
      expect(template.displayNotes(AppLanguage.hebrew),
          'A simple starting point.');
    });
  });

  group('MealTemplate.displayName / displayDescription', () {
    test('falls back to English when untranslated', () {
      final template = MealTemplate.create(
          name: 'Balanced Breakfast', description: 'Oats, yogurt, banana.');
      expect(template.displayName(AppLanguage.hebrew), 'Balanced Breakfast');
      expect(template.displayDescription(AppLanguage.hebrew),
          'Oats, yogurt, banana.');
    });

    test('shows Hebrew when set', () {
      final template = MealTemplate.create(
        name: 'Balanced Breakfast',
        nameHe: 'ארוחת בוקר מאוזנת',
        description: 'Oats, yogurt, banana.',
        descriptionHe: 'שיבולת שועל, יוגורט, בננה.',
      );
      expect(template.displayName(AppLanguage.hebrew), 'ארוחת בוקר מאוזנת');
      expect(template.displayDescription(AppLanguage.hebrew),
          'שיבולת שועל, יוגורט, בננה.');
    });
  });

  group('FoodItem.matchesSearch', () {
    final hummus = FoodItem.create(
      name: 'Hummus',
      nameHe: 'חומוס',
      unit: '100g',
      kcalPerUnit: 166,
      proteinPerUnit: 7.9,
      carbsPerUnit: 14.3,
      fatPerUnit: 9.6,
    );
    final whey = FoodItem.create(
      name: 'Whey Protein',
      nameHe: 'אבקת חלבון מי גבינה',
      brand: 'Concentrate, per 30g scoop',
      unit: 'scoop',
      kcalPerUnit: 120,
      proteinPerUnit: 24,
      carbsPerUnit: 3,
      fatPerUnit: 1.5,
    );

    test('matches the Hebrew name even in an English session', () {
      // The picker is one list; search has no idea what language is selected,
      // and it should not need to.
      expect(hummus.matchesSearch('חומ'), isTrue);
      expect(hummus.matchesSearch('humm'), isTrue);
    });

    test('matches the English name and brand for a Hebrew-named food', () {
      expect(whey.matchesSearch('whey'), isTrue);
      expect(whey.matchesSearch('scoop'), isTrue);
      expect(whey.matchesSearch('חלבון'), isTrue);
    });

    test('is case insensitive and ignores surrounding whitespace', () {
      expect(hummus.matchesSearch('  HUMMUS '), isTrue);
    });

    test('an empty query matches everything, so the list is not blank', () {
      expect(hummus.matchesSearch(''), isTrue);
      expect(hummus.matchesSearch('   '), isTrue);
    });

    test('does not match something absent from either name', () {
      expect(hummus.matchesSearch('falafel'), isFalse);
    });
  });
}
