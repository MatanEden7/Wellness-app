import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/template_origin.dart';
import '../data/db/drift_database.dart';
import '../features/workouts/domain/exercise_tags.dart';
import '../features/workouts/domain/models.dart';
import 'profile_fit.dart';
import 'user_profile_service.dart';

/// Builds workout templates for a profile by **selecting from the seeded
/// exercise library**, not by inventing exercises.
///
/// The previous version minted its own `ExerciseData` rows with the
/// equipment baked into their names ('Barbell Bench Press', 'Dumbbell Bench
/// Press', 'Push-ups') and inserted them alongside the 16 already in the
/// library. That produced near-duplicate entries after onboarding, and left
/// the library itself unfilterable, because "needs a barbell" only existed
/// inside a string. Equipment and injury contraindications are now real
/// fields on [Exercise] and every choice goes through [ProfileFit], so the
/// generator and the browsing UI agree by construction.
class WorkoutTemplateGenerator {
  WorkoutTemplateGenerator(this._database, this._profile);

  final AppDatabase _database;
  final UserProfile _profile;
  final _uuid = const Uuid();

  /// Muscle groups a session should cover, matched against
  /// `Exercise.primaryMuscle`.
  static const _push = ['Chest', 'Shoulders', 'Triceps'];
  static const _pull = ['Back', 'Biceps'];
  static const _legs = ['Quadriceps', 'Hamstrings', 'Glutes', 'Calves'];
  static const _core = ['Core'];

  Future<List<WorkoutTemplateData>> generateTemplates() async {
    final all = await _database.getAllExercises();
    final available = all.where(_fits).toList();
    if (available.isEmpty) {
      debugPrint('[WORKOUT-GEN] No exercises fit this profile; skipping');
      return const [];
    }

    final created = <WorkoutTemplateData>[];

    // One template per training day the user asked for. Previously this
    // produced a fixed 2-3 templates regardless, so someone who said "I
    // train 6 days a week" got three -- the answer was collected and then
    // ignored.
    final plan = _sessionsFor(_profile.trainingDaysPerWeek);
    for (final day in plan) {
      final picks = _pick(available, day.muscles, day.exercisesPerSession);
      if (picks.isEmpty) continue;
      created.add(await _write(day.name, day.notes, picks));
    }

    // Plus a physiotherapy session per reported injury, built from the
    // rehabFor pool rather than "whatever isn't contraindicated" -- being
    // safe with a bad shoulder is not the same as rehabilitating one.
    for (final injury in _profile.injuries) {
      final part = BodyPart.forProfileId(injury);
      if (part == null) continue; // 'none'
      final rehab = all
          .where((e) => e.rehabFor.contains(part) && _fits(e))
          .toList();
      if (rehab.isEmpty) continue;
      created.add(await _write(
        'Physiotherapy — ${part.label}',
        'Rehab work for your ${part.label.toLowerCase()}. Low load; safe on '
            'a rest day.',
        rehab.take(5).toList(),
        sets: 2,
        reps: 12,
      ));
    }

    debugPrint('[WORKOUT-GEN] Generated ${created.length} templates '
        '(${plan.length} training + ${created.length - plan.length} rehab)');
    return created;
  }

  bool _fits(ExerciseData data) => ProfileFit.exerciseFits(
        Exercise(
          id: data.id,
          name: data.name,
          unit: data.unit,
          primaryMuscle: data.primaryMuscle,
          equipment: data.equipment,
          contraindicatedFor: data.contraindicatedFor,
          rehabFor: data.rehabFor,
        ),
        _profile,
      );

  Future<WorkoutTemplateData> _write(
    String name,
    String notes,
    List<ExerciseData> picks, {
    int sets = 3,
    int reps = 10,
  }) async {
    final template = WorkoutTemplateData(
      id: _uuid.v4(),
      name: name,
      notes: notes,
      // Marked generated so a later profile change can replace it without
      // touching anything the user built. See ProfileFit.isReplaceable.
      origin: TemplateOrigin.generated,
    );
    await _database.insertWorkoutTemplate(template);
    for (var i = 0; i < picks.length; i++) {
      await _database.insertTemplateExercise(TemplateExerciseData(
        id: _uuid.v4(),
        templateId: template.id,
        exerciseId: picks[i].id,
        orderIndex: i,
        defaultSets: sets,
        defaultReps: reps,
      ));
    }
    return template;
  }

