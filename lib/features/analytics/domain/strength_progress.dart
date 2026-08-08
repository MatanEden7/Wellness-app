import '../../../core/date_utils.dart';
import 'analytics_input.dart';

/// Estimated one-rep max (Epley).
///
/// This, not the raw top-set weight, is what the progression line plots.
/// Adding a rep at the same weight *is* progress, and a raw-weight line hides
/// it -- which produces exactly the false "I'm stuck" reading the plateau
/// detector below is supposed to be the only source of.
///
/// Epley's formula is undefined-ish at a single rep (it returns 1.033x the
/// load), so one rep is reported as the load itself.
double estimatedOneRepMax(double weightKg, int reps) {
  if (reps <= 1) return weightKg;
  return weightKg * (1 + reps / 30.0);
}

/// One session's worth of work on one exercise.
class ExerciseSessionPoint {
  final DateTime day;

  /// Heaviest load used that day. Null when every set was bodyweight.
  final double? topWeightKg;

  /// Reps performed on the heaviest set -- the pair that produced [e1rm].
  final int repsAtTopWeight;

  /// Null when the exercise carries no load, where a 1RM is meaningless.
  final double? e1rm;

  final int setCount;
  final double volume;

  const ExerciseSessionPoint({
    required this.day,
    required this.topWeightKg,
    required this.repsAtTopWeight,
    required this.e1rm,
    required this.setCount,
    required this.volume,
  });
}

/// Everything logged for one exercise in the range, oldest session first.
class ExerciseProgress {
  final String exerciseId;
  final List<ExerciseSessionPoint> sessions;

  const ExerciseProgress({required this.exerciseId, required this.sessions});

  int get sessionCount => sessions.length;

  double get totalVolume => sessions.fold(0.0, (sum, s) => sum + s.volume);

  double? get bestE1rm {
    double? best;
    for (final s in sessions) {
      final v = s.e1rm;
      if (v != null && (best == null || v > best)) best = v;
    }
    return best;
  }
}

/// Whether an exercise's working weight has moved lately.
///
/// This is the direct answer to "am I using the same weight for a while" --
/// and it is computed for every exercise at once, rather than making the user
/// page through a chart one lift at a time to find out.
class PlateauStatus {
  final String exerciseId;

  /// The load the most recent session worked at.
  final double lastTopWeightKg;

  /// How many consecutive recent sessions used that same load.
  final int sessionsAtWeight;

  /// Days since the load last went up. Equal to the span back to the first
  /// session at the current weight.
  final int daysSinceIncrease;

  /// The most recent session beat every earlier one on estimated 1RM.
  final bool isPersonalBest;

  const PlateauStatus({
    required this.exerciseId,
    required this.lastTopWeightKg,
    required this.sessionsAtWeight,
    required this.daysSinceIncrease,
    required this.isPersonalBest,
  });

  /// Stuck: same load for at least three sessions *and* at least two weeks.
  ///
  /// Both conditions are required. Three sessions inside one week is a normal
  /// training block, not a plateau; two weeks with a single session in them is
  /// a scheduling gap, not a plateau either.
  bool get isPlateau => sessionsAtWeight >= 3 && daysSinceIncrease >= 14;
}

/// Groups completed sessions into per-exercise progression, oldest first.
///
/// Multiple sessions on the same calendar day are merged, because the chart's
/// x-axis is days and two dots on one day would have to pick a winner
/// arbitrarily.
Map<String, ExerciseProgress> buildExerciseProgress(
  List<TrainingSession> sessions,
) {
  // exerciseId -> day -> the sets performed
  final byExerciseDay = <String, Map<DateTime, List<TrainingSet>>>{};

  for (final session in sessions) {
    final day = AppDateUtils.startOfDay(session.startedAt);
    for (final set in session.sets) {
      byExerciseDay
          .putIfAbsent(set.exerciseId, () => <DateTime, List<TrainingSet>>{})
          .putIfAbsent(day, () => <TrainingSet>[])
          .add(set);
    }
  }

  final out = <String, ExerciseProgress>{};
  byExerciseDay.forEach((exerciseId, byDay) {
    final days = byDay.keys.toList()..sort();
    out[exerciseId] = ExerciseProgress(
      exerciseId: exerciseId,
      sessions: [
        for (final day in days) _pointFor(day, byDay[day]!),
      ],
    );
  });
  return out;
}

ExerciseSessionPoint _pointFor(DateTime day, List<TrainingSet> sets) {
  TrainingSet? top;
  for (final set in sets) {
    final w = set.weightKg;
    if (w == null) continue;
    // Ties on load break toward the higher rep count: the same weight for more
    // reps is the better set, and is the progress the e1RM line exists to see.
    if (top == null ||
        w > top.weightKg! ||
        (w == top.weightKg && set.reps > top.reps)) {
      top = set;
    }
  }

  return ExerciseSessionPoint(
    day: day,
    topWeightKg: top?.weightKg,
    repsAtTopWeight: top?.reps ?? 0,
    e1rm: top == null ? null : estimatedOneRepMax(top.weightKg!, top.reps),
    setCount: sets.length,
    volume: sets.fold(0.0, (sum, s) => sum + s.volume),
  );
}

/// Plateau verdicts for every loaded exercise trained at least [minSessions]
/// times, worst first (longest stall at the top).
///
/// Bodyweight exercises are excluded: "the same weight for weeks" is the
/// definition of a push-up, not a problem with it.
List<PlateauStatus> detectPlateaus(
  Map<String, ExerciseProgress> progress, {
  int minSessions = 3,
}) {
  final out = <PlateauStatus>[];

  for (final entry in progress.entries) {
    final loaded =
        entry.value.sessions.where((s) => s.topWeightKg != null).toList();
    if (loaded.length < minSessions) continue;

    final last = loaded.last;
    final lastWeight = last.topWeightKg!;

    // Walk back while the load is unchanged or lower. A *lighter* session does
    // not reset the clock -- a deload week is not evidence the weight moved up.
    var firstAtWeight = last;
    var sessionsAtWeight = 0;
    for (final session in loaded.reversed) {
      if (session.topWeightKg! > lastWeight) break;
      if (session.topWeightKg! == lastWeight) {
        sessionsAtWeight++;
        firstAtWeight = session;
      }
    }

    final bestBefore = loaded
        .sublist(0, loaded.length - 1)
        .map((s) => s.e1rm ?? 0)
        .fold<double>(0, (a, b) => a > b ? a : b);

    out.add(PlateauStatus(
      exerciseId: entry.key,
      lastTopWeightKg: lastWeight,
      sessionsAtWeight: sessionsAtWeight,
      daysSinceIncrease: last.day.difference(firstAtWeight.day).inDays,
      isPersonalBest: (last.e1rm ?? 0) > bestBefore,
    ));
  }

  out.sort((a, b) {
    final byStall = b.daysSinceIncrease.compareTo(a.daysSinceIncrease);
    if (byStall != 0) return byStall;
    return b.sessionsAtWeight.compareTo(a.sessionsAtWeight);
  });
  return out;
}
