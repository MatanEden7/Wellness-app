import 'dart:math' as math;

import '../features/workouts/domain/exercise_tags.dart';

/// How a session is actually programmed: how many sets and reps, how long to
/// rest, how much to lift, and how long the whole thing takes.
///
/// Pure functions over plain values -- no database, no providers. That is
/// deliberate: this is the part with real domain judgement in it, and it
/// should be verifiable without constructing an app.
///
/// The generator previously wrote `3 sets x 10 reps, no weight, no rest` for
/// every exercise, every goal and every user. That is not a program, it is a
/// placeholder. Three things drive everything here instead:
///
///  * **Volume** -- weekly sets per muscle is the primary driver of
///    hypertrophy, and the number amateur plans get wrong in both directions.
///  * **Rest** -- the difference between a 45-minute session and a 75-minute
///    one, and between how a heavy compound and a cable curl should be run.
///  * **Duration** -- a session nobody has time for does not get done, so
///    exercise count is *derived* from the time budget rather than fixed.
abstract final class WorkoutProgramming {
  // ---------------------------------------------------------------- targets

  /// Target session length, and the ceiling nothing may exceed.
  static const Duration targetSession = Duration(minutes: 45);
  static const Duration maxSession = Duration(minutes: 60);

  /// General warm-up before the first working set.
  static const Duration warmup = Duration(minutes: 5);

  /// Seconds per rep under load. A controlled rep is roughly 3s; higher-rep
  /// work is run a little faster.
  static double secondsPerRep(int reps) => reps >= 13 ? 2.5 : 3.0;

  /// Ramp-up sets before the first working set of a compound. Short, light,
  /// and real time on the clock -- ignoring them is how a plan that claims
  /// 45 minutes takes an hour.
  static const int warmupSetsPerCompound = 2;
  static const Duration warmupSetCost = Duration(seconds: 45);

  // ------------------------------------------------------------------ goal

  /// The rep scheme for a goal, with rest split by mechanic.
  ///
  /// One rest value for a whole session is wrong in both directions: three
  /// minutes on cable curls wastes a third of the session, sixty seconds on
  /// squats degrades every set that follows.
  static RepScheme schemeFor(String goal) {
    switch (goal) {
      case 'muscle_gain':
        return const RepScheme(
          sets: 4,
          reps: 8,
          compoundRest: Duration(seconds: 150),
          isolationRest: Duration(seconds: 75),
          repsInReserve: 2,
        );
      case 'fat_loss':
        // Shorter rest, higher reps: more total work in the same time. The
        // training itself is not what creates the deficit, but density keeps
        // the session useful while calories are low.
        return const RepScheme(
          sets: 3,
          reps: 14,
          compoundRest: Duration(seconds: 75),
          isolationRest: Duration(seconds: 45),
          repsInReserve: 2,
        );
      case 'mobility_rehab':
        return const RepScheme(
          sets: 2,
          reps: 12,
          compoundRest: Duration(seconds: 60),
          isolationRest: Duration(seconds: 45),
          repsInReserve: 4,
        );
      case 'maintenance':
      default:
        return const RepScheme(
          sets: 3,
          reps: 10,
          compoundRest: Duration(seconds: 120),
          isolationRest: Duration(seconds: 60),
          repsInReserve: 3,
        );
    }
  }

  /// Weekly sets per muscle group the plan aims for.
  ///
  /// Volume is the main hypertrophy driver; too little does nothing and too
  /// much outruns recovery. Beginners need less to progress and recover from
  /// less, so this scales with experience as well as goal.
  static int weeklySetsPerMuscle(String goal, String experience) {
    final base = switch (goal) {
      'muscle_gain' => 10,
      'fat_loss' => 8,
      'mobility_rehab' => 4,
      _ => 6,
    };
    final bump = switch (experience) {
      'advanced' => 8,
      'intermediate' => 4,
      _ => 0,
    };
    // Rehab work is capped: its purpose is tissue tolerance, not volume.
    return goal == 'mobility_rehab' ? math.min(base + bump, 6) : base + bump;
  }