  /// Exactly [days] sessions, following the split convention for that
  /// frequency: full-body when training infrequently (each session has to
  /// cover everything), upper/lower at 4, push/pull/legs at 5+, cycling the
  /// pattern to fill the week.
  ///
  /// `goal` is intentionally not consulted -- per the product decision it
  /// drives calorie and macro targets only, not template selection.
  List<_SessionPlan> _sessionsFor(int days) {
    final count = days.clamp(1, 7);
    late final List<_SessionPlan> pattern;

    if (count <= 3) {
      pattern = const [
        _SessionPlan('Full Body A', 'Every major muscle group',
            [..._push, ..._pull, ..._legs, ..._core], 6),
        _SessionPlan('Full Body B', 'Same coverage, different selection',
            [..._legs, ..._pull, ..._push, ..._core], 6),
        _SessionPlan('Full Body C', 'Third variation to keep it fresh',
            [..._pull, ..._legs, ..._push, ..._core], 6),
      ];
    } else if (count == 4) {
      pattern = const [
        _SessionPlan('Upper Body A', 'Chest, back, shoulders and arms',
            [..._push, ..._pull], 6),
        _SessionPlan('Lower Body A', 'Legs and core', [..._legs, ..._core], 6),
        _SessionPlan('Upper Body B', 'Upper body, second variation',
            [..._pull, ..._push], 6),
        _SessionPlan('Lower Body B', 'Lower body, second variation',
            [..._legs, ..._core], 6),
      ];
    } else {
      pattern = const [
        _SessionPlan('Push Day', 'Chest, shoulders and triceps', _push, 5),
        _SessionPlan('Pull Day', 'Back and biceps', _pull, 5),
        _SessionPlan('Leg Day', 'Quads, hamstrings, glutes and calves',
            [..._legs, ..._core], 5),
      ];
    }

    // Cycle the pattern up to `count`, suffixing repeats so names stay
    // distinct (Push Day, ... , Push Day 2).
    return [
      for (var i = 0; i < count; i++)
        () {
          final base = pattern[i % pattern.length];
          final cycle = (i ~/ pattern.length) + 1;
          return cycle == 1
              ? base
              : _SessionPlan('${base.name} $cycle', base.notes, base.muscles,
                  base.exercisesPerSession);
        }(),
    ];
  }

  /// Picks up to [count] exercises spread across [muscles], taking one per
  /// group before doubling up on any of them -- otherwise a session becomes
  /// four chest movements simply because chest has the most options.
  List<ExerciseData> _pick(
    List<ExerciseData> available,
    List<String> muscles,
    int count,
  ) {
    final byMuscle = {
      for (final muscle in muscles)
        muscle: available.where((e) => e.primaryMuscle == muscle).toList(),
    };

    final picked = <ExerciseData>[];
    var round = 0;
    while (picked.length < count) {
      var addedThisRound = false;
      for (final muscle in muscles) {
        if (picked.length >= count) break;
        final options = byMuscle[muscle] ?? const <ExerciseData>[];
        if (round < options.length) {
          picked.add(options[round]);
          addedThisRound = true;
        }
      }
      if (!addedThisRound) break; // every group exhausted
      round++;
    }

    // Backfill. When most of a group is contraindicated -- e.g. a shoulder
    // injury guts Push day -- the loop above returns two exercises and calls
    // it a session. Top up from anything else available so the user still
    // gets a workout worth doing.
    if (picked.length < count) {
      for (final exercise in available) {
        if (picked.length >= count) break;
        if (!picked.contains(exercise)) picked.add(exercise);
      }
    }
    return picked;
  }

}

class _SessionPlan {
  const _SessionPlan(this.name, this.notes, this.muscles, this.exercisesPerSession);

  final String name;
  final String notes;
  final List<String> muscles;
  final int exercisesPerSession;
}
