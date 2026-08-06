@Tags(['workouts', 'catalog'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/workouts/domain/exercise_tags.dart';
import 'package:wellness_app/services/user_profile_service.dart';
import 'package:wellness_app/services/workout_programming.dart';
import 'package:wellness_app/services/workout_template_generator.dart';

/// What the generator actually produces, swept across the profile space.
///
/// `workout_programming_test.dart` proves the arithmetic in isolation; this
/// proves the generator applies it to the real catalog for every profile a
/// user can build. The failure it exists to prevent is the state the app
/// shipped in until now: every template `3 sets x 10 reps, no weight, no
/// rest`, for every goal and every person -- a placeholder that looked like a
/// program.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const goals = ['muscle_gain', 'fat_loss', 'maintenance', 'mobility_rehab'];
  const experiences = ['beginner', 'intermediate', 'advanced'];
  const equipmentSets = <List<String>>[
    [],
    ['dumbbells'],
    ['barbell_rack', 'dumbbells', 'cable', 'machines', 'pullup_bar'],
    ['bands'],
  ];

  UserProfile profile({
    String goal = 'muscle_gain',
    String experience = 'beginner',
    int days = 4,
    List<String> equipment = const ['dumbbells'],
    List<String> injuries = const [],
    String sex = 'male',
    int age = 30,
    double weightKg = 80,
  }) =>
      UserProfile(
        sex: sex,
        ageYears: age,
        heightCm: 178,
        weightKg: weightKg,
        goal: goal,
        activityLevel: 'moderate',
        trainingDaysPerWeek: days,
        trainingExperience: experience,
        equipment: equipment,
        dietType: 'omnivore',
        mealCountPerDay: '3',
        exclusions: const [],
        injuries: injuries,
        energyUnit: 'kcal',
        weightUnit: 'g',
        bmr: 1800,
        tdee: 2500,
        calorieTarget: 2500,
        proteinTargetG: 150,
        fatTargetG: 60,
        carbsTargetG: 300,
      );

  /// Generates for [p] and returns each training template with its rows.
  Future<List<({WorkoutTemplateData template, List<TemplateExerciseData> rows})>>
      generate(UserProfile p) async {
    AppDatabase.resetForTesting();
    final db = AppDatabase();
    final created = await WorkoutTemplateGenerator(db, p).generateTemplates();
    return [
      for (final t in created)
        (
          template: t,
          rows: await db.getTemplateExercisesByTemplateId(t.id),
        ),
    ];
  }

  /// Session duration implied by the stored prescription.
  Future<Duration> durationOf(
      AppDatabase db, List<TemplateExerciseData> rows) async {
    final prescriptions = <Prescription>[];
    for (final row in rows) {
      final exercise = await db.getExerciseById(row.exerciseId);
      prescriptions.add(Prescription(
        sets: row.defaultSets,
        reps: row.defaultReps ?? 10,
        rest: Duration(seconds: row.restSeconds),
        isCompound: exercise?.mechanicOrDefault == Mechanic.compound,
      ));
    }
    return WorkoutProgramming.sessionDuration(prescriptions);
  }

  group('every session is a real prescription', () {
    test('sets, reps and rest are always present', () async {
      for (final goal in goals) {
        for (final experience in experiences) {
          final plans = await generate(
              profile(goal: goal, experience: experience));
          expect(plans, isNotEmpty, reason: '$goal/$experience got no plan');

          for (final plan in plans) {
            expect(plan.rows, isNotEmpty, reason: plan.template.name);
            for (final row in plan.rows) {
              expect(row.defaultSets, greaterThan(0));
              expect(row.defaultReps, isNotNull,
                  reason: '"${plan.template.name}" has a set with no rep '
                      'target, which is not a prescription');
              expect(row.defaultRestSeconds, isNotNull,
                  reason: 'no rest means no time budget and no recovery');
            }
          }
        }
      }
    });

    test('the scheme actually varies by goal', () async {
      // The regression: everything was 3x10 regardless. If two different
      // goals still produce identical prescriptions, nothing was gained.
      final schemes = <String>{};
      for (final goal in goals) {
        final plans = await generate(profile(goal: goal));
        final row = plans.first.rows.first;
        schemes.add('${row.defaultSets}x${row.defaultReps}');
      }

      expect(schemes.length, greaterThan(1),
          reason: 'every goal produced the same sets and reps');
    });

    test('compounds rest longer than isolation within a session', () async {
      AppDatabase.resetForTesting();
      final db = AppDatabase();
      final created =
          await WorkoutTemplateGenerator(db, profile()).generateTemplates();

      for (final template in created) {
        final rows = await db.getTemplateExercisesByTemplateId(template.id);
        for (final row in rows) {
          final exercise = await db.getExerciseById(row.exerciseId);
          if (exercise == null) continue;
          final isCompound = exercise.mechanicOrDefault == Mechanic.compound;
          final scheme = WorkoutProgramming.schemeFor(
              isCompound ? 'muscle_gain' : 'muscle_gain');
          expect(
            row.defaultRestSeconds,
            isCompound
                ? scheme.compoundRest.inSeconds
                : scheme.isolationRest.inSeconds,
            reason: '"${exercise.name}" rests wrong for its mechanic',
          );
        }
      }
    });
  });

  group('time budget', () {
    test('no session anywhere in the profile space runs over an hour',
        () async {
      for (final goal in goals) {
        for (final experience in experiences) {
          for (final equipment in equipmentSets) {
            AppDatabase.resetForTesting();
            final db = AppDatabase();
            final created = await WorkoutTemplateGenerator(
                    db,
                    profile(
                        goal: goal,
                        experience: experience,
                        equipment: equipment))
                .generateTemplates();

            for (final template in created) {
              final rows = await db.getTemplateExercisesByTemplateId(template.id);
              final duration = await durationOf(db, rows);
              expect(duration, lessThanOrEqualTo(WorkoutProgramming.maxSession),
                  reason: '$goal/$experience/$equipment produced '
                      '"${template.name}" at ${duration.inMinutes} minutes');
            }
          }
        }
      }
    });

    test('a normal training session is not trivially short', () async {
      AppDatabase.resetForTesting();
      final db = AppDatabase();
      final created = await WorkoutTemplateGenerator(
              db, profile(equipment: const ['barbell_rack', 'dumbbells']))
          .generateTemplates();

      for (final template in created) {
        if (template.name.startsWith('Physiotherapy')) continue;
        final rows = await db.getTemplateExercisesByTemplateId(template.id);
        final duration = await durationOf(db, rows);
        expect(duration.inMinutes, greaterThanOrEqualTo(25),
            reason: '"${template.name}" is only ${duration.inMinutes} minutes; '
                'someone who set aside 45 got a warm-up');
      }
    });
  });

  group('load prescription', () {
    test('weight is present exactly when the exercise is kg-based', () async {
      // The safety property, verified end to end rather than in the unit.
      for (final experience in experiences) {
        AppDatabase.resetForTesting();
        final db = AppDatabase();
        final created = await WorkoutTemplateGenerator(
                db,
                profile(
                    experience: experience,
                    equipment: const ['barbell_rack', 'dumbbells', 'bands']))
            .generateTemplates();

        for (final template in created) {
          for (final row in await db.getTemplateExercisesByTemplateId(template.id)) {
            final exercise = await db.getExerciseById(row.exerciseId);
            if (exercise == null) continue;

            if (exercise.unit != 'kg') {
              expect(row.defaultWeight, isNull,
                  reason: '"${exercise.name}" is ${exercise.unit} but was '
                      'given ${row.defaultWeight}kg');
            } else if (exercise.loadClassOrDefault != LoadClass.none) {
              expect(row.defaultWeight, isNotNull,
                  reason: '"${exercise.name}" is loadable but got no weight');
              expect(row.defaultWeight! % 2.5, 0,
                  reason: 'not loadable on a real bar');
            }
          }
        }
      }
    });

    test('an advanced lifter is prescribed more than a beginner', () async {
      Future<double> totalFor(String experience) async {
        AppDatabase.resetForTesting();
        final db = AppDatabase();
        final created = await WorkoutTemplateGenerator(
                db,
                profile(
                    experience: experience,
                    equipment: const ['barbell_rack', 'dumbbells']))
            .generateTemplates();
        var sum = 0.0;
        for (final t in created) {
          for (final row in await db.getTemplateExercisesByTemplateId(t.id)) {
            sum += row.defaultWeight ?? 0;
          }
        }
        return sum;
      }

      expect(await totalFor('advanced'), greaterThan(await totalFor('beginner')));
    });

    test('a lighter person is prescribed less than a heavier one', () async {
      Future<double?> squatWeight(double bodyweight) async {
        AppDatabase.resetForTesting();
        final db = AppDatabase();
        final created = await WorkoutTemplateGenerator(
                db,
                profile(
                    weightKg: bodyweight,
                    equipment: const ['barbell_rack', 'dumbbells']))
            .generateTemplates();
        for (final t in created) {
          for (final row in await db.getTemplateExercisesByTemplateId(t.id)) {
            final exercise = await db.getExerciseById(row.exerciseId);
            if (exercise?.loadClassOrDefault == LoadClass.squatPattern) {
              return row.defaultWeight;
            }
          }
        }
        return null;
      }

      final light = await squatWeight(55);
      final heavy = await squatWeight(110);
      expect(light, isNotNull);
      expect(heavy, isNotNull);
      expect(light!, lessThan(heavy!));
    });
  });

  group('structure', () {
    test('one template per requested training day, for 1 through 7', () async {
      for (final days in [1, 2, 3, 4, 5, 6, 7]) {
        final plans = await generate(profile(days: days));
        expect(plans.where((p) => !p.template.name.startsWith('Physiotherapy')),
            hasLength(days),
            reason: 'asked for $days days and got '
                '${plans.length} templates');
      }
    });

    test('compounds are ordered before isolation', () async {
      AppDatabase.resetForTesting();
      final db = AppDatabase();
      final created = await WorkoutTemplateGenerator(
              db, profile(equipment: const ['barbell_rack', 'dumbbells']))
          .generateTemplates();

      for (final template in created) {
        if (template.name.startsWith('Physiotherapy')) continue;
        final rows = await db.getTemplateExercisesByTemplateId(template.id)
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

        var seenIsolation = false;
        for (final row in rows) {
          final exercise = await db.getExerciseById(row.exerciseId);
          final isCompound = exercise?.mechanicOrDefault == Mechanic.compound;
          if (!isCompound) seenIsolation = true;
          if (isCompound && seenIsolation) {
            fail('"${template.name}" puts ${exercise?.name} after isolation '
                'work; fatigue ruins technique on exactly the lifts where '
                'technique matters');
          }
        }
      }
    });

    test('a session never programs two lifts of the same pattern', () async {
      // Bench Press *and* Push-ups, Squats *and* Bodyweight Squat, Deadlift
      // *and* Romanian Deadlift all appeared together before selection went
      // breadth-first. No coach programs near-duplicates while whole patterns
      // and every accessory go untouched.
      AppDatabase.resetForTesting();
      final db = AppDatabase();
      final created = await WorkoutTemplateGenerator(
              db,
              profile(equipment: const [
                'barbell_rack',
                'dumbbells',
                'cable',
                'pullup_bar'
              ]))
          .generateTemplates();

      for (final template in created) {
        if (template.name.startsWith('Physiotherapy')) continue;
        final seen = <MovementPattern>{};
        for (final row in await db.getTemplateExercisesByTemplateId(template.id)) {
          final exercise = await db.getExerciseById(row.exerciseId);
          if (exercise == null) continue;
          if (exercise.mechanicOrDefault != Mechanic.compound) continue;
          expect(seen, isNot(contains(exercise.pattern)),
              reason: '"${template.name}" has two ${exercise.pattern.name} '
                  'compounds, the second of which is a near-duplicate');
          seen.add(exercise.pattern);
        }
      }
    });

    test('accessory work reaches the arms', () async {
      // Selecting accessories by pattern could never reach them: a curl and a
      // lateral raise are both MovementPattern.isolation, and only the muscle
      // says which belongs on a pull day.
      AppDatabase.resetForTesting();
      final db = AppDatabase();
      final created = await WorkoutTemplateGenerator(
              db,
              profile(days: 6, equipment: const [
                'barbell_rack',
                'dumbbells',
                'cable',
                'pullup_bar'
              ]))
          .generateTemplates();

      final muscles = <String>{};
      for (final template in created) {
        for (final row in await db.getTemplateExercisesByTemplateId(template.id)) {
          final exercise = await db.getExerciseById(row.exerciseId);
          if (exercise?.primaryMuscle != null) muscles.add(exercise!.primaryMuscle!);
        }
      }

      expect(muscles, contains('Biceps'));
      expect(muscles, contains('Triceps'));
    });

    test('a loaded lift is preferred over its bodyweight cousin', () async {
      // The progression rule on every template is "add 2.5kg", and you cannot
      // add 2.5kg to a push-up. An intermediate with a rack was prescribed
      // Push-ups purely because it sorts first in the catalog.
      AppDatabase.resetForTesting();
      final db = AppDatabase();
      final created = await WorkoutTemplateGenerator(
              db,
              profile(
                  days: 3,
                  equipment: const ['barbell_rack', 'dumbbells', 'pullup_bar']))
          .generateTemplates();

      final names = <String>{};
      for (final template in created) {
        for (final row in await db.getTemplateExercisesByTemplateId(template.id)) {
          final exercise = await db.getExerciseById(row.exerciseId);
          if (exercise != null) names.add(exercise.name);
        }
      }

      expect(names, contains('Bench Press'),
          reason: 'a barbell owner was given push-ups instead');
      expect(names, contains('Squats'));
    });

    test('templates carry a Hebrew name', () async {
      // WorkoutTemplateData has always had nameHe and the generator never
      // filled it, so a Hebrew user's plan came out entirely in English.
      final plans = await generate(profile(days: 6));
      for (final plan in plans) {
        expect(plan.template.nameHe, isNotNull,
            reason: '"${plan.template.name}" has no Hebrew name');
      }
    });

    test('the progression rule travels with the template', () async {
      // Static templates cannot progress by themselves, so the rule the user
      // applies has to be written down rather than assumed.
      final plans = await generate(profile());
      expect(plans.first.template.notes, contains('reserve'));
      expect(plans.first.template.notes, contains('starting estimate'),
          reason: 'a prescribed weight must not read as authoritative');
    });

    test('no profile is left without a plan', () async {
      // Including the worst case: nothing to train with and everything hurts.
      for (final equipment in equipmentSets) {
        final plans = await generate(profile(
          equipment: equipment,
          injuries: const ['shoulder', 'knee', 'back'],
        ));
        expect(plans, isNotEmpty, reason: 'equipment=$equipment');
      }
    });
  });
}