  // ------------------------------------------------------------------ load

  /// Fraction of a one-rep max that a set of [reps] can be run at.
  ///
  /// Epley, inverted. Used to turn a strength standard (a 1RM estimate) into
  /// the weight for the prescribed rep range.
  static double percentOfOneRepMax(int reps) {
    if (reps <= 1) return 1.0;
    return 1 / (1 + reps / 30.0);
  }

  /// Estimated one-rep max as a multiple of bodyweight.
  ///
  /// Population statistics, not a measurement -- which is exactly why the
  /// result is presented as a starting estimate to adjust on set one.
  ///
  /// Sex is a real term, not a nicety: female upper-body standards run around
  /// 60-65% of male at equal bodyweight and lower body around 75-80%.
  /// Ignoring it would over-prescribe for half of all users.
  static double? _bodyweightMultiple(
    LoadClass loadClass,
    String sex,
    String experience,
  ) {
    if (loadClass == LoadClass.none) return null;

    final level = switch (experience) {
      'advanced' => 2,
      'intermediate' => 1,
      _ => 0,
    };
    final female = sex == 'female';

    const male = {
      LoadClass.squatPattern: [0.60, 1.00, 1.40],
      LoadClass.deadliftPattern: [0.75, 1.25, 1.75],
      LoadClass.benchPattern: [0.45, 0.75, 1.10],
      LoadClass.pressPattern: [0.30, 0.50, 0.70],
      LoadClass.accessory: [0.10, 0.18, 0.25],
    };
    const womenTable = {
      LoadClass.squatPattern: [0.45, 0.75, 1.05],
      LoadClass.deadliftPattern: [0.55, 0.90, 1.30],
      LoadClass.benchPattern: [0.28, 0.45, 0.65],
      LoadClass.pressPattern: [0.18, 0.30, 0.45],
      LoadClass.accessory: [0.07, 0.12, 0.18],
    };

    final table = female ? womenTable : male;
    return table[loadClass]?[level];
  }

  /// Recovery and tissue tolerance decline with age. Flat to 40, then a
  /// gentle taper -- not a cliff, and never below 85%.
  static double ageFactor(int ageYears) {
    if (ageYears <= 40) return 1.0;
    return math.max(0.85, 1.0 - (ageYears - 40) * 0.006);
  }

  /// A starting working weight in kg, or null when prescribing one would be
  /// meaningless.
  ///
  /// Returns null for anything that is not barbell/dumbbell loaded. A
  /// bodyweight, band or time-based movement has no external load to give,
  /// and an untagged exercise resolves to [LoadClass.none] -- so a missing
  /// tag can never produce a dangerous number.
  static double? startingWeightKg({
    required LoadClass loadClass,
    required String unit,
    required double bodyweightKg,
    required String sex,
    required String experience,
    required int ageYears,
    required int reps,
  }) {
    if (unit != 'kg') return null;
    final multiple = _bodyweightMultiple(loadClass, sex, experience);
    if (multiple == null) return null;

    final oneRepMax = bodyweightKg * multiple;
    final raw = oneRepMax * percentOfOneRepMax(reps) * ageFactor(ageYears);

    // Rounded to something loadable on a real bar or rack.
    final rounded = (raw / 2.5).round() * 2.5;
    return math.max(2.5, rounded);
  }

  // -------------------------------------------------------------- duration

  /// How long one exercise takes, warm-up sets included for compounds.
  static Duration exerciseDuration({
    required int sets,
    required int reps,
    required Duration rest,
    required bool isCompound,
  }) {
    final work = secondsPerRep(reps) * reps;
    // The last set needs no rest after it -- counting it inflates every
    // estimate by one full rest interval per exercise.
    final seconds = sets * work + (sets - 1) * rest.inSeconds;
    final ramp = isCompound ? warmupSetsPerCompound * warmupSetCost.inSeconds : 0;
    return Duration(seconds: seconds.round() + ramp);
  }

