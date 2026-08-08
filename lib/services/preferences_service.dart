import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for the preferences service
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError('PreferencesService provider must be overridden');
});

// Enums for preferences
enum NutritionMetric { calories, protein, carbs, fat }
enum TimeframeMode { day, week }
enum WorkoutMetricMode { count, time }

class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // Keys for shared preferences
  static const String _primaryNutritionMetricKey = 'primary_nutrition_metric';
  static const String _globalTimeframeModeKey = 'global_timeframe_mode';
  static const String _workoutMetricModeKey = 'workout_metric_mode';
  static const String _mealsTimeframeModeKey = 'meals_timeframe_mode';
  static const String _workoutsTimeframeModeKey = 'workouts_timeframe_mode';
  static const String _sleepTimeframeModeKey = 'sleep_timeframe_mode';
  
  // Nutrition goals keys
  static const String _calorieGoalKey = 'calorie_goal';
  static const String _proteinGoalKey = 'protein_goal';
  static const String _carbsGoalKey = 'carbs_goal';
  static const String _fatGoalKey = 'fat_goal';
  static const String _sleepGoalHoursKey = 'sleep_goal_hours';

  // Custom color keys
  static const String _calorieColorKey = 'calorie_color';
  static const String _proteinColorKey = 'protein_color';
  static const String _carbsColorKey = 'carbs_color';
  static const String _fatColorKey = 'fat_color';
  static const String _useThemeColorsKey = 'use_theme_colors';
  
  // Section color keys
  static const String _mealsColorKey = 'meals_color';
  static const String _workoutsColorKey = 'workouts_color';
  static const String _sleepColorKey = 'sleep_color';
  
  // Custom theme color keys
  static const String _customPrimaryColorKey = 'custom_primary_color';
  static const String _customBackgroundColorKey = 'custom_background_color';
  static const String _customSurfaceColorKey = 'custom_surface_color';
  
  // Workout timer settings keys
  static const String _defaultRestTimeKey = 'default_rest_time';
  static const String _restTimerSoundEnabledKey = 'rest_timer_sound_enabled';
  static const String _restTimerVolumeKey = 'rest_timer_volume';
  
  // Default colors
  static const Color defaultCalorieColor = Colors.orange;
  static const Color defaultProteinColor = Colors.red;
  static const Color defaultCarbsColor = Colors.blue;
  static const Color defaultFatColor = Colors.purple;
  static const Color defaultMealsColor = Colors.orange;
  static const Color defaultWorkoutsColor = Colors.blue;
  static const Color defaultSleepColor = Colors.purple;
  static const Color defaultCustomPrimaryColor = Color(0xFF6366F1); // Indigo
  static const Color defaultCustomBackgroundColor = Color(0xFFF8FAFC); // Light gray
  static const Color defaultCustomSurfaceColor = Colors.white;

  // Primary nutrition metric (Enhancement 3)
  NutritionMetric get primaryNutritionMetric {
    final value = _prefs.getString(_primaryNutritionMetricKey);
    return NutritionMetric.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NutritionMetric.calories,
    );
  }

  Future<void> setPrimaryNutritionMetric(NutritionMetric metric) async {
    await _prefs.setString(_primaryNutritionMetricKey, metric.name);
  }

  // Global timeframe mode (Enhancement 4)
  TimeframeMode get globalTimeframeMode {
    final value = _prefs.getString(_globalTimeframeModeKey);
    return TimeframeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TimeframeMode.day,
    );
  }

  Future<void> setGlobalTimeframeMode(TimeframeMode mode) async {
    await _prefs.setString(_globalTimeframeModeKey, mode.name);
  }

  // Workout metric mode (Enhancement 5)
  WorkoutMetricMode get workoutMetricMode {
    final value = _prefs.getString(_workoutMetricModeKey);
    return WorkoutMetricMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WorkoutMetricMode.count,
    );
  }

  Future<void> setWorkoutMetricMode(WorkoutMetricMode mode) async {
    await _prefs.setString(_workoutMetricModeKey, mode.name);
  }

  // Section-specific timeframe overrides (Enhancement 4)
  TimeframeMode? getMealsTimeframeOverride() {
    final value = _prefs.getString(_mealsTimeframeModeKey);
    return value != null 
        ? TimeframeMode.values.firstWhere((e) => e.name == value)
        : null;
  }

  Future<void> setMealsTimeframeOverride(TimeframeMode? mode) async {
    if (mode != null) {
      await _prefs.setString(_mealsTimeframeModeKey, mode.name);
    } else {
      await _prefs.remove(_mealsTimeframeModeKey);
    }
  }

  TimeframeMode? getWorkoutsTimeframeOverride() {
    final value = _prefs.getString(_workoutsTimeframeModeKey);
    return value != null 
        ? TimeframeMode.values.firstWhere((e) => e.name == value)
        : null;
  }

  Future<void> setWorkoutsTimeframeOverride(TimeframeMode? mode) async {
    if (mode != null) {
      await _prefs.setString(_workoutsTimeframeModeKey, mode.name);
    } else {
      await _prefs.remove(_workoutsTimeframeModeKey);
    }
  }

  TimeframeMode? getSleepTimeframeOverride() {
    final value = _prefs.getString(_sleepTimeframeModeKey);
    return value != null 
        ? TimeframeMode.values.firstWhere((e) => e.name == value)
        : null;
  }

  Future<void> setSleepTimeframeOverride(TimeframeMode? mode) async {
    if (mode != null) {
      await _prefs.setString(_sleepTimeframeModeKey, mode.name);
    } else {
      await _prefs.remove(_sleepTimeframeModeKey);
    }
  }

  // Effective timeframe mode for each section (considers global + override)
  TimeframeMode getEffectiveMealsTimeframe() {
    return getMealsTimeframeOverride() ?? globalTimeframeMode;
  }

  TimeframeMode getEffectiveWorkoutsTimeframe() {
    return getWorkoutsTimeframeOverride() ?? globalTimeframeMode;
  }

  TimeframeMode getEffectiveSleepTimeframe() {
    return getSleepTimeframeOverride() ?? globalTimeframeMode;
  }

  // Nutrition Goals
  double? get calorieGoal {
    return _prefs.getDouble(_calorieGoalKey);
  }

  Future<void> setCalorieGoal(double? goal) async {
    if (goal != null) {
      await _prefs.setDouble(_calorieGoalKey, goal);
    } else {
      await _prefs.remove(_calorieGoalKey);
    }
  }

  double? get proteinGoal {
    return _prefs.getDouble(_proteinGoalKey);
  }

  Future<void> setProteinGoal(double? goal) async {
    if (goal != null) {
      await _prefs.setDouble(_proteinGoalKey, goal);
    } else {
      await _prefs.remove(_proteinGoalKey);
    }
  }

  double? get carbsGoal {
    return _prefs.getDouble(_carbsGoalKey);
  }

  Future<void> setCarbsGoal(double? goal) async {
    if (goal != null) {
      await _prefs.setDouble(_carbsGoalKey, goal);
    } else {
      await _prefs.remove(_carbsGoalKey);
    }
  }

  double? get fatGoal {
    return _prefs.getDouble(_fatGoalKey);
  }

  Future<void> setFatGoal(double? goal) async {
    if (goal != null) {
      await _prefs.setDouble(_fatGoalKey, goal);
    } else {
      await _prefs.remove(_fatGoalKey);
    }
  }

  /// Hours of sleep a night that count as "goal met".
  ///
  /// Unlike the macro goals this always has a value: the analytics screen
  /// scores sleep as one of four daily goals, and a null goal would silently
  /// drop the whole day's score by 25% rather than showing anything wrong.
  double get sleepGoalHours {
    return _prefs.getDouble(_sleepGoalHoursKey) ?? defaultSleepGoalHours;
  }

  Future<void> setSleepGoalHours(double hours) async {
    await _prefs.setDouble(_sleepGoalHoursKey, hours);
  }

  static const double defaultSleepGoalHours = 8.0;

  bool isValidSleepGoal(double value) => value >= 4 && value <= 12;

  // Validation for nutrition goals
  bool isValidCalorieGoal(double value) {
    return value >= 800 && value <= 20000;
  }

  bool isValidMacroGoal(double value) {
    return value >= 10 && value <= 600;
  }

  // Utility methods for getting metric values
  String getNutritionMetricLabel(NutritionMetric metric) {
    switch (metric) {
      case NutritionMetric.calories:
        return 'Calories';
      case NutritionMetric.protein:
        return 'Protein';
      case NutritionMetric.carbs:
        return 'Carbs';
      case NutritionMetric.fat:
        return 'Fat';
    }
  }

  String getWorkoutMetricLabel(WorkoutMetricMode mode) {
    switch (mode) {
      case WorkoutMetricMode.count:
        return 'Workouts';
      case WorkoutMetricMode.time:
        return 'Minutes';
    }
  }

  String getTimeframeModeLabel(TimeframeMode mode) {
    switch (mode) {
      case TimeframeMode.day:
        return 'Day';
      case TimeframeMode.week:
        return 'Week';
    }
  }
  
  // Use theme colors setting
  bool get useThemeColors {
    return _prefs.getBool(_useThemeColorsKey) ?? false;
  }
  
  Future<void> setUseThemeColors(bool value) async {
    await _prefs.setBool(_useThemeColorsKey, value);
  }
  
  // Custom colors for nutrition macros
  Color get calorieColor {
    final colorValue = _prefs.getInt(_calorieColorKey);
    return colorValue != null ? Color(colorValue) : defaultCalorieColor;
  }
  
  Future<void> setCalorieColor(Color color) async {
    await _prefs.setInt(_calorieColorKey, color.toARGB32());
  }
  
  Color get proteinColor {
    final colorValue = _prefs.getInt(_proteinColorKey);
    return colorValue != null ? Color(colorValue) : defaultProteinColor;
  }
  
  Future<void> setProteinColor(Color color) async {
    await _prefs.setInt(_proteinColorKey, color.toARGB32());
  }
  
  Color get carbsColor {
    final colorValue = _prefs.getInt(_carbsColorKey);
    return colorValue != null ? Color(colorValue) : defaultCarbsColor;
  }
  
  Future<void> setCarbsColor(Color color) async {
    await _prefs.setInt(_carbsColorKey, color.toARGB32());
  }
  
  Color get fatColor {
    final colorValue = _prefs.getInt(_fatColorKey);
    return colorValue != null ? Color(colorValue) : defaultFatColor;
  }
  
  Future<void> setFatColor(Color color) async {
    await _prefs.setInt(_fatColorKey, color.toARGB32());
  }
  
  // Get color for a specific metric (considering theme colors setting)
  Color getColorForMetric(NutritionMetric metric, {Color? themeColor}) {
    if (useThemeColors && themeColor != null) {
      return themeColor;
    }
    
    switch (metric) {
      case NutritionMetric.calories:
        return calorieColor;
      case NutritionMetric.protein:
        return proteinColor;
      case NutritionMetric.carbs:
        return carbsColor;
      case NutritionMetric.fat:
        return fatColor;
    }
  }
  
  // WCAG contrast validation
  static double calculateLuminance(Color color) {
    return color.computeLuminance();
  }
  
  static double calculateContrastRatio(Color color1, Color color2) {
    final lum1 = calculateLuminance(color1);
    final lum2 = calculateLuminance(color2);
    final lighter = lum1 > lum2 ? lum1 : lum2;
    final darker = lum1 > lum2 ? lum2 : lum1;
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  static bool isColorAccessible(Color color, Color background) {
    final contrastRatio = calculateContrastRatio(color, background);
    return contrastRatio >= 4.5; // WCAG AA standard
  }
  
  // Adjust color for better contrast if needed
  static Color ensureContrast(Color color, Color background) {
    if (isColorAccessible(color, background)) {
      return color;
    }
    
    // Make color lighter or darker to meet contrast requirements
    final backgroundLum = calculateLuminance(background);
    if (backgroundLum > 0.5) {
      // Light background, make color darker
      return HSLColor.fromColor(color).withLightness(0.3).toColor();
    } else {
      // Dark background, make color lighter
      return HSLColor.fromColor(color).withLightness(0.7).toColor();
    }
  }
  
  // Section colors
  Color get mealsColor {
    final colorValue = _prefs.getInt(_mealsColorKey);
    return colorValue != null ? Color(colorValue) : defaultMealsColor;
  }
  
  Future<void> setMealsColor(Color color) async {
    await _prefs.setInt(_mealsColorKey, color.toARGB32());
  }
  
  Color get workoutsColor {
    final colorValue = _prefs.getInt(_workoutsColorKey);
    return colorValue != null ? Color(colorValue) : defaultWorkoutsColor;
  }
  
  Future<void> setWorkoutsColor(Color color) async {
    await _prefs.setInt(_workoutsColorKey, color.toARGB32());
  }
  
  Color get sleepColor {
    final colorValue = _prefs.getInt(_sleepColorKey);
    return colorValue != null ? Color(colorValue) : defaultSleepColor;
  }
  
  Future<void> setSleepColor(Color color) async {
    await _prefs.setInt(_sleepColorKey, color.toARGB32());
  }
  
  // Reset colors to defaults
  Future<void> resetColors() async {
    await _prefs.remove(_calorieColorKey);
    await _prefs.remove(_proteinColorKey);
    await _prefs.remove(_carbsColorKey);
    await _prefs.remove(_fatColorKey);
  }
  
  Future<void> resetSectionColors() async {
    await _prefs.remove(_mealsColorKey);
    await _prefs.remove(_workoutsColorKey);
    await _prefs.remove(_sleepColorKey);
  }
  
  // Custom theme colors
  Color get customPrimaryColor {
    final colorValue = _prefs.getInt(_customPrimaryColorKey);
    return colorValue != null ? Color(colorValue) : defaultCustomPrimaryColor;
  }
  
  Future<void> setCustomPrimaryColor(Color color) async {
    await _prefs.setInt(_customPrimaryColorKey, color.toARGB32());
  }
  
  Color get customBackgroundColor {
    final colorValue = _prefs.getInt(_customBackgroundColorKey);
    return colorValue != null ? Color(colorValue) : defaultCustomBackgroundColor;
  }
  
  Future<void> setCustomBackgroundColor(Color color) async {
    await _prefs.setInt(_customBackgroundColorKey, color.toARGB32());
  }
  
  Color get customSurfaceColor {
    final colorValue = _prefs.getInt(_customSurfaceColorKey);
    return colorValue != null ? Color(colorValue) : defaultCustomSurfaceColor;
  }
  
  Future<void> setCustomSurfaceColor(Color color) async {
    await _prefs.setInt(_customSurfaceColorKey, color.toARGB32());
  }
  
  // Reset theme colors
  Future<void> resetThemeColors() async {
    await _prefs.remove(_customPrimaryColorKey);
    await _prefs.remove(_customBackgroundColorKey);
    await _prefs.remove(_customSurfaceColorKey);
  }
  
  // Reset all custom colors
  Future<void> resetAllCustomColors() async {
    await resetColors();
    await resetSectionColors();
    await resetThemeColors();
  }
  
  // Workout timer settings
  int get defaultRestTime {
    return _prefs.getInt(_defaultRestTimeKey) ?? 90; // Default 90 seconds
  }
  
  Future<void> setDefaultRestTime(int seconds) async {
    await _prefs.setInt(_defaultRestTimeKey, seconds);
  }
  
  bool get restTimerSoundEnabled {
    return _prefs.getBool(_restTimerSoundEnabledKey) ?? true;
  }
  
  Future<void> setRestTimerSoundEnabled(bool enabled) async {
    await _prefs.setBool(_restTimerSoundEnabledKey, enabled);
  }
  
  double get restTimerVolume {
    return _prefs.getDouble(_restTimerVolumeKey) ?? 1.0; // Default full volume
  }
  
  Future<void> setRestTimerVolume(double volume) async {
    await _prefs.setDouble(_restTimerVolumeKey, volume);
  }
}
