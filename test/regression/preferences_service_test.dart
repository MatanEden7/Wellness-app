@Tags(['persistence'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/services/preferences_service.dart';

/// Coverage for [PreferencesService]: enum-backed preferences with safe
/// fallbacks, nutrition-goal round-trips (including clearing via null),
/// range validation, and the WCAG contrast helpers used by the theme/color
/// editors. None of this had a fast test before -- the goal round-trip in
/// particular is exactly what the Profile-page write-through
/// (see integration_test/regression/profile_preferences_sync_test.dart)
/// depends on to keep the dashboard rings in sync.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PreferencesService(await SharedPreferences.getInstance());
  });

  group('enum preferences default safely when unset', () {
    test('primaryNutritionMetric defaults to calories', () {
      expect(prefs.primaryNutritionMetric, NutritionMetric.calories);
    });

    test('globalTimeframeMode defaults to day', () {
      expect(prefs.globalTimeframeMode, TimeframeMode.day);
    });

    test('workoutMetricMode defaults to count', () {
      expect(prefs.workoutMetricMode, WorkoutMetricMode.count);
    });
  });

  group('enum preferences round-trip', () {
    test('primaryNutritionMetric persists across get calls', () async {
      await prefs.setPrimaryNutritionMetric(NutritionMetric.protein);
      expect(prefs.primaryNutritionMetric, NutritionMetric.protein);
    });

    test('globalTimeframeMode persists across get calls', () async {
      await prefs.setGlobalTimeframeMode(TimeframeMode.week);
      expect(prefs.globalTimeframeMode, TimeframeMode.week);
    });
  });

  group('per-section timeframe overrides', () {
    test('fall back to the global mode when unset', () async {
      await prefs.setGlobalTimeframeMode(TimeframeMode.week);
      expect(prefs.getMealsTimeframeOverride(), isNull);
      expect(prefs.getEffectiveMealsTimeframe(), TimeframeMode.week);
    });

    test('take priority over the global mode once set', () async {
      await prefs.setGlobalTimeframeMode(TimeframeMode.week);
      await prefs.setMealsTimeframeOverride(TimeframeMode.day);
      expect(prefs.getEffectiveMealsTimeframe(), TimeframeMode.day);
      // Other sections are unaffected.
      expect(prefs.getEffectiveWorkoutsTimeframe(), TimeframeMode.week);
    });

    test('setting an override back to null clears it, not just sets day',
        () async {
      await prefs.setSleepTimeframeOverride(TimeframeMode.day);
      await prefs.setSleepTimeframeOverride(null);
      expect(prefs.getSleepTimeframeOverride(), isNull);
    });
  });

  group('nutrition goals', () {
    test('are null (unset) by default', () {
      expect(prefs.calorieGoal, isNull);
      expect(prefs.proteinGoal, isNull);
      expect(prefs.carbsGoal, isNull);
      expect(prefs.fatGoal, isNull);
    });

    test('round-trip through set/get', () async {
      await prefs.setCalorieGoal(2200);
      await prefs.setProteinGoal(180);
      await prefs.setCarbsGoal(220);
      await prefs.setFatGoal(70);

      expect(prefs.calorieGoal, 2200);
      expect(prefs.proteinGoal, 180);
      expect(prefs.carbsGoal, 220);
      expect(prefs.fatGoal, 70);
    });

    test('setting a goal to null clears it rather than storing null-as-0',
        () async {
      await prefs.setCalorieGoal(2200);
      await prefs.setCalorieGoal(null);
      expect(prefs.calorieGoal, isNull);
    });

    test('isValidCalorieGoal accepts the documented 800-20000 range', () {
      expect(prefs.isValidCalorieGoal(800), isTrue);
      expect(prefs.isValidCalorieGoal(20000), isTrue);
      expect(prefs.isValidCalorieGoal(799.9), isFalse);
      expect(prefs.isValidCalorieGoal(20000.1), isFalse);
    });

    test('isValidMacroGoal accepts the documented 10-600 range', () {
      expect(prefs.isValidMacroGoal(10), isTrue);
      expect(prefs.isValidMacroGoal(600), isTrue);
      expect(prefs.isValidMacroGoal(9.9), isFalse);
      expect(prefs.isValidMacroGoal(600.1), isFalse);
    });
  });

  group('custom nutrition colors', () {
    test('default to the documented colors when unset', () {
      expect(prefs.calorieColor, PreferencesService.defaultCalorieColor);
      expect(prefs.proteinColor, PreferencesService.defaultProteinColor);
    });

    test('round-trip through set/get', () async {
      await prefs.setCalorieColor(const Color(0xFF009688));
      expect(prefs.calorieColor, const Color(0xFF009688));
    });

    test('resetColors reverts all four to defaults', () async {
      await prefs.setCalorieColor(const Color(0xFF009688));
      await prefs.setProteinColor(const Color(0xFF009688));
      await prefs.resetColors();
      expect(prefs.calorieColor, PreferencesService.defaultCalorieColor);
      expect(prefs.proteinColor, PreferencesService.defaultProteinColor);
    });
  });

  group('getColorForMetric', () {
    test('returns the per-metric custom color when useThemeColors is off',
        () async {
      await prefs.setCalorieColor(const Color(0xFF009688));
      expect(
          prefs.getColorForMetric(NutritionMetric.calories,
              themeColor: Colors.pink),
          const Color(0xFF009688));
    });

    test('returns the theme color once useThemeColors is on', () async {
      await prefs.setUseThemeColors(true);
      await prefs.setCalorieColor(const Color(0xFF009688));
      expect(
          prefs.getColorForMetric(NutritionMetric.calories,
              themeColor: Colors.pink),
          Colors.pink);
    });

    test(
        'falls back to the per-metric color if useThemeColors is on but no theme color given',
        () async {
      await prefs.setUseThemeColors(true);
      await prefs.setCalorieColor(const Color(0xFF009688));
      expect(prefs.getColorForMetric(NutritionMetric.calories),
          const Color(0xFF009688));
    });
  });

  group('WCAG contrast helpers', () {
    test('black on white is maximally accessible', () {
      expect(
          PreferencesService.calculateContrastRatio(Colors.black, Colors.white),
          closeTo(21, 0.01));
      expect(PreferencesService.isColorAccessible(Colors.black, Colors.white),
          isTrue);
    });

    test('two near-identical colors are not accessible', () {
      const a = Color(0xFFAAAAAA);
      const b = Color(0xFFB0B0B0);
      expect(PreferencesService.isColorAccessible(a, b), isFalse);
    });

    test('contrast ratio is symmetric regardless of argument order', () {
      final ab = PreferencesService.calculateContrastRatio(
          Colors.orange, Colors.white);
      final ba = PreferencesService.calculateContrastRatio(
          Colors.white, Colors.orange);
      expect(ab, ba);
    });

    test('ensureContrast returns the same color when already accessible', () {
      expect(PreferencesService.ensureContrast(Colors.black, Colors.white),
          Colors.black);
    });

    test('ensureContrast darkens a too-light color against a light background',
        () {
      const tooLight = Color(0xFFF0F0F0);
      final fixed = PreferencesService.ensureContrast(tooLight, Colors.white);
      expect(PreferencesService.isColorAccessible(fixed, Colors.white), isTrue);
    });

    test('ensureContrast lightens a too-dark color against a dark background',
        () {
      const darkBg = Color(0xFF101010);
      const tooDark = Color(0xFF1A1A1A);
      final fixed = PreferencesService.ensureContrast(tooDark, darkBg);
      expect(PreferencesService.isColorAccessible(fixed, darkBg), isTrue);
    });
  });

  group('workout timer settings', () {
    test('default to 90s rest, sound on, full volume', () {
      expect(prefs.defaultRestTime, 90);
      expect(prefs.restTimerSoundEnabled, isTrue);
      expect(prefs.restTimerVolume, 1.0);
    });

    test('round-trip through set/get', () async {
      await prefs.setDefaultRestTime(120);
      await prefs.setRestTimerSoundEnabled(false);
      await prefs.setRestTimerVolume(0.5);

      expect(prefs.defaultRestTime, 120);
      expect(prefs.restTimerSoundEnabled, isFalse);
      expect(prefs.restTimerVolume, 0.5);
    });
  });

  test(
      'resetAllCustomColors reverts nutrition, section, and theme colors together',
      () async {
    await prefs.setCalorieColor(const Color(0xFF009688));
    await prefs.setMealsColor(const Color(0xFF009688));
    await prefs.setCustomPrimaryColor(const Color(0xFF009688));

    await prefs.resetAllCustomColors();

    expect(prefs.calorieColor, PreferencesService.defaultCalorieColor);
    expect(prefs.mealsColor, PreferencesService.defaultMealsColor);
    expect(
        prefs.customPrimaryColor, PreferencesService.defaultCustomPrimaryColor);
  });
}
