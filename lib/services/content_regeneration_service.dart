import 'package:flutter/foundation.dart';

import '../core/app_language.dart';
import '../data/db/drift_database.dart';
import 'meal_template_generator.dart';
import 'profile_fit.dart';
import 'user_profile_service.dart';
import 'workout_template_generator.dart';

/// What a regeneration would replace, so the prompt can be specific about
/// the cost before the user agrees to it.
class RegenerationPreview {
  const RegenerationPreview({
    required this.mealTemplates,
    required this.workoutTemplates,
  });

  final int mealTemplates;
  final int workoutTemplates;

  bool get isEmpty => mealTemplates == 0 && workoutTemplates == 0;
}

/// Replaces profile-generated templates after the profile changes.
///
/// The rule this exists to enforce: **only `TemplateOrigin.generated` is
/// ever touched.** Anything the user built or edited is theirs, and the
/// seeded built-ins are left alone so the catalog can't shrink
/// irreversibly. Without that distinction, "your equipment changed --
/// regenerate?" has no safe implementation; it would either do nothing or
/// destroy hand-built work.
///
/// Deliberately *not* automatic. Regeneration throws away templates the
/// user may have been using all week, so it is offered, not imposed --
/// [ProfileFit.contentAffectingFieldsChanged] decides whether to offer it
/// at all, and only content-affecting fields count (`goal` is target-only
/// and does not qualify).
class ContentRegenerationService {
  ContentRegenerationService(this._database);

  final AppDatabase _database;

  /// How many generated templates a regeneration would discard.
  Future<RegenerationPreview> preview() async {
    final meals = (await _database.getAllMealTemplates())
        .where((t) => ProfileFit.isReplaceable(t.origin))
        .length;
    final workouts = (await _database.getAllWorkoutTemplates())
        .where((t) => ProfileFit.isReplaceable(t.origin))
        .length;
    return RegenerationPreview(
      mealTemplates: meals,
      workoutTemplates: workouts,
    );
  }

  /// Deletes every generated template and rebuilds from [profile], in
  /// [language].
  ///
  /// [language] is the app's *current* language, not the one the discarded
  /// templates were written in. Regeneration is the one moment a rewrite is
  /// legitimate: the user asked for these templates to be replaced, so the
  /// replacements are written in the language they are using now. Nothing
  /// else in the app re-languages content behind their back.
  ///
  /// Returns how many templates were created. Safe to call when nothing was
  /// previously generated -- it simply generates for the first time.
  Future<int> regenerate(UserProfile profile, AppLanguage language) async {
    final removedMeals = await _deleteReplaceableMealTemplates();
    final removedWorkouts = await _deleteReplaceableWorkoutTemplates();
    debugPrint('[REGEN] Removed $removedMeals meal / $removedWorkouts workout '
        'generated templates');

    final meals = await MealTemplateGenerator(_database, profile, language)
        .generateTemplates();
    final workouts =
        await WorkoutTemplateGenerator(_database, profile, language)
            .generateTemplates();

    debugPrint('[REGEN] Rebuilt ${meals.length} meal / ${workouts.length} '
        'workout templates');
    return meals.length + workouts.length;
  }

  Future<int> _deleteReplaceableMealTemplates() async {
    final replaceable = (await _database.getAllMealTemplates())
        .where((t) => ProfileFit.isReplaceable(t.origin))
        .toList();
    for (final template in replaceable) {
      // deleteMealTemplate cascades to its items.
      await _database.deleteMealTemplate(template.id);
    }
    return replaceable.length;
  }

  Future<int> _deleteReplaceableWorkoutTemplates() async {
    final replaceable = (await _database.getAllWorkoutTemplates())
        .where((t) => ProfileFit.isReplaceable(t.origin))
        .toList();
    for (final template in replaceable) {
      await _database.deleteWorkoutTemplate(template.id);
    }
    return replaceable.length;
  }
}
