@Tags(['analytics'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/date_utils.dart';
import 'package:wellness_app/features/analytics/domain/analytics_input.dart';
import 'package:wellness_app/features/analytics/domain/analytics_range.dart';
import 'package:wellness_app/features/analytics/domain/goal_scoring.dart';

/// The hero chart's whole meaning is "how much of my life did I get right that
/// day", so the scoring rules are the part of this feature most worth pinning:
/// a wrong rule here is not a wrong pixel, it is the app telling someone they
/// failed on a day they did everything asked of them.
void main() {
  // A Wednesday. Fixed, because "today" in a streak test is otherwise a coin
  // flip that fails once a week.
  final wed = DateTime(2026, 8, 5);

  DateRange rangeOf(int days, {DateTime? endingOn}) {
    final end = AppDateUtils.startOfDay(endingOn ?? wed)
        .add(const Duration(days: 1));
    return DateRange(
      DateTime(end.year, end.month, end.day - days),
      end,
    );
  }

  DailyNutrition nutrition(DateTime day,
          {double kcal = 0, double protein = 0}) =>
      DailyNutrition(
        dateInt: AppDateUtils.dateToInt(day),
        kcal: kcal,
        protein: protein,
        carbs: 0,
        fat: 0,
        logged: true,
      );

  SleepNight sleep(DateTime day, double hours) => SleepNight(
        day: day,
        hours: hours,
        startedAt: DateTime(day.year, day.month, day.day - 1, 23),
      );

  TrainingSession session(DateTime day) => TrainingSession(
        id: 'S${day.day}',
        startedAt: DateTime(day.year, day.month, day.day, 18),
        duration: const Duration(minutes: 45),
        sets: const [TrainingSet(exerciseId: 'E', reps: 8, weightKg: 60)],
      );

  group('an unset goal is not a failed goal', () {
    test('only the goals actually configured are scored', () {
      final days = scoreGoalDays(
        range: rangeOf(1),
        targets: const GoalTargets(sleepGoalHours: 8),
        nutrition: const [],
        sessions: const [],
        sleep: [sleep(wed, 8.2)],
      );

      // Sleep is the only applicable goal, and it was met -- so the day is
      // perfect. Scoring the three unconfigured goals as misses would cap
      // every day at 25% with nothing on screen explaining why.
      expect(days.single.applicable, {WellnessGoal.sleep});
      expect(days.single.score, 1.0);
      expect(days.single.isPerfect, isTrue);
    });
  });

  group('the calorie goal follows what the user is training for', () {
    List<GoalDay> score(String profileGoal, double kcal) => scoreGoalDays(
          range: rangeOf(1),
          targets: GoalTargets(calorieGoal: 2000, profileGoal: profileGoal),
          nutrition: [nutrition(wed, kcal: kcal)],
          sessions: const [],
          sleep: const [],
        );

    bool met(String goal, double kcal) =>
        score(goal, kcal).single.met.contains(WellnessGoal.calories);

    test('comfortably under target is a win when cutting, not a failure', () {
      // The single most important case in this file. A flat +/-10% band marks
      // a fat-loss user's best day as a miss.
      expect(met('fat_loss', 1700), isTrue);
      expect(met('fat_loss', 2100), isFalse);
    });

    test('but starving is still a miss when cutting', () {
      expect(met('fat_loss', 900), isFalse);
    });

    test('bulking wants the target hit or beaten', () {
      expect(met('muscle_gain', 2300), isTrue);
      expect(met('muscle_gain', 1500), isFalse);
    });

    test('maintenance is a band on both sides', () {
      expect(met('maintenance', 2000), isTrue);
      expect(met('maintenance', 1500), isFalse);
      expect(met('maintenance', 2600), isFalse);
    });

    test('a day with nothing logged never counts as met', () {
      final days = scoreGoalDays(
        range: rangeOf(1),
        targets: const GoalTargets(calorieGoal: 2000, profileGoal: 'fat_loss'),
        nutrition: const [],
        sessions: const [],
        sleep: const [],
      );
      // Zero kcal is inside the fat-loss ceiling, so an unlogged day would
      // otherwise score as a perfect cutting day.
      expect(days.single.met.contains(WellnessGoal.calories), isFalse);
    });
  });

  group('training counts rest days once the week is done', () {
    test('a rest day after hitting the weekly target still scores', () {
      final sun = AppDateUtils.startOfWeek(wed);
      final days = scoreGoalDays(
        range: rangeOf(3),
        targets: const GoalTargets(trainingDaysPerWeek: 3),
        nutrition: const [],
        sessions: [
          session(sun),
          session(sun.add(const Duration(days: 1))),
          session(sun.add(const Duration(days: 2))),
        ],
        sleep: const [],
      );

      // Wednesday has no session, but the week's three are already done.
      // Scoring it as a miss would make a perfect week impossible for anyone
      // who does not train daily.
      final wednesday = days.firstWhere((d) => d.day == wed);
      expect(wednesday.met.contains(WellnessGoal.training), isTrue);
    });

    test('a rest day short of the target does not score', () {
      final days = scoreGoalDays(
        range: rangeOf(1),
        targets: const GoalTargets(trainingDaysPerWeek: 4),
        nutrition: const [],
        sessions: const [],
        sleep: const [],
      );
      expect(days.single.met.contains(WellnessGoal.training), isFalse);
    });
  });

  group('sleep', () {
    test('a near miss still counts', () {
      final days = scoreGoalDays(
        range: rangeOf(1),
        targets: const GoalTargets(sleepGoalHours: 8),
        nutrition: const [],
        sessions: const [],
        // 7h45m. Without the tolerance this is the goal nobody ever meets.
        sleep: [sleep(wed, 7.75)],
      );
      expect(days.single.met.contains(WellnessGoal.sleep), isTrue);
    });

    test('a real shortfall does not', () {
      final days = scoreGoalDays(
        range: rangeOf(1),
        targets: const GoalTargets(sleepGoalHours: 8),
        nutrition: const [],
        sessions: const [],
        sleep: [sleep(wed, 6)],
      );
      expect(days.single.met.contains(WellnessGoal.sleep), isFalse);
    });
  });

  group('streaks', () {
    List<GoalDay> perfectRun(int days, {int breakAt = -1}) {
      final range = rangeOf(days);
      return scoreGoalDays(
        range: range,
        targets: const GoalTargets(sleepGoalHours: 8),
        nutrition: const [],
        sessions: const [],
        sleep: [
          for (var i = 0; i < range.days.length; i++)
            if (i != breakAt) sleep(range.days[i], 8.5),
        ],
      );
    }

    test('counts back from the most recent day', () {
      expect(currentStreak(perfectRun(5)), 5);
    });

    test('a gap ends the current streak but not the best one', () {
      // Break two days in: the run after it is shorter than the run before.
      final days = perfectRun(6, breakAt: 3);
      expect(currentStreak(days), 2);
      expect(bestStreak(days), 3);
    });

    test('an unmet most-recent day means no current streak', () {
      expect(currentStreak(perfectRun(4, breakAt: 3)), 0);
    });
  });

  test('the average score ignores days with nothing configured', () {
    final days = scoreGoalDays(
      range: rangeOf(2),
      targets: const GoalTargets(sleepGoalHours: 8),
      nutrition: const [],
      sessions: const [],
      sleep: [sleep(wed, 9)],
    );

    // One night of two: 0.5, not 1.0 and not 0.
    expect(averageGoalScore(days), closeTo(0.5, 0.001));
  });
}
