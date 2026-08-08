import '../../../core/date_utils.dart';
import 'analytics_input.dart';
import 'analytics_range.dart';

/// The four goals the hero chart scores a day against.
enum WellnessGoal { calories, protein, training, sleep }

/// What "met" means for this user, gathered from the nutrition preferences and
/// the profile.
class GoalTargets {
  /// Null when the user has not set one. An unset goal is *not applicable*
  /// rather than *failed* -- scoring an unconfigured goal as a miss would cap
  /// every day at 75% with nothing on screen explaining why.
  final double? calorieGoal;
  final double? proteinGoal;

  /// From `UserProfile.trainingDaysPerWeek`. Zero disables the training goal.
  final int trainingDaysPerWeek;

  final double sleepGoalHours;

  /// `UserProfile.goal` -- fat_loss, muscle_gain, maintenance, mobility_rehab.
  /// Decides which side of the calorie target counts as a win.
  final String profileGoal;

  const GoalTargets({
    this.calorieGoal,
    this.proteinGoal,
    this.trainingDaysPerWeek = 0,
    this.sleepGoalHours = 8.0,
    this.profileGoal = 'maintenance',
  });

  Set<WellnessGoal> get applicable => {
        if (calorieGoal != null && calorieGoal! > 0) WellnessGoal.calories,
        if (proteinGoal != null && proteinGoal! > 0) WellnessGoal.protein,
        if (trainingDaysPerWeek > 0) WellnessGoal.training,
        WellnessGoal.sleep,
      };
}

/// One day's verdict.
class GoalDay {
  final DateTime day;
  final Set<WellnessGoal> applicable;
  final Set<WellnessGoal> met;

  const GoalDay({
    required this.day,
    required this.applicable,
    required this.met,
  });

  /// 0..1. A day with no applicable goals scores 0 rather than dividing by
  /// zero, and the UI shows the "set your goals" empty state instead.
  double get score => applicable.isEmpty ? 0 : met.length / applicable.length;

  bool get isPerfect =>
      applicable.isNotEmpty && met.length == applicable.length;
}

/// Scores every day in [range].
///
/// Pure: same inputs, same output, no clock read. The caller passes the range,
/// which is what makes "today" testable.
List<GoalDay> scoreGoalDays({
  required DateRange range,
  required GoalTargets targets,
  required List<DailyNutrition> nutrition,
  required List<TrainingSession> sessions,
  required List<SleepNight> sleep,
}) {
  final applicable = targets.applicable;
  final nutritionByDate = {for (final n in nutrition) n.dateInt: n};
  final sleepByDay = {
    for (final s in sleep) AppDateUtils.startOfDay(s.day): s,
  };

  // Sessions per calendar day, and the running per-week count they feed.
  final sessionDays = <DateTime>{};
  final sessionsPerWeek = <DateTime, int>{};
  for (final session in sessions) {
    sessionDays.add(session.day);
    final week = AppDateUtils.startOfWeek(session.day);
    sessionsPerWeek[week] = (sessionsPerWeek[week] ?? 0) + 1;
  }

  return [
    for (final day in range.days)
      GoalDay(
        day: day,
        applicable: applicable,
        met: {
          if (applicable.contains(WellnessGoal.calories) &&
              _caloriesMet(nutritionByDate[AppDateUtils.dateToInt(day)],
                  targets.calorieGoal!, targets.profileGoal))
            WellnessGoal.calories,
          if (applicable.contains(WellnessGoal.protein) &&
              _proteinMet(nutritionByDate[AppDateUtils.dateToInt(day)],
                  targets.proteinGoal!))
            WellnessGoal.protein,
          if (applicable.contains(WellnessGoal.training) &&
              _trainingMet(
                day,
                sessionDays,
                sessionsPerWeek[AppDateUtils.startOfWeek(day)] ?? 0,
                targets.trainingDaysPerWeek,
              ))
            WellnessGoal.training,
          if (_sleepMet(sleepByDay[day], targets.sleepGoalHours))
            WellnessGoal.sleep,
        },
      ),
  ];
}

/// Which side of the calorie target counts as a win depends on what the user
/// is training for.
///
/// A flat +/-10% band would mark a fat-loss user's best day -- comfortably
/// under target -- as a failure, which is both wrong and demoralising. The
/// lower bound on that branch exists so under-eating badly still fails.
bool _caloriesMet(DailyNutrition? day, double goal, String profileGoal) {
  if (day == null || !day.logged) return false;
  return switch (profileGoal) {
    'fat_loss' => day.kcal <= goal * 1.02 && day.kcal >= goal * 0.7,
    'muscle_gain' => day.kcal >= goal * 0.95,
    _ => day.kcal >= goal * 0.9 && day.kcal <= goal * 1.1,
  };
}

bool _proteinMet(DailyNutrition? day, double goal) {
  if (day == null || !day.logged) return false;
  return day.protein >= goal * 0.95;
}

/// Met by training that day, or by having already hit the week's target.
///
/// The second clause is the "rest day honoured" rule: someone training 3x a
/// week who has done all three by Wednesday is not failing on Thursday, and
/// scoring it as a miss would make a perfect week impossible for anyone who
/// does not train daily.
bool _trainingMet(
  DateTime day,
  Set<DateTime> sessionDays,
  int sessionsThisWeek,
  int targetPerWeek,
) {
  if (sessionDays.contains(day)) return true;
  return sessionsThisWeek >= targetPerWeek;
}

/// Half an hour of slack: a 7h45m night against an 8h goal is a hit, not a
/// miss. Without it the sleep goal is the one nobody ever meets.
bool _sleepMet(SleepNight? night, double goalHours) {
  if (night == null) return false;
  return night.hours >= goalHours - 0.5;
}

/// Consecutive perfect days ending at the most recent day in [days].
///
/// Counts back from the end of the list rather than from "today" so it is
/// well-defined for any range the caller passes.
int currentStreak(List<GoalDay> days) {
  var streak = 0;
  for (final day in days.reversed) {
    if (!day.isPerfect) break;
    streak++;
  }
  return streak;
}

int bestStreak(List<GoalDay> days) {
  var best = 0;
  var run = 0;
  for (final day in days) {
    if (day.isPerfect) {
      run++;
      if (run > best) best = run;
    } else {
      run = 0;
    }
  }
  return best;
}

/// Share of applicable goals met across the whole range, 0..1.
double averageGoalScore(List<GoalDay> days) {
  final scored = days.where((d) => d.applicable.isNotEmpty).toList();
  if (scored.isEmpty) return 0;
  return scored.map((d) => d.score).reduce((a, b) => a + b) / scored.length;
}
