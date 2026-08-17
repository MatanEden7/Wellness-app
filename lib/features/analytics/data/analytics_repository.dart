import 'dart:async';

import '../../../core/date_utils.dart';
import '../../../data/db/drift_database.dart';
import '../domain/analytics_input.dart';
import '../domain/analytics_range.dart';

/// The only place in the analytics feature that touches the database.
///
/// Loads one range in a single pass and hands the pure domain layer plain
/// value objects. Two things it deliberately does *not* do:
///
///  * **No per-day queries.** The existing `watchMealsByDate` is one day and
///    `getMealItemsByMealId` is one meal; calling either in a loop over 365
///    days is O(days x allItems) and re-scans the whole item list every time.
///    Everything here is indexed once and joined in memory instead.
///  * **No in-progress sessions.** `endedAt == null` means "still running".
///    Letting one through logs an abandoned session as a zero-volume training
///    day, which both flattens the volume chart and breaks the goal streak.
class AnalyticsRepository {
  final AppDatabase _database;

  AnalyticsRepository(this._database);

  /// Emits whenever anything the screen shows changes.
  ///
  /// Merges the five collection signals rather than listening to them
  /// separately, so one page-wide recomputation happens per change instead of
  /// one per section.
  Stream<void> watchChanges() async* {
    yield null;
    await for (final _ in _mergedSignals()) {
      yield null;
    }
  }

  Stream<void> _mergedSignals() {
    // `skip(1)` on each: every watchXStream() emits immediately on listen, and
    // without it a page load would fire five redundant recomputations before
    // anything had actually changed.
    return StreamGroupLite.merge([
      _database.watchMealsStream().skip(1),
      _database.watchWorkoutsStream().skip(1),
      _database.watchSleepStream().skip(1),
      _database.watchBodyWeightStream().skip(1),
      _database.watchFoodsStream().skip(1),
    ]);
  }

  Future<AnalyticsSnapshot> load(DateRange range) async {
    final startInt = AppDateUtils.dateToInt(range.start);
    // endExclusive is midnight the day *after* the last day in range, so the
    // last real day is one step back. Comparing against endExclusive directly
    // would pull in a day past the window.
    final endInt = AppDateUtils.dateToInt(
      range.endExclusive.subtract(const Duration(days: 1)),
    );

    return AnalyticsSnapshot(
      nutrition: await _loadNutrition(range, startInt, endInt),
      sessions: await _loadSessions(range),
      sleep: await _loadSleep(range),
      weighIns: await _loadWeighIns(range),
      exercises: await _loadExercises(),
    );
  }

  Future<List<DailyNutrition>> _loadNutrition(
    DateRange range,
    int startInt,
    int endInt,
  ) async {
    final meals = await _database.getAllMeals();
    final items = await _database.getAllMealItems();

    final mealDateById = <String, int>{};
    for (final meal in meals) {
      if (meal.date < startInt || meal.date > endInt) continue;
      mealDateById[meal.id] = meal.date;
    }

    // Seeded with the days that have meals but no items yet: an empty meal is
    // still a logged day, and treating it as unlogged would let a day the user
    // clearly interacted with vanish from the adherence count.
    final totals = <int, DailyNutrition>{
      for (final date in mealDateById.values)
        date: DailyNutrition(
            dateInt: date, kcal: 0, protein: 0, carbs: 0, fat: 0, logged: true),
    };

    for (final item in items) {
      final date = mealDateById[item.mealId];
      if (date == null) continue;
      final current = totals[date]!;
      totals[date] = DailyNutrition(
        dateInt: date,
        kcal: current.kcal + item.kcal,
        protein: current.protein + item.protein,
        carbs: current.carbs + item.carbs,
        fat: current.fat + item.fat,
        logged: true,
      );
    }

    return totals.values.toList();
  }

  Future<List<TrainingSession>> _loadSessions(DateRange range) async {
    final sessions = await _database.getAllWorkoutSessions();
    final setEntries = await _database.getAllSetEntries();

    final inRange = [
      for (final session in sessions)
        if (session.endedAt != null && range.contains(session.startedAt))
          session,
    ];
    if (inRange.isEmpty) return const [];

    final wanted = {for (final s in inRange) s.id};
    final setsBySession = <String, List<TrainingSet>>{};
    for (final entry in setEntries) {
      if (!wanted.contains(entry.sessionId)) continue;
      setsBySession.putIfAbsent(entry.sessionId, () => <TrainingSet>[]).add(
            TrainingSet(
              exerciseId: entry.exerciseId,
              reps: entry.reps,
              weightKg: entry.weight,
            ),
          );
    }

    return [
      for (final session in inRange)
        TrainingSession(
          id: session.id,
          startedAt: session.startedAt,
          duration: session.endedAt!.difference(session.startedAt),
          sets: setsBySession[session.id] ?? const [],
        ),
    ];
  }

  Future<List<SleepNight>> _loadSleep(DateRange range) async {
    final entries = await _database.getAllSleepEntries();
    final byDay = <DateTime, SleepNight>{};

    for (final entry in entries) {
      final endedAt = entry.endedAt;
      if (endedAt == null) continue; // still sleeping, or never stopped
      // Attributed to the day it ended on: a 23:30 bedtime otherwise scores
      // the previous day, and "did I sleep enough last night" stops lining up
      // with the day the user is looking at.
      final day = AppDateUtils.startOfDay(endedAt);
      if (!range.contains(day)) continue;

      final hours = endedAt.difference(entry.startedAt).inMinutes / 60.0;
      if (hours <= 0) continue;

      // Two naps on one day would otherwise each look like a full night. The
      // longer one wins, which is the one that was actually the night's sleep.
      final existing = byDay[day];
      if (existing != null && existing.hours >= hours) continue;

      byDay[day] = SleepNight(
        day: day,
        hours: hours,
        startedAt: entry.startedAt,
        quality: entry.quality,
      );
    }

    return byDay.values.toList();
  }

  Future<List<WeighIn>> _loadWeighIns(DateRange range) async {
    final entries = await _database.getAllBodyWeightEntries();
    return [
      for (final entry in entries)
        if (range.contains(AppDateUtils.startOfDay(entry.recordedAt)))
          WeighIn(
            day: AppDateUtils.startOfDay(entry.recordedAt),
            kg: entry.kg,
          ),
    ];
  }

  Future<Map<String, ExerciseRef>> _loadExercises() async {
    final exercises = await _database.getAllExercises();
    return {
      for (final e in exercises)
        e.id: ExerciseRef(
          id: e.id,
          name: e.name,
          primaryMuscle: e.primaryMuscle,
        ),
    };
  }
}

/// A three-line merge, rather than a dependency on `async`'s `StreamGroup`.
///
/// The app has no stream-utility package and one merge does not justify
/// adding one.
class StreamGroupLite {
  static Stream<T> merge<T>(List<Stream<T>> sources) {
    late final List<StreamSubscription<T>> subscriptions;
    late final StreamController<T> controller;

    controller = StreamController<T>(
      onListen: () {
        subscriptions = [
          for (final source in sources)
            source.listen(controller.add, onError: controller.addError),
        ];
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );

    return controller.stream;
  }
}
