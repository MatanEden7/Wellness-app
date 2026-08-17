import 'package:wellness_app/l10n/app_localizations.dart';

class TextLimits {
  // Text length limits
  static const int mealNameMaxLength = 50;
  static const int foodNameMaxLength = 50;
  static const int workoutTemplateNameMaxLength = 40;
  static const int sleepNoteMaxLength = 200;
  static const int generalNoteMaxLength = 500;

  // Validation methods
  //
  // Each takes the localisations rather than returning English: these strings
  // are shown to the user under a form field, so they belong in the ARB like
  // every other piece of chrome. Callers pass a closure --
  // `(v) => TextLimits.validateMealName(v, l10n)` -- which is why these are
  // not tear-offs any more.
  static String? validateMealName(String? value, AppLocalizations l10n) =>
      _validateName(value, l10n.mealName, mealNameMaxLength, l10n);

  static String? validateFoodName(String? value, AppLocalizations l10n) =>
      _validateName(value, l10n.foodName, foodNameMaxLength, l10n);

  static String? validateWorkoutTemplateName(
          String? value, AppLocalizations l10n) =>
      _validateName(
          value, l10n.templateName, workoutTemplateNameMaxLength, l10n);

  static String? validateSleepNote(String? value, AppLocalizations l10n) =>
      _validateLength(value, l10n.noteLabel, sleepNoteMaxLength, l10n);

  static String? validateGeneralNote(String? value, AppLocalizations l10n) =>
      _validateLength(value, l10n.noteLabel, generalNoteMaxLength, l10n);

  /// Required, then bounded.
  static String? _validateName(
      String? value, String field, int max, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.fieldRequired(field);
    }
    return _validateLength(value, field, max, l10n);
  }

  /// Bounded only -- an empty optional field is valid.
  static String? _validateLength(
      String? value, String field, int max, AppLocalizations l10n) {
    if (value != null && value.trim().length > max) {
      return l10n.fieldMaxLength(field, max);
    }
    return null;
  }

  // Truncation methods for display
  static String truncateForDisplay(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  static String truncateMealName(String name) {
    return truncateForDisplay(name, mealNameMaxLength);
  }

  static String truncateFoodName(String name) {
    return truncateForDisplay(name, foodNameMaxLength);
  }

  static String truncateWorkoutTemplateName(String name) {
    return truncateForDisplay(name, workoutTemplateNameMaxLength);
  }
}
