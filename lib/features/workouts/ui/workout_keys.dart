import 'package:flutter/widgets.dart';

/// Keys for the workout controls whose visible label is ambiguous.
///
/// "Start Workout" appears on the workouts FAB, as the start-sheet's title,
/// and on every template card's button; "Quick Workout" is both a tile in
/// that sheet and the fallback name of any template-less session in the
/// recent list. Targeting those by text picks an arbitrary one, so the flow
/// tests address them by key instead -- same reasoning as `DashboardKeys`.
class WorkoutKeys {
  const WorkoutKeys._();

  /// FAB on the workouts page that opens the start-workout sheet.
  static const startWorkoutFab = Key('workouts_start_fab');

  /// "Quick Workout" tile inside that sheet.
  static const quickWorkoutTile = Key('workouts_quick_start_tile');

  /// FAB on a running session that opens the exercise picker.
  static const addExerciseFab = Key('session_add_exercise_fab');

  /// One row in the exercise picker. Keyed per exercise so a flow test can
  /// tap a specific one without depending on catalog ordering or on the name
  /// being a unique substring ("Push-ups" also matches "Incline Push-ups").
  static Key exerciseRow(String exerciseId) => Key('exercise_row_$exerciseId');

  /// Search field in the exercise picker. Keyed because the session page
  /// underneath the sheet has its own text fields, so "the last TextField"
  /// is not reliably this one.
  static const exerciseSearchField = Key('exercise_picker_search');

  /// Confirm button on the prescription sheet.
  static const savePrescription = Key('exercise_prescription_save');
}
