@Tags(['analytics'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/features/analytics/domain/analytics_input.dart';
import 'package:wellness_app/features/analytics/domain/strength_progress.dart';

/// "Am I using the same weight for a while?" is the question this screen was
/// asked for, and both ways of getting it wrong are bad: a plateau that never
/// fires is useless, and one that fires on normal training teaches the user to
/// ignore the screen.
void main() {
  final start = DateTime(2026, 6, 1);

  TrainingSession sessionOn(
    int dayOffset, {
    required double weight,
    int reps = 8,
    int sets = 3,
    String exerciseId = 'bench',
  }) {
    final day = DateTime(start.year, start.month, start.day + dayOffset);
    return TrainingSession(
      id: 'S$dayOffset-$exerciseId',
      startedAt: DateTime(day.year, day.month, day.day, 18),
      duration: const Duration(minutes: 50),
      sets: [
        for (var i = 0; i < sets; i++)
          TrainingSet(exerciseId: exerciseId, reps: reps, weightKg: weight),
      ],
    );
  }

  group('estimated 1RM', () {
    test('a single rep is the load itself', () {
      // Epley returns 1.033x at one rep, which would report a PR for simply
      // doing a heavy single.
      expect(estimatedOneRepMax(100, 1), 100);
    });

    test('more reps at the same weight is more estimated 1RM', () {
      // The entire reason the chart plots e1RM instead of raw load.
      expect(estimatedOneRepMax(80, 10), greaterThan(estimatedOneRepMax(80, 8)));
    });
  });

  group('progress grouping', () {
    test('sessions are grouped per exercise, oldest first', () {
      final progress = buildExerciseProgress([
        sessionOn(0, weight: 60),
        sessionOn(7, weight: 62.5),
        sessionOn(3, weight: 40, exerciseId: 'row'),
      ]);

      expect(progress.keys.toSet(), {'bench', 'row'});
      expect(progress['bench']!.sessions.map((s) => s.topWeightKg),
          [60.0, 62.5]);
    });

    test('the top set is the heaviest, breaking ties on reps', () {
      final progress = buildExerciseProgress([
        TrainingSession(
          id: 'S',
          startedAt: start,
          duration: const Duration(minutes: 40),
          sets: const [
            TrainingSet(exerciseId: 'bench', reps: 5, weightKg: 80),
            TrainingSet(exerciseId: 'bench', reps: 8, weightKg: 80),
            TrainingSet(exerciseId: 'bench', reps: 12, weightKg: 60),
          ],
        ),
      ]);

      final point = progress['bench']!.sessions.single;
      expect(point.topWeightKg, 80);
      // Same load for more reps is the better set, and is the progress the
      // e1RM line exists to see.
      expect(point.repsAtTopWeight, 8);
    });

    test('bodyweight work has no 1RM but still counts as volume', () {
      final progress = buildExerciseProgress([
        TrainingSession(
          id: 'S',
          startedAt: start,
          duration: const Duration(minutes: 20),
          sets: const [TrainingSet(exerciseId: 'pushup', reps: 20)],
        ),
      ]);

      final point = progress['pushup']!.sessions.single;
      expect(point.e1rm, isNull);
      expect(point.setCount, 1);
    });
  });

  group('plateau detection', () {
    PlateauStatus? statusFor(List<TrainingSession> sessions) {
      final found =
          detectPlateaus(buildExerciseProgress(sessions)).where((p) => p.exerciseId == 'bench');
      return found.isEmpty ? null : found.first;
    }

    test('three sessions at one weight over three weeks is a plateau', () {
      final status = statusFor([
        sessionOn(0, weight: 80),
        sessionOn(10, weight: 80),
        sessionOn(21, weight: 80),
      ]);

      expect(status!.isPlateau, isTrue);
      expect(status.sessionsAtWeight, 3);
      expect(status.daysSinceIncrease, 21);
      expect(status.lastTopWeightKg, 80);
    });

    test('three sessions inside one week is a training block, not a plateau',
        () {
      // Both conditions are required precisely so this does not fire.
      final status = statusFor([
        sessionOn(0, weight: 80),
        sessionOn(2, weight: 80),
        sessionOn(4, weight: 80),
      ]);

      expect(status!.isPlateau, isFalse);
    });

    test('a weight that just went up is not a plateau', () {
      final status = statusFor([
        sessionOn(0, weight: 80),
        sessionOn(7, weight: 80),
        sessionOn(14, weight: 80),
        sessionOn(21, weight: 82.5),
      ]);

      expect(status!.isPlateau, isFalse);
      expect(status.daysSinceIncrease, 0);
      expect(status.isPersonalBest, isTrue);
    });

    test('a deload does not reset the stall clock', () {
      // Dropping the weight for a week is recovery, not evidence the working
      // weight moved -- treating it as a fresh start would hide a real stall.
      final status = statusFor([
        sessionOn(0, weight: 80),
        sessionOn(7, weight: 60),
        sessionOn(14, weight: 80),
        sessionOn(21, weight: 80),
      ]);

      expect(status!.sessionsAtWeight, 3);
      expect(status.daysSinceIncrease, 21);
      expect(status.isPlateau, isTrue);
    });

    test('more reps at the same weight is still flagged, but as a best', () {
      final status = statusFor([
        sessionOn(0, weight: 80, reps: 5),
        sessionOn(10, weight: 80, reps: 6),
        sessionOn(21, weight: 80, reps: 8),
      ]);

      // The weight genuinely has not moved, so the strip says so -- but the
      // e1RM did, so it is also the user's best, and the UI colours it that
      // way rather than red.
      expect(status!.isPlateau, isTrue);
      expect(status.isPersonalBest, isTrue);
    });

    test('bodyweight exercises are never flagged', () {
      final plateaus = detectPlateaus(buildExerciseProgress([
        for (final offset in [0, 10, 21])
          TrainingSession(
            id: 'S$offset',
            startedAt: DateTime(start.year, start.month, start.day + offset),
            duration: const Duration(minutes: 20),
            sets: const [TrainingSet(exerciseId: 'pushup', reps: 20)],
          ),
      ]));

      // "The same weight for weeks" is the definition of a push-up.
      expect(plateaus, isEmpty);
    });

    test('too few sessions to judge is not a plateau', () {
      expect(statusFor([sessionOn(0, weight: 80), sessionOn(20, weight: 80)]),
          isNull);
    });

    test('the longest stall sorts first', () {
      final plateaus = detectPlateaus(buildExerciseProgress([
        for (final offset in [0, 10, 20])
          sessionOn(offset, weight: 80, exerciseId: 'bench'),
        for (final offset in [0, 5, 9])
          sessionOn(offset, weight: 40, exerciseId: 'curl'),
      ]));

      expect(plateaus.first.exerciseId, 'bench');
    });
  });
}
