import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:wellness_app/features/dashboard/ui/dashboard_page.dart';
import 'package:wellness_app/services/language_service.dart';
import 'package:wellness_app/features/workouts/ui/workout_keys.dart';

import '../support/app_launcher.dart';

/// A quick workout could not gain an exercise at all: the session page builds
/// its exercise list from `session.templateId`, a quick workout has none, and
/// the only "Add Exercise" button pushed the read-only Exercise Library, which
/// cannot hand anything back.
///
/// `test/regression/quick_workout_exercises_test.dart` already pins the data
/// side (template created lazily, prescription stored, ordering). This covers
/// only what that cannot: that the screens actually wire up to it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('adding an exercise to a quick workout puts it on the session',
      (tester) async {
    final l10n = await loadL10n(AppLanguage.english);

    late String exerciseName;
    late String exerciseId;
    await pumpApp(tester, seed: (db) async {
      final first = (await db.getAllExercises()).first;
      exerciseName = first.name;
      exerciseId = first.id;
    });

    await tapDashboardAction(tester, DashboardKeys.workoutsAction);
    await tapVisible(tester, find.byKey(WorkoutKeys.startWorkoutFab));
    await tapVisible(tester, find.byKey(WorkoutKeys.quickWorkoutTile));

    // The state that used to be a dead end.
    expect(find.text(l10n.noExercisesYet), findsOneWidget);

    await tapVisible(tester, find.byKey(WorkoutKeys.addExerciseFab));

    // Search narrows to one row, so the tap can't land on a similarly-named
    // exercise further down the catalog.
    await tester.enterText(
        find.byKey(WorkoutKeys.exerciseSearchField), exerciseName);
    await settle(tester);
    await tapVisible(tester, find.byKey(WorkoutKeys.exerciseRow(exerciseId)));

    await tapVisible(tester, find.byKey(WorkoutKeys.savePrescription));

    // Back on the session, now actually holding the exercise.
    expect(find.text(exerciseName), findsWidgets);
    expect(find.text(l10n.noExercisesYet), findsNothing);

    // The prescription rendered back out: 3 sets by default, and rest
    // resolved from the default 10 reps via the ladder rather than the flat
    // 90s global -- 10 reps lands on 90s, which is 1:30.
    expect(find.text(l10n.setsAndRestSummary(3, '1:30')), findsOneWidget);
  });
}
