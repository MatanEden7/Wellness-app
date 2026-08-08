import 'analytics_view.dart';
import 'goal_scoring.dart';

/// What an insight is about. The UI turns this plus [Insight.values] into
/// copy -- the rules themselves stay free of strings so the same rule can
/// speak English or Hebrew, and so a rule is testable on its numbers alone.
enum InsightKind {
  plateau,
  personalBest,
  proteinShortfall,
  calorieDrift,
  volumeDrop,
  sleepDebt,
  consistencyWin,
  neglectedMuscle,
}

enum InsightTone { positive, neutral, warning }

/// One generated observation.
class Insight {
  final InsightKind kind;
  final InsightTone tone;

  /// Exercise id or muscle name, for the kinds that name one.
  final String? subjectId;

  /// The numbers the copy interpolates. Keys are per-kind and documented on
  /// the rule that emits them.
  final Map<String, double> values;

  /// Higher wins when more insights qualify than the card will show.
  final int priority;

  const Insight({
    required this.kind,
    required this.tone,
    required this.priority,
    this.subjectId,
    this.values = const {},
  });
}

/// How many insights the card shows. Past three it stops being a summary and
/// becomes a second screen the user has to read.
const int maxInsights = 3;

/// Runs every rule and returns the strongest [maxInsights].
///
/// Each rule is a pure function of the already-computed view, so adding one is
/// a function and a unit test -- no query, no UI change.
List<Insight> generateInsights(AnalyticsView view) {
  final found = <Insight>[
    ..._plateaus(view),
    ..._personalBests(view),
    ...<Insight?>[
      _proteinShortfall(view),
      _calorieDrift(view),
      _volumeDrop(view),
      _sleepDebt(view),
      _consistencyWin(view),
      _neglectedMuscle(view),
    ].whereType<Insight>(),
  ]..sort((a, b) => b.priority.compareTo(a.priority));

  return found.take(maxInsights).toList();
}

/// values: `weight` (kg), `days`, `sessions`.
Iterable<Insight> _plateaus(AnalyticsView view) =>
    view.plateaus.where((p) => p.isPlateau).take(2).map((p) => Insight(
          kind: InsightKind.plateau,
          tone: InsightTone.warning,
          subjectId: p.exerciseId,
          // The longer the stall, the more it deserves the slot.
          priority: 60 + p.daysSinceIncrease,
          values: {
            'weight': p.lastTopWeightKg,
            'days': p.daysSinceIncrease.toDouble(),
            'sessions': p.sessionsAtWeight.toDouble(),
          },
        ));

/// values: `e1rm` (kg).
Iterable<Insight> _personalBests(AnalyticsView view) =>
    view.plateaus.where((p) => p.isPersonalBest).take(1).map((p) => Insight(
          kind: InsightKind.personalBest,
          tone: InsightTone.positive,
          subjectId: p.exerciseId,
          priority: 90,
          values: {
            'e1rm': view.strength[p.exerciseId]?.sessions.last.e1rm ?? 0,
          },
        ));

/// values: `actual` (g), `goal` (g).
Insight? _proteinShortfall(AnalyticsView view) {
  final goal = view.targets.proteinGoal;
  if (goal == null || goal <= 0) return null;
  final recent = view.protein.tailAverage(7);
  // Two observations minimum: one low day is a day, not a trend.
  if (recent == null || view.protein.observedCount < 2) return null;
  if (recent >= goal * 0.85) return null;

  return Insight(
    kind: InsightKind.proteinShortfall,
    tone: InsightTone.warning,
    priority: 70,
    values: {'actual': recent, 'goal': goal},
  );
}

/// values: `actual` (kcal), `goal` (kcal), `direction` (-1 under, 1 over).
Insight? _calorieDrift(AnalyticsView view) {
  final goal = view.targets.calorieGoal;
  if (goal == null || goal <= 0) return null;
  final recent = view.calories.tailAverage(7);
  if (recent == null || view.calories.observedCount < 3) return null;

  final ratio = recent / goal;
  if (ratio > 0.85 && ratio < 1.15) return null;

  return Insight(
    kind: InsightKind.calorieDrift,
    tone: InsightTone.neutral,
    priority: 50,
    values: {
      'actual': recent,
      'goal': goal,
      'direction': ratio >= 1 ? 1 : -1,
    },
  );
}

/// values: `drop` (0..1 share below the earlier average).
///
/// Compares the latest bucket against the average of the ones before it, which
/// is why it needs at least three: with two, "the average of the rest" is a
/// single bucket and any normal week-to-week swing trips it.
Insight? _volumeDrop(AnalyticsView view) {
  final points = view.volume.points.where((p) => p.hasValue).toList();
  if (points.length < 3) return null;

  final latest = points.last.value!;
  final earlier = points.sublist(0, points.length - 1).map((p) => p.value!);
  final baseline = earlier.reduce((a, b) => a + b) / earlier.length;
  if (baseline <= 0 || latest >= baseline * 0.7) return null;

  return Insight(
    kind: InsightKind.volumeDrop,
    tone: InsightTone.warning,
    priority: 65,
    values: {'drop': 1 - (latest / baseline)},
  );
}

/// values: `nights`, `goal` (hours).
Insight? _sleepDebt(AnalyticsView view) {
  final recent = view.goalDays.reversed.take(7).toList();
  if (recent.length < 7) return null;

  final short = recent.where((d) => !d.met.contains(WellnessGoal.sleep)).length;
  if (short < 3) return null;

  return Insight(
    kind: InsightKind.sleepDebt,
    tone: InsightTone.warning,
    priority: 55,
    values: {
      'nights': short.toDouble(),
      'goal': view.targets.sleepGoalHours,
    },
  );
}

/// values: `days`.
Insight? _consistencyWin(AnalyticsView view) {
  if (view.currentStreak < 7) return null;
  return Insight(
    kind: InsightKind.consistencyWin,
    tone: InsightTone.positive,
    priority: 85,
    values: {'days': view.currentStreak.toDouble()},
  );
}

/// The muscle group with the fewest sets, when the user is training enough for
/// its absence to be a choice rather than a coincidence.
///
/// values: `sets`.
Insight? _neglectedMuscle(AnalyticsView view) {
  final total = view.setsPerMuscle.values.fold(0, (a, b) => a + b);
  // Under ~30 sets in range there is not enough training to call anything
  // neglected -- everything looks neglected in a light week.
  if (total < 30 || view.setsPerMuscle.length < 3) return null;

  final sorted = view.setsPerMuscle.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  final lowest = sorted.first;
  if (lowest.value > total * 0.05) return null;

  return Insight(
    kind: InsightKind.neglectedMuscle,
    tone: InsightTone.neutral,
    subjectId: lowest.key,
    priority: 40,
    values: {'sets': lowest.value.toDouble()},
  );
}
