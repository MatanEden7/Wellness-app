@Tags(['catalog'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:wellness_app/data/catalog/starter_exercises.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/workouts/domain/exercise_tags.dart';

/// The audit that keeps the exercise library *usable*, not merely well-formed.
///
/// Field-level checks are the easy half. The half that matters is coverage:
/// a library where every row is perfectly tagged can still be unable to
/// program a session, and that is exactly what this one was. Before these
/// tests there were zero bodyweight hamstring, shoulder and biceps exercises,
/// no `carry` movement at all, and four of the seven body parts could not fill
/// a physiotherapy session without bands.
void main() {
  final all = StarterExerciseLibrary.all;
  final training = StarterExerciseLibrary.training;

  /// The equipment a user might actually have. `bodyweight only` is the case
  /// that kept breaking, because it is the one nothing else compensates for.
  const kits = <String, Set<Equipment>>{
    'bodyweight only': {Equipment.bodyweight},
    'bands': {Equipment.bodyweight, Equipment.bands},
    'dumbbells': {Equipment.bodyweight, Equipment.dumbbells},
    'full gym': {
      Equipment.bodyweight,
      Equipment.dumbbells,
      Equipment.barbellRack,
      Equipment.machines,
      Equipment.bands,
      Equipment.kettlebells,
      Equipment.cable,
      Equipment.pullupBar,
    },
  };

  bool availableWith(StarterExercise e, Set<Equipment> kit) =>
      e.equipment.isEmpty || e.equipment.any(kit.contains);

  group('every row is well formed', () {
    test('ids are unique', () {
      final seen = <String, String>{};
      for (final e in all) {
        expect(seen.containsKey(e.id), isFalse,
            reason: 'id ${e.id}: ${seen[e.id]} and ${e.name}');
        seen[e.id] = e.name;
      }
    });

    test('names are unique', () {
      final seen = <String>{};
      for (final e in all) {
        expect(seen.add(e.name), isTrue, reason: 'duplicate: ${e.name}');
      }
    });

    test('every row has notes and a Hebrew name', () {
      final hebrew = RegExp(r'[֐-׿]');
      for (final e in all) {
        expect(e.notes.trim(), isNotEmpty, reason: '${e.name} has no notes');
        expect(e.nameHe.trim(), isNotEmpty, reason: '${e.name} has no nameHe');
        expect(hebrew.hasMatch(e.nameHe), isTrue,
            reason: '${e.name}: "${e.nameHe}" has no Hebrew letters');
        expect(hebrew.hasMatch(e.primaryMuscleHe), isTrue,
            reason: '${e.name} muscle "${e.primaryMuscleHe}" has no Hebrew');
      }
    });

    test('units are ones the set logger understands', () {
      const units = {'kg', 'bodyweight', 'band', 'min'};
      for (final e in all) {
        expect(units, contains(e.unit),
            reason: '${e.name} uses unit "${e.unit}"');
      }
    });

    test('an unloaded unit never carries a load prescription', () {
      // LoadClass drives the suggested starting weight. Prescribing one for a
      // bodyweight or time-based movement is meaningless at best.
      for (final e in all) {
        if (e.unit == 'kg') continue;
        expect(e.loadClass, LoadClass.none,
            reason: '${e.name} is measured in ${e.unit} but is load-classed '
                '${e.loadClass.name}');
      }
    });
  });

  group('contraindicated and rehab stay distinct', () {
    test('nothing both rehabilitates and endangers the same body part', () {
      // The contradiction that matters: such an exercise would be put into a
      // physiotherapy session for the exact injury it aggravates.
      for (final e in all) {
        final both = e.rehabFor.intersection(e.contraindicatedFor);
        expect(both, isEmpty,
            reason: '${e.name} claims to rehab and to endanger '
                '${both.map((p) => p.name).join(", ")}');
      }
    });

    test('rehab-classed rows prescribe no load and are single-joint', () {
      for (final e in all.where((e) => e.isRehab)) {
        expect(e.loadClass, LoadClass.none, reason: e.name);
        expect(e.mechanic, Mechanic.isolation, reason: e.name);
      }
    });

    test('every rehab-classed row actually rehabilitates something', () {
      for (final e in all.where((e) => e.isRehab)) {
        expect(e.rehabFor, isNotEmpty,
            reason: '${e.name} is filed under Rehab but names no body part');
      }
    });
  });

  group('coverage: what makes the library usable', () {
    test('every body part can fill a physiotherapy session with no equipment',
        () {
      // WorkoutTemplateGenerator takes up to five and skips the session
      // entirely when the pool is empty. An injured user is exactly the user
      // who may own nothing, so bodyweight-only is the case that has to work.
      for (final part in BodyPart.values) {
        for (final entry in kits.entries) {
          final pool = all
              .where((e) =>
                  e.rehabFor.contains(part) && availableWith(e, entry.value))
              .length;
          expect(pool, greaterThanOrEqualTo(5),
              reason: '${part.name} rehab has only $pool options with '
                  '${entry.key}; the generator asks for 5');
        }
      }
    });

    test('every muscle is trainable, including with no equipment', () {
      final muscles = training.map((e) => e.primaryMuscle).toSet();
      for (final muscle in muscles) {
        final total = training.where((e) => e.primaryMuscle == muscle).length;
        expect(total, greaterThanOrEqualTo(3),
            reason: '$muscle has only $total exercises in total');

        for (final entry in kits.entries) {
          final n = training
              .where((e) =>
                  e.primaryMuscle == muscle && availableWith(e, entry.value))
              .length;
          // Two is the honest floor with nothing at all: some muscles (biceps,
          // hamstrings) genuinely have few equipment-free options. Three
          // everywhere else.
          final floor = entry.key == 'bodyweight only' ? 2 : 3;
          expect(n, greaterThanOrEqualTo(floor),
              reason: '$muscle has only $n options with ${entry.key}');
        }
      }
    });

    test('every movement pattern has options to program from', () {
      // A plan covers patterns, not muscle names. `carry` had none at all, so
      // no generated session could ever include one.
      for (final pattern in MovementPattern.values) {
        final n = training.where((e) => e.pattern == pattern).length;
        expect(n, greaterThanOrEqualTo(2),
            reason: '${pattern.name} has only $n exercises');
      }
    });

    test('the big compounds are all present', () {
      const essentials = [
        'Squats',
        'Deadlift',
        'Bench Press',
        'Overhead Press',
        'Pull-ups',
        'Barbell Rows',
        'Push-ups',
        'Bodyweight Squat',
        'Plank',
        'Chin-up',
        'Romanian Deadlift',
        'Hip Thrust',
        'Farmer Carry',
        'Reverse Lunge',
      ];
      final names = all.map((e) => e.name).toSet();
      for (final name in essentials) {
        expect(names, contains(name), reason: '$name is missing');
      }
    });

    test('an injury never silently wipes out a muscle group', () {
      // The failure this prevents: an injury that leaves the generator with
      // nothing to program for a muscle, so the session is quietly short.
      //
      // One exception is real rather than a gap, and is pinned rather than
      // waved through: every way to train the triceps loads the elbow
      // extensors, so an elbow injury correctly leaves no direct triceps
      // work. That user gets the elbow physiotherapy session instead. If any
      // *other* pair ever joins this list it is a coverage hole, and this
      // test will say so by name.
      const clinicallyCorrect = {'elbow/Triceps'};

      final wipedOut = <String>{};
      for (final part in BodyPart.values) {
        final safe =
            training.where((e) => !e.contraindicatedFor.contains(part));
        for (final muscle in training.map((e) => e.primaryMuscle).toSet()) {
          if (safe.every((e) => e.primaryMuscle != muscle)) {
            wipedOut.add('${part.name}/$muscle');
          }
        }
      }
      expect(wipedOut, clinicallyCorrect);
    });
  });

  group('the seeded database matches the library', () {
    late AppDatabase database;

    setUpAll(() => database = AppDatabase());

    test('every row is seeded, with its metadata intact', () async {
      final seeded = {
        for (final e in await database.getAllExercises()) e.id: e
      };
      for (final e in all) {
        final row = seeded[e.id];
        expect(row, isNotNull, reason: '${e.name} was not seeded');
        expect(row!.name, e.name);
        expect(row.nameHe, e.nameHe);
        expect(row.primaryMuscle, e.primaryMuscle);
        expect(row.primaryMuscleHe, e.primaryMuscleHe);
        expect(row.unit, e.unit);
        expect(row.equipment, e.equipment);
        expect(row.contraindicatedFor, e.contraindicatedFor);
        expect(row.rehabFor, e.rehabFor);
        expect(row.movementPattern, e.pattern);
        expect(row.mechanic, e.mechanic);
        expect(row.loadClass, e.loadClass);
      }
    });
  });
}
