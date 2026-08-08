import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/db/drift_database.dart';
import '../../../services/preferences_service.dart';
import '../../../services/user_profile_service.dart';
import '../domain/analytics_range.dart';
import '../domain/analytics_view.dart';
import '../domain/goal_scoring.dart';
import 'analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.read(databaseProvider));
});

/// Which window the screen is showing. Month by default: a week is too short
/// for a trend to exist and a year is too coarse to act on.
final analyticsRangeProvider =
    StateProvider<AnalyticsRange>((ref) => AnalyticsRange.month);

/// Which exercise the strength chart is focused on. Null means "use the
/// most-trained one", resolved per view so it survives a range change.
final analyticsFocusExerciseProvider = StateProvider<String?>((ref) => null);

/// What counts as a goal met, assembled from the nutrition preferences and the
/// profile.
final goalTargetsProvider = Provider<GoalTargets>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  final profile = ref.watch(userProfileServiceProvider).loadProfile();

  return GoalTargets(
    // Falls back to the profile's calculated target when no explicit goal has
    // been set, so onboarding alone is enough for the screen to score days --
    // the alternative is a page that shows nothing until the user visits a
    // settings screen they have no reason to know about.
    calorieGoal: prefs.calorieGoal ?? profile?.calorieTarget,
    proteinGoal: prefs.proteinGoal ?? profile?.proteinTargetG,
    trainingDaysPerWeek: profile?.trainingDaysPerWeek ?? 0,
    sleepGoalHours: prefs.sleepGoalHours,
    profileGoal: profile?.goal ?? 'maintenance',
  );
});

/// The one aggregation pass the whole screen reads from.
///
/// Every section takes a slice of this single value. Sections must not query
/// anything themselves: with seven cards, per-section streams would re-run the
/// full aggregation seven times per frame -- the `build()`-time stream pattern
/// this codebase is working its way out of.
///
/// `autoDispose` so leaving the screen frees the computed series; the family
/// key is the range, so flicking between W/M/6M/Y and back re-uses whatever is
/// still alive rather than recomputing.
final analyticsViewProvider =
    StreamProvider.autoDispose.family<AnalyticsView, AnalyticsRange>(
  (ref, range) {
    final repository = ref.watch(analyticsRepositoryProvider);
    final targets = ref.watch(goalTargetsProvider);
    // Read once per subscription rather than per emission: recomputing against
    // a clock that moves mid-stream would silently shift the window under the
    // user while they are looking at it.
    final window = range.rangeEndingOn(DateTime.now());

    return repository.watchChanges().asyncMap((_) async {
      final snapshot = await repository.load(window);
      return AnalyticsView.compute(
        range: window,
        bucket: range.bucket,
        targets: targets,
        snapshot: snapshot,
      );
    });
  },
);
