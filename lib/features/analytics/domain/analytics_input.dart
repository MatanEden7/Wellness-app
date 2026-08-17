/// The raw material the analytics domain works from.
///
/// Deliberately *not* the `AppDatabase` row types and *not* the freezed domain
/// models. Everything below is a plain value object with only the fields the
/// analysis needs, which keeps the whole `domain/` layer free of Flutter, free
/// of the database, and constructible in three lines inside a unit test.
/// `AnalyticsRepository` is the only place that knows how to build these.
library;

import '../../../core/date_utils.dart';

/// One calendar day's nutrition totals, already summed from meal items.
class DailyNutrition {
  /// yyyymmdd, matching `MealData.date`.
  final int dateInt;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  /// Whether anything at all was logged that day. A day with meals logged that
  /// happen to total zero is still a logged day; a day with no meals is not,
  /// and the two must not average together.
  final bool logged;

  const DailyNutrition({
    required this.dateInt,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.logged,
  });

  DateTime get day => AppDateUtils.intToDate(dateInt);
}

/// One set inside a completed session.
class TrainingSet {
  final String exerciseId;
  final int reps;

  /// Null for bodyweight work. Volume treats it as zero load, but the set
  /// still counts toward "you trained this muscle".
  final double? weightKg;

  const TrainingSet({
    required this.exerciseId,
    required this.reps,
    this.weightKg,
  });

  double get volume => reps * (weightKg ?? 0);
}

/// A **completed** workout session.
///
/// Only completed sessions ever reach here. An in-progress session
/// (`endedAt == null`) that leaked into the aggregates would log as a
/// zero-volume training day and break both the volume chart and the streak.
class TrainingSession {
  final String id;
  final DateTime startedAt;
  final Duration duration;
  final List<TrainingSet> sets;

  const TrainingSession({
    required this.id,
    required this.startedAt,
    required this.duration,
    required this.sets,
  });

  DateTime get day => AppDateUtils.startOfDay(startedAt);

  double get volume => sets.fold(0.0, (sum, s) => sum + s.volume);
}

/// One night's sleep, attributed to the day it *ended* on.
///
/// Attributing by end rather than start is what makes "did I sleep enough last
/// night?" line up with the day the user is looking at -- a 23:30 bedtime
/// otherwise scores the previous day.
class SleepNight {
  final DateTime day;
  final double hours;
  final int? quality;

  /// When the user went to sleep. Used for bedtime consistency; the hour is
  /// what matters, not the date.
  final DateTime startedAt;

  const SleepNight({
    required this.day,
    required this.hours,
    required this.startedAt,
    this.quality,
  });
}

/// One weigh-in, normalised to the calendar day it was taken on.
class WeighIn {
  final DateTime day;
  final double kg;

  const WeighIn({required this.day, required this.kg});
}

/// The exercise metadata the training charts need, without dragging the whole
/// `Exercise` model (and its localisation extensions) into the pure layer.
class ExerciseRef {
  final String id;

  /// Already in the user's language: the row was seeded in it and is never
  /// re-resolved. See `AppDatabase.seedCatalogFor`.
  final String name;
  final String? primaryMuscle;

  const ExerciseRef({
    required this.id,
    required this.name,
    this.primaryMuscle,
  });
}

/// Everything the analytics screen was able to load for one range, in one pass.
class AnalyticsSnapshot {
  final List<DailyNutrition> nutrition;
  final List<TrainingSession> sessions;
  final List<SleepNight> sleep;
  final List<WeighIn> weighIns;
  final Map<String, ExerciseRef> exercises;

  const AnalyticsSnapshot({
    required this.nutrition,
    required this.sessions,
    required this.sleep,
    required this.weighIns,
    required this.exercises,
  });

  const AnalyticsSnapshot.empty()
      : nutrition = const [],
        sessions = const [],
        sleep = const [],
        weighIns = const [],
        exercises = const {};
}