  /// Total session length for a list of prescriptions.
  static Duration sessionDuration(Iterable<Prescription> prescriptions) {
    var total = warmup;
    for (final p in prescriptions) {
      total += exerciseDuration(
        sets: p.sets,
        reps: p.reps,
        rest: p.rest,
        isCompound: p.isCompound,
      );
    }
    return total;
  }

  /// How many exercises fit in [budget] under [scheme].
  ///
  /// This is the piece that makes the plan honest. A fixed "six exercises"
  /// runs about 45 minutes at 3x10 and roughly 75 at 4x8 with real compound
  /// rest -- the same session shape blowing straight through the ceiling
  /// purely because nobody counted the rest.
  ///
  /// [compoundShare] is how many of the picks are compounds, which cost more.
  static int exerciseBudget(
    RepScheme scheme, {
    Duration budget = targetSession,
    double compoundShare = 0.5,
    int minimum = 3,
    int maximum = 9,
  }) {
    final available = budget - warmup;
    if (available <= Duration.zero) return minimum;

    final compoundCost = exerciseDuration(
      sets: scheme.sets,
      reps: scheme.reps,
      rest: scheme.compoundRest,
      isCompound: true,
    ).inSeconds;
    final isolationCost = exerciseDuration(
      sets: scheme.sets,
      reps: scheme.reps,
      rest: scheme.isolationRest,
      isCompound: false,
    ).inSeconds;

    final averageCost =
        compoundCost * compoundShare + isolationCost * (1 - compoundShare);
    if (averageCost <= 0) return minimum;

    final fits = (available.inSeconds / averageCost).floor();
    return fits.clamp(minimum, maximum);
  }

  // --------------------------------------------------------------- ordering

  /// Session order: compounds before isolation, and the heaviest patterns
  /// first.
  ///
  /// Fatigue ruins technique on exactly the movements where technique matters
  /// most, so a squat belongs at the start and a lateral raise at the end.
  static int orderRank(MovementPattern pattern, Mechanic mechanic) {
    if (mechanic == Mechanic.compound) {
      return switch (pattern) {
        MovementPattern.squat => 0,
        MovementPattern.hinge => 1,
        MovementPattern.verticalPush => 2,
        MovementPattern.horizontalPush => 3,
        MovementPattern.verticalPull => 4,
        MovementPattern.horizontalPull => 5,
        MovementPattern.lunge => 6,
        MovementPattern.carry => 7,
        _ => 8,
      };
    }
    // Core bracing goes last: it is the one thing that should be fatigued at
    // the end rather than the start, because everything else relies on it.
    return pattern == MovementPattern.coreBrace ? 20 : 10;
  }
}

/// Sets, reps, rest and proximity to failure for a goal.
class RepScheme {
  const RepScheme({
    required this.sets,
    required this.reps,
    required this.compoundRest,
    required this.isolationRest,
    required this.repsInReserve,
  });

  final int sets;
  final int reps;
  final Duration compoundRest;
  final Duration isolationRest;

  /// Reps left in the tank on the last set. Training to failure on every set
  /// is how novices get hurt and how everyone accumulates fatigue they cannot
  /// use.
  final int repsInReserve;

  Duration restFor(Mechanic mechanic) =>
      mechanic == Mechanic.compound ? compoundRest : isolationRest;
}

/// One exercise as prescribed, independent of which exercise it is.
class Prescription {
  const Prescription({
    required this.sets,
    required this.reps,
    required this.rest,
    required this.isCompound,
    this.weightKg,
  });

  final int sets;
  final int reps;
  final Duration rest;
  final bool isCompound;

  /// Null when no external load applies -- bodyweight, bands, or time.
  final double? weightKg;
}
