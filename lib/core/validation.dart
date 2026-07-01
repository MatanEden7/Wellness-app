class TextLimits {
  // Text length limits
  static const int mealNameMaxLength = 50;
  static const int foodNameMaxLength = 50;
  static const int workoutTemplateNameMaxLength = 40;
  static const int sleepNoteMaxLength = 200;
  static const int generalNoteMaxLength = 500;

  // Validation methods
  static String? validateMealName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Meal name is required';
    }
    if (value.trim().length > mealNameMaxLength) {
      return 'Meal name must be $mealNameMaxLength characters or less';
    }
    return null;
  }

  static String? validateFoodName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Food name is required';
    }
    if (value.trim().length > foodNameMaxLength) {
      return 'Food name must be $foodNameMaxLength characters or less';
    }
    return null;
  }

  static String? validateWorkoutTemplateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Template name is required';
    }
    if (value.trim().length > workoutTemplateNameMaxLength) {
      return 'Template name must be $workoutTemplateNameMaxLength characters or less';
    }
    return null;
  }

  static String? validateSleepNote(String? value) {
    if (value != null && value.trim().length > sleepNoteMaxLength) {
      return 'Note must be $sleepNoteMaxLength characters or less';
    }
    return null;
  }

  static String? validateGeneralNote(String? value) {
    if (value != null && value.trim().length > generalNoteMaxLength) {
      return 'Note must be $generalNoteMaxLength characters or less';
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
