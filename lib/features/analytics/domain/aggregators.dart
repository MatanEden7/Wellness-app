import '../../../core/date_utils.dart';
import 'analytics_input.dart';
import 'analytics_range.dart';
import 'series.dart';

/// How a bucket combines the days inside it.
enum BucketReducer {
  /// Mean of the days that have data. Right for rates -- calories per day,
  /// hours slept, goal score. A week bucket showing 15,000 kcal is unreadable.
  mean,

  /// Sum over the bucket. Right for quantities -- training volume, session
  /// counts, where the weekly total is the number that means something.
  sum,
}

/// Folds a per-day map into one point per bucket.
///
/// A bucket with no observed day yields a null point, not a zero, so the chart
/// can draw a gap and the averages can ignore it.
MetricSeries bucketize(
  Map<DateTime, double> byDay,
  DateRange range,
  AnalyticsBucket bucket,
  BucketReducer reducer,
) {
  final buckets = <DateTime, List<double>>{};
  for (final day in range.days) {
    final start = bucketStartFor(day, bucket);
    buckets.putIfAbsent(start, () => <double>[]);
    final value = byDay[day];
    if (value != null) buckets[start]!.add(value);
  }

  return MetricSeries([
    for (final start in bucketStarts(range, bucket))
      TimeSeriesPoint(start, _reduce(buckets[start] ?? const [], reducer)),
  ]);
}

double? _reduce(List<double> values, BucketReducer reducer) {
  if (values.isEmpty) return null;
  final total = values.reduce((a, b) => a + b);
  return reducer == BucketReducer.sum ? total : total / values.length;
}

/// Per-day nutrition, keyed by calendar day. Unlogged days are absent, so they
/// stay distinguishable from days that were logged as zero.
Map<DateTime, double> nutritionByDay(
  List<DailyNutrition> nutrition,
  double Function(DailyNutrition) pick,
) =>
    {
      for (final day in nutrition)
        if (day.logged) AppDateUtils.intToDate(day.dateInt): pick(day),
    };

/// Total training volume per day. Days without a session are absent.
Map<DateTime, double> volumeByDay(List<TrainingSession> sessions) {
  final out = <DateTime, double>{};
  for (final session in sessions) {
    out[session.day] = (out[session.day] ?? 0) + session.volume;
  }
  return out;
}

/// Completed sessions per day.
Map<DateTime, double> sessionCountByDay(List<TrainingSession> sessions) {
  final out = <DateTime, double>{};
  for (final session in sessions) {
    out[session.day] = (out[session.day] ?? 0) + 1;
  }
  return out;
}

/// Minutes trained per day.
Map<DateTime, double> trainingMinutesByDay(List<TrainingSession> sessions) {
  final out = <DateTime, double>{};
  for (final session in sessions) {
    out[session.day] = (out[session.day] ?? 0) + session.duration.inMinutes;
  }
  return out;
}

Map<DateTime, double> sleepHoursByDay(List<SleepNight> nights) => {
      for (final night in nights)
        AppDateUtils.startOfDay(night.day): night.hours
    };

/// Body weight per day.
///
/// Never bucketed by the caller: weigh-ins are sparse and irregular, and
/// averaging them into weekly bars throws away the exact shape the EMA exists
/// to smooth. The daily series carries gaps and the chart connects across them.
Map<DateTime, double> weightByDay(List<WeighIn> weighIns) =>
    {for (final w in weighIns) AppDateUtils.startOfDay(w.day): w.kg};

/// Sets performed per primary muscle, for the distribution bars.
///
/// Exercises with no `primaryMuscle` are grouped under [unlabelledMuscle]
/// rather than dropped -- a user's own untagged exercise still represents real
/// work, and silently omitting it would understate their total.
const String unlabelledMuscle = 'other';

Map<String, int> setsPerMuscle(
  List<TrainingSession> sessions,
  Map<String, ExerciseRef> exercises,
) {
  final out = <String, int>{};
  for (final session in sessions) {
    for (final set in session.sets) {
      final muscle = exercises[set.exerciseId]?.primaryMuscle?.trim();
      final key =
          (muscle == null || muscle.isEmpty) ? unlabelledMuscle : muscle;
      out[key] = (out[key] ?? 0) + 1;
    }
  }
  return out;
}

/// Standard deviation of bedtime, in hours -- the consistency figure.
///
/// Bedtimes are projected onto a continuous scale before averaging, otherwise
/// 23:30 and 00:30 average to noon instead of midnight and every user looks
/// wildly inconsistent.
double? bedtimeConsistencyHours(List<SleepNight> nights) {
  if (nights.length < 2) return null;
  final samples = nights.map((n) {
    final h = n.startedAt.hour + n.startedAt.minute / 60.0;
    return h < 12 ? h + 24 : h;
  }).toList();
  return standardDeviation(samples);
}
