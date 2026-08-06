@Tags(['workouts'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/features/workouts/domain/exercise_tags.dart';
import 'package:wellness_app/services/workout_programming.dart';

/// [WorkoutProgramming] -- the domain judgement, verified without a database.
///
/// Two of these assertions are safety properties rather than correctness
/// ones, and are worth naming as such: a load is never prescribed for a
/// movement that has no external load, and an untagged exercise never
/// produces a number at all. Everything else here is "does the plan do what
/// it claims" -- chiefly that a session fits in the time a person actually
/// has, which the old fixed 3x10-for-everything never checked because it had
/// no concept of rest.
void main() {
  const goals = ['muscle_gain', 'fat_loss', 'maintenance', 'mobility_rehab'];
  const experiences = ['beginner', 'intermediate', 'advanced'];

  /// A realistic session for [goal]: the derived number of exercises, half
  /// compound and ordered compounds-first, as the generator will build them.
  List<Prescription> session(String goal) {
    final scheme = WorkoutProgramming.schemeFor(goal);
    final count = WorkoutProgramming.exerciseBudget(scheme);
    final compounds = (count / 2).ceil();
    return [
      for (var i = 0; i < count; i++)
        Prescription(
          sets: scheme.sets,
          reps: scheme.reps,
          rest: i < compounds ? scheme.compoundRest : scheme.isolationRest,
          isCompound: i < compounds,
        ),
    ];
  }

  group('session length', () {
    test('no goal produces a session over the hard ceiling', () {
      for (final goal in goals) {
        final duration = WorkoutProgramming.sessionDuration(session(goal));
        expect(duration, lessThanOrEqualTo(WorkoutProgramming.maxSession),
            reason: '$goal came out at ${duration.inMinutes} minutes; a '
                'session nobody has time for does not get done');
      }
    });

    test('sessions land near the 45-minute target, not far under it', () {
      // Undershooting is its own failure -- a 20-minute "workout" for someone
      // who set aside three quarters of an hour is a wasted session.
      for (final goal in goals.where((g) => g != 'mobility_rehab')) {
        final minutes = WorkoutProgramming.sessionDuration(session(goal)).inMinutes;
        expect(minutes, inInclusiveRange(38, 55), reason: '$goal: $minutes min');
      }
    });

    test('rehab sessions are deliberately shorter', () {
      // Their purpose is tissue tolerance, not accumulating volume.
      expect(WorkoutProgramming.sessionDuration(session('mobility_rehab')),
          lessThan(WorkoutProgramming.targetSession));
    });

    test('the last set costs no rest', () {
      // Counting rest after the final set inflates every estimate by a full
      // rest interval per exercise -- about eight minutes across a session.
      final one = WorkoutProgramming.exerciseDuration(
          sets: 1, reps: 10, rest: const Duration(seconds: 120), isCompound: false);
      final two = WorkoutProgramming.exerciseDuration(
          sets: 2, reps: 10, rest: const Duration(seconds: 120), isCompound: false);

      expect(two - one, const Duration(seconds: 120 + 30));
    });

    test('compounds cost their warm-up ramp', () {
      final compound = WorkoutProgramming.exerciseDuration(
          sets: 3, reps: 8, rest: const Duration(seconds: 120), isCompound: true);
      final isolation = WorkoutProgramming.exerciseDuration(
          sets: 3, reps: 8, rest: const Duration(seconds: 120), isCompound: false);

      expect(compound, greaterThan(isolation),
          reason: 'you do not walk up to a heavy squat and do a working set');
    });

    test('a tighter budget yields fewer exercises', () {
      final scheme = WorkoutProgramming.schemeFor('muscle_gain');

      expect(
        WorkoutProgramming.exerciseBudget(scheme,
            budget: const Duration(minutes: 25)),
        lessThan(WorkoutProgramming.exerciseBudget(scheme,
            budget: const Duration(minutes: 60))),
      );
    });
  });

  group('volume', () {
    test('rises with experience, for every goal', () {
      for (final goal in goals) {
        final beginner = WorkoutProgramming.weeklySetsPerMuscle(goal, 'beginner');
        final advanced = WorkoutProgramming.weeklySetsPerMuscle(goal, 'advanced');
        expect(advanced, greaterThanOrEqualTo(beginner), reason: goal);
      }
    });

    test('muscle gain targets the most, rehab the least', () {
      for (final experience in experiences) {
        expect(
          WorkoutProgramming.weeklySetsPerMuscle('muscle_gain', experience),
          greaterThan(
              WorkoutProgramming.weeklySetsPerMuscle('maintenance', experience)),
        );
        expect(
          WorkoutProgramming.weeklySetsPerMuscle('mobility_rehab', experience),
          lessThan(
              WorkoutProgramming.weeklySetsPerMuscle('maintenance', experience) + 1),
        );
      }
    });

    test('stays inside a range a human can recover from', () {
      for (final goal in goals) {
        for (final experience in experiences) {
          final sets = WorkoutProgramming.weeklySetsPerMuscle(goal, experience);
          expect(sets, inInclusiveRange(4, 20),
              reason: '$goal/$experience prescribes $sets sets per muscle per '
                  'week; beyond about 20 is fatigue nobody adapts to');
        }
      }
    });
  });

  group('load', () {
    const bodyweight = 80.0;

    double? weight({
      LoadClass loadClass = LoadClass.squatPattern,
      String unit = 'kg',
      String sex = 'male',
      String experience = 'beginner',
      int age = 30,
      int reps = 8,
    }) =>
        WorkoutProgramming.startingWeightKg(
          loadClass: loadClass,
          unit: unit,
          bodyweightKg: bodyweight,
          sex: sex,
          experience: experience,
          ageYears: age,
          reps: reps,
        );

    test('is never prescribed for a movement with no external load', () {
      // Safety property. A band, a bodyweight movement and a timed walk have
      // no barbell weight to give, and inventing one is how a generator hurts
      // somebody.
      for (final unit in ['bodyweight', 'band', 'min']) {
        expect(weight(unit: unit), isNull, reason: unit);
      }
    });

    test('an untagged exercise gets no number at all', () {
      // The other half of the same property: `LoadClass.none` is what every
      // missing or unrecognised tag resolves to.
      expect(weight(loadClass: LoadClass.none), isNull);
    });

    test('rises monotonically with experience', () {
      final beginner = weight(experience: 'beginner')!;
      final intermediate = weight(experience: 'intermediate')!;
      final advanced = weight(experience: 'advanced')!;

      expect(intermediate, greaterThan(beginner));
      expect(advanced, greaterThan(intermediate));
    });

    test('women are not prescribed male upper-body loads', () {
      // Ignoring sex would over-prescribe for half of all users. The gap is
      // larger on upper body than lower, which is why both are checked.
      for (final loadClass in [LoadClass.benchPattern, LoadClass.pressPattern]) {
        expect(weight(loadClass: loadClass, sex: 'female')!,
            lessThan(weight(loadClass: loadClass, sex: 'male')!),
            reason: loadClass.name);
      }
      expect(weight(loadClass: LoadClass.squatPattern, sex: 'female')!,
          lessThan(weight(loadClass: LoadClass.squatPattern, sex: 'male')!));
    });

    test('higher reps mean lighter weight', () {
      expect(weight(reps: 14)!, lessThan(weight(reps: 5)!));
    });

    test('tapers with age, but never collapses', () {
      expect(weight(age: 65)!, lessThan(weight(age: 30)!));
      expect(WorkoutProgramming.ageFactor(30), 1.0);
      expect(WorkoutProgramming.ageFactor(40), 1.0,
          reason: 'the taper starts after 40, it is not a cliff at 40');
      expect(WorkoutProgramming.ageFactor(90), greaterThanOrEqualTo(0.85));
    });

    test('lands on something loadable, and never below an empty bar plate', () {
      for (final loadClass in LoadClass.values) {
        for (final experience in experiences) {
          final kg = weight(loadClass: loadClass, experience: experience);
          if (kg == null) continue;
          expect(kg % 2.5, 0,
              reason: '$kg kg cannot be loaded on a real bar');
          expect(kg, greaterThanOrEqualTo(2.5));
        }
      }
    });

    test('a beginner squat is plausible rather than absurd', () {
      // The sanity check a coach would apply: a novice 80kg man working sets
      // of 8 belongs somewhere around 35-50kg, not 15 and not 120.
      expect(weight(reps: 8)!, inInclusiveRange(30, 55));
    });

    test('percent of 1RM matches the standard relation', () {
      expect(WorkoutProgramming.percentOfOneRepMax(1), 1.0);
      expect(WorkoutProgramming.percentOfOneRepMax(5), closeTo(0.86, 0.02));
      expect(WorkoutProgramming.percentOfOneRepMax(10), closeTo(0.75, 0.02));
      expect(WorkoutProgramming.percentOfOneRepMax(14), closeTo(0.68, 0.02));
    });
  });

  group('scheme', () {
    test('compounds always rest longer than isolation', () {
      for (final goal in goals) {
        final scheme = WorkoutProgramming.schemeFor(goal);
        expect(scheme.compoundRest, greaterThan(scheme.isolationRest),
            reason: goal);
        expect(scheme.restFor(Mechanic.compound), scheme.compoundRest);
        expect(scheme.restFor(Mechanic.isolation), scheme.isolationRest);
      }
    });

    test('fat loss trains denser than muscle gain', () {
      final cut = WorkoutProgramming.schemeFor('fat_loss');
      final bulk = WorkoutProgramming.schemeFor('muscle_gain');

      expect(cut.reps, greaterThan(bulk.reps));
      expect(cut.compoundRest, lessThan(bulk.compoundRest));
    });

    test('nobody is sent to failure on every set', () {
      for (final goal in goals) {
        expect(WorkoutProgramming.schemeFor(goal).repsInReserve,
            greaterThanOrEqualTo(1),
            reason: '$goal trains to failure, which is how novices get hurt');
      }
    });

    test('an unknown goal falls back rather than throwing', () {
      // Profiles are strings from storage; a value from a future build must
      // not take onboarding down.
      expect(WorkoutProgramming.schemeFor('astronaut').sets, greaterThan(0));
      expect(WorkoutProgramming.weeklySetsPerMuscle('astronaut', 'zebra'),
          greaterThan(0));
    });
  });

  group('ordering', () {
    test('compounds come before isolation', () {
      expect(
        WorkoutProgramming.orderRank(MovementPattern.squat, Mechanic.compound),
        lessThan(WorkoutProgramming.orderRank(
            MovementPattern.isolation, Mechanic.isolation)),
      );
    });

    test('the heaviest patterns come first', () {
      // Fatigue ruins technique on exactly the lifts where technique matters.
      expect(
        WorkoutProgramming.orderRank(MovementPattern.squat, Mechanic.compound),
        lessThan(WorkoutProgramming.orderRank(
            MovementPattern.lunge, Mechanic.compound)),
      );
    });

    test('core bracing comes last', () {
      // Everything else relies on the trunk holding position, so it is the one
      // thing that should be tired at the end rather than the start.
      final core =
          WorkoutProgramming.orderRank(MovementPattern.coreBrace, Mechanic.isolation);
      for (final pattern in MovementPattern.values) {
        if (pattern == MovementPattern.coreBrace) continue;
        expect(core,
            greaterThan(WorkoutProgramming.orderRank(pattern, Mechanic.compound)),
            reason: pattern.name);
      }
    });
  });
}
