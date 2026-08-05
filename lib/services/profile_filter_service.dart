import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features/meals/domain/food_tags.dart';
import '../features/workouts/domain/exercise_tags.dart';
import 'profile_fit.dart';
import 'user_profile_service.dart';

/// Whether the browsing lists are currently showing everything, or only
/// what suits the user's profile.
///
/// Session-scoped rather than persisted, deliberately: "show me everything
/// just this once" is the common case (logging an off-plan meal, checking
/// what a lift is called), and a persisted toggle silently left on would
/// quietly undo the personalisation without the user remembering they did
/// it. Resetting on relaunch keeps the tailored view the default.
final showAllContentProvider = StateProvider<bool>((ref) => false);

/// The profile the filters read from, or null before onboarding completes.
///
/// Null means "don't filter anything" -- there is no profile to judge
/// against, and hiding half the catalog during first run would be wrong.
final filterProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(userProfileServiceProvider).loadProfile();
});

/// Turns a [FitResult] into the short reason shown on a revealed item's
/// badge, e.g. "Contains dairy" or "Needs a barbell & rack".
///
/// Lives here rather than in [ProfileFit] so that service stays free of
/// presentation concerns and remains testable without a widget tree.
String? fitFailureLabel(FitResult result) {
  if (result.fits) return null;
  switch (result.failure!) {
    case FitFailure.diet:
      final tag = result.detail as FoodTag;
      return 'Contains ${tag.label.toLowerCase()}';
    case FitFailure.exclusion:
      final tag = result.detail as FoodTag;
      return 'Contains ${tag.label.toLowerCase()}';
    case FitFailure.equipment:
      final equipment = result.detail as Equipment;
      return 'Needs ${equipment.label.toLowerCase()}';
    case FitFailure.injury:
      final part = result.detail as BodyPart;
      return 'Avoid with ${part.label.toLowerCase()} injury';
  }
}
