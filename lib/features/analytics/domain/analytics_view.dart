import 'aggregators.dart' as agg;
import 'analytics_input.dart';
import 'analytics_range.dart';
import 'goal_scoring.dart' as goals;
import 'goal_scoring.dart' show GoalDay, GoalTargets;
import 'insights.dart';
import 'series.dart';
import 'strength_progress.dart';

/// Everything the analytics screen draws, computed once per range.
///
/// The whole screen reads slices of one of these. Sections deliberately do not
/// query anything themselves: six sections each watching their own stream
/// would re-run the full aggregation six times per frame, which is the
/// build()-time stream pattern this codebase already carries elsewhere and is
/// slowly removing.
class AnalyticsView {
  final DateRange range;
  final AnalyticsBucket bucket;
  final GoalTargets targets;

  // Goals
  final List<GoalDay> goalDays;
  final MetricSeries goalScore;
  final int currentStreak;
  final int bestStreak;
  final double averageScore;

  // Nutrition
  final MetricSeries calories;
  final MetricSeries caloriesTrend;
  final MetricSeries protein;
  final MetricSeries carbs;
  final MetricSeries fat;
  final int daysLogged;

  // Training
  final MetricSeries volume;
  final MetricSeries sessionCount;
  final MetricSeries trainingMinutes;
  final Map<String, int> setsPerMuscle;
  final Map<String, ExerciseProgress> strength;
  final List<PlateauStatus> plateaus;

  // Body
  final MetricSeries bodyWeight;
  final MetricSeries bodyWeightTrend;

  // Sleep
  final MetricSeries sleepHours;
  final MetricSeries sleepQuality;
  final double? bedtimeConsistency;

  final Map<String, ExerciseRef> exercises;

  /// Derived from everything above, so it is declared after it and computed on
  /// first read. `late final` rather than a getter: the rules are cheap but not
  /// free, and the insights card would otherwise re-run them on every rebuild.
  late final List<Insight> insights = generateInsights(this);

  AnalyticsView({
    required this.range,
    required this.bucket,
    required this.targets,
    required this.goalDays,
    required this.goalScore,
    required this.currentStreak,
    required this.bestStreak,
    required this.averageScore,
    required this.calories,
    required this.caloriesTrend,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.daysLogged,
    required this.volume,
    required this.sessionCount,
    required this.trainingMinutes,
    required this.setsPerMuscle,
    required this.strength,
    required this.plateaus,
    required this.bodyWeight,
    required this.bodyWeightTrend,
    required this.sleepHours,
    required this.sleepQuality,
    required this.bedtimeConsistency,
    required this.exercises,
  });

  /// True when there is nothing at all to show -- the page renders one empty
  /// state instead of eight empty cards.
  bool get hasNoData =>
      daysLogged == 0 &&
      strength.isEmpty &&
      sleepHours.isEmpty &&
      bodyWeight.isEmpty;

  /// The exercise to open the strength chart on: the one with the most logged
  /// sessions in range, so the default view is the one with something to say.
  String? get defaultStrengthExerciseId {
    String? best;
    var bestCount = 0;
    for (final entry in strength.entries) {
      if (entry.value.sessionCount > bestCount) {
        bestCount = entry.value.sessionCount;
        best = entry.key;
      }
    }
    return best;
  }

  /// The single aggregation pass.
  factory AnalyticsView.compute({
    required DateRange range,
    required AnalyticsBucket bucket,
    required GoalTargets targets,
    required AnalyticsSnapshot snapshot,
  }) {
    final goalDays = goals.scoreGoalDays(
      range: range,
      targets: targets,
      nutrition: snapshot.nutrition,
      sessions: snapshot.sessions,
      sleep: snapshot.sleep,
    );

    final calories = agg.bucketize(
      agg.nutritionByDay(snapshot.nutrition, (d) => d.kcal),
      range,
      bucket,
      agg.BucketReducer.mean,
    );

    final strength = buildExerciseProgress(snapshot.sessions);

    final bodyWeight = agg.bucketize(
      agg.weightByDay(snapshot.weighIns),
      range,
      // Weigh-ins are sparse; bucketing them into weekly means throws away the
      // shape the EMA is there to smooth. Always daily, gaps and all.
      AnalyticsBucket.day,
      agg.BucketReducer.mean,
    );

    return AnalyticsView(
      range: range,
      bucket: bucket,
      targets: targets,
      goalDays: goalDays,
      goalScore: agg.bucketize(
        {for (final d in goalDays) d.day: d.score},
        range,
        bucket,
        agg.BucketReducer.mean,
      ),
      currentStreak: goals.currentStreak(goalDays),
      bestStreak: goals.bestStreak(goalDays),
      averageScore: goals.averageGoalScore(goalDays),
      calories: calories,
      // Always a 7-point window regardless of bucket: on a bucketed range each
      // point is already an average, and re-averaging seven of those gives the
      // long-run trend rather than the "what has this week looked like" line
      // the chart is for.
      caloriesTrend: calories.movingAverage(7),
      protein: agg.bucketize(
          agg.nutritionByDay(snapshot.nutrition, (d) => d.protein),
          range,
          bucket,
          agg.BucketReducer.mean),
      carbs: agg.bucketize(
          agg.nutritionByDay(snapshot.nutrition, (d) => d.carbs),
          range,
          bucket,
          agg.BucketReducer.mean),
      fat: agg.bucketize(agg.nutritionByDay(snapshot.nutrition, (d) => d.fat),
          range, bucket, agg.BucketReducer.mean),
      daysLogged: snapshot.nutrition.where((d) => d.logged).length,
      volume: agg.bucketize(agg.volumeByDay(snapshot.sessions), range, bucket,
          agg.BucketReducer.sum),
      sessionCount: agg.bucketize(agg.sessionCountByDay(snapshot.sessions),
          range, bucket, agg.BucketReducer.sum),
      trainingMinutes: agg.bucketize(
          agg.trainingMinutesByDay(snapshot.sessions),
          range,
          bucket,
          agg.BucketReducer.sum),
      setsPerMuscle: agg.setsPerMuscle(snapshot.sessions, snapshot.exercises),
      strength: strength,
      plateaus: detectPlateaus(strength),
      bodyWeight: bodyWeight,
      // 0.25 smooths roughly a week of daily weigh-ins without lagging so far
      // behind that a real change takes a fortnight to show up.
      bodyWeightTrend: bodyWeight.exponentialMovingAverage(0.25),
      sleepHours: agg.bucketize(agg.sleepHoursByDay(snapshot.sleep), range,
          bucket, agg.BucketReducer.mean),
      sleepQuality: agg.bucketize(
        {
          for (final n in snapshot.sleep)
            if (n.quality != null) n.day: n.quality!.toDouble(),
        },
        range,
        bucket,
        agg.BucketReducer.mean,
      ),
      bedtimeConsistency: agg.bedtimeConsistencyHours(snapshot.sleep),
      exercises: snapshot.exercises,
    );
  }
}
