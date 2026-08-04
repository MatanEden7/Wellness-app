import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/template_origin.dart';
import '../data/db/drift_database.dart';
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
    final available = await _availableExercises();
    if (available.isEmpty) {
      // Unreachable with the seeded catalog -- the coverage test proves a
      // full-body program survives every equipment/injury combination -- but
      // a user who deleted their whole library shouldn't crash onboarding.
      debugPrint('[WORKOUT-GEN] No exercises fit this profile; skipping');
      return const [];
    }

    final plan = _splitForTrainingDays(_profile.trainingDaysPerWeek);
    debugPrint('[WORKOUT-GEN] ${_profile.trainingDaysPerWeek} days/week -> '
        '${plan.length} template(s), ${available.length} exercises available');

    final created = <WorkoutTemplateData>[];
    for (final day in plan) {
      final picks = _pick(available, day.muscles, day.exercisesPerSession);
      if (picks.isEmpty) continue;

      final template = WorkoutTemplateData(
        id: _uuid.v4(),
        name: day.name,
        notes: day.notes,
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
          defaultSets: day.sets,
          defaultReps: day.reps,
        ));
      }
      created.add(template);
    }

    debugPrint('[WORKOUT-GEN] Generated ${created.length} workout templates');
    return created;
  }

  /// Library entries this user can actually perform -- owns the equipment
  /// for, and not contraindicated by any of their injuries.
  Future<List<ExerciseData>> _availableExercises() async {
    final all = await _database.getAllExercises();
    return all.where((data) {
      final exercise = Exercise(
        id: data.id,
        name: data.name,
        unit: data.unit,
        primaryMuscle: data.primaryMuscle,
        equipment: data.equipment,
        contraindicatedFor: data.contraindicatedFor,
      );
      return ProfileFit.exerciseFits(exercise, _profile);
    }).toList();
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
    return picked;
  }

  /// The split to run for a given weekly frequency.
  ///
  /// Deliberately conventional: full-body when training 1-3 days (each
  /// session has to cover everything), upper/lower at 4, push/pull/legs at
  /// 5+. `goal` is intentionally not consulted -- per the product decision
  /// it drives calorie and macro targets only, not template selection.
  List<_SessionPlan> _splitForTrainingDays(int days) {
    if (days <= 3) {
      return const [
        _SessionPlan(
          name: 'Full Body A',
          notes: 'Covers every major muscle group in one session',
          muscles: [..._push, ..._pull, ..._legs, ..._core],
          exercisesPerSession: 6,
        ),
        _SessionPlan(
          name: 'Full Body B',
          notes: 'Same coverage, different movement selection',
          muscles: [..._legs, ..._pull, ..._push, ..._core],
          exercisesPerSession: 6,
        ),
      ];
    }

    if (days == 4) {
      return const [
        _SessionPlan(
          name: 'Upper Body',
          notes: 'Chest, back, shoulders and arms',
          muscles: [..._push, ..._pull],
          exercisesPerSession: 6,
        ),
        _SessionPlan(
          name: 'Lower Body',
          notes: 'Legs and core',
          muscles: [..._legs, ..._core],
          exercisesPerSession: 6,
        ),
      ];
    }

    return const [
      _SessionPlan(
        name: 'Push Day',
        notes: 'Chest, shoulders and triceps',
        muscles: _push,
        exercisesPerSession: 5,
      ),
      _SessionPlan(
        name: 'Pull Day',
        notes: 'Back and biceps',
        muscles: _pull,
        exercisesPerSession: 5,
      ),
      _SessionPlan(
        name: 'Leg Day',
        notes: 'Quads, hamstrings, glutes and calves',
        muscles: [..._legs, ..._core],
        exercisesPerSession: 5,
      ),
    ];
  }
}

class _SessionPlan {
  const _SessionPlan({
    required this.name,
    required this.notes,
    required this.muscles,
    required this.exercisesPerSession,
  });

  final String name;
  final String notes;
  final List<String> muscles;
  final int exercisesPerSession;

  /// Fixed for now: 3x10 is a reasonable default for every split here, and
  /// the user can adjust per-exercise in the template editor.
  int get sets => 3;
  int get reps => 10;
}
