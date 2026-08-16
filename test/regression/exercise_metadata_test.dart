@Tags(['catalog', 'persistence'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/workouts/domain/exercise_tags.dart';

/// The movement/mechanic/load metadata that programming is built on, and the
/// backfill that keeps it working for users upgrading from a snapshot written
/// before it existed.
///
/// The backfill is the risky half. `_applySnapshot` **replaces** the exercise
/// list rather than merging it, so without repair an upgrading user keeps 58
/// untagged exercises forever and the generator has nothing to program from --
/// it would produce empty sessions in silence, the same shape as a reset
/// leaving an empty food catalog. It also has to repair *without* trampling a
/// user's own edits or resurrecting something they deleted, which is the
/// contract `persistence_test` already pins for starter foods.
class _MemStore implements SnapshotStore {
  _MemStore([this.contents]);
  String? contents;

  @override
  Future<String?> read() async => contents;

  @override
  Future<void> write(String c) async => contents = c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the seeded library is fully tagged', () {
    late List<ExerciseData> seeded;

    setUp(() {
      AppDatabase.resetForTesting();
      seeded = AppDatabase().debugSeededExercises;
    });

    test('every exercise carries all three tags', () {
      for (final exercise in seeded) {
        expect(exercise.movementPattern, isNotNull,
            reason: '"${exercise.name}" has no movement pattern, so it can '
                'only ever be picked as filler');
        expect(exercise.mechanic, isNotNull, reason: exercise.name);
        expect(exercise.loadClass, isNotNull, reason: exercise.name);
      }
    });

    test('a load is only ever prescribed for kg-based exercises', () {
      // The safety invariant. A band, bodyweight or time-based movement has
      // no barbell load to give, and inventing one is how a generator hurts
      // somebody.
      for (final exercise in seeded) {
        if (exercise.loadClassOrDefault == LoadClass.none) continue;
        expect(exercise.unit, 'kg',
            reason: '"${exercise.name}" is unit "${exercise.unit}" but would '
                'be given a prescribed weight');
      }
    });

    test('there are enough compounds to open every session', () {
      final compounds =
          seeded.where((e) => e.mechanicOrDefault == Mechanic.compound);
      expect(compounds.length, greaterThan(15),
          reason: 'sessions open with a compound; too few and the same one '
              'appears in every workout of the week');
    });

    test('every non-rehab pattern has at least one exercise', () {
      final present = seeded
          .where((e) => e.primaryMuscle != 'Rehab')
          .map((e) => e.pattern)
          .toSet();

      // Carry is deliberately absent from the seed catalog for now; the rest
      // are what a balanced week has to be built from.
      for (final required in [
        MovementPattern.squat,
        MovementPattern.hinge,
        MovementPattern.lunge,
        MovementPattern.horizontalPush,
        MovementPattern.verticalPush,
        MovementPattern.horizontalPull,
        MovementPattern.verticalPull,
        MovementPattern.coreBrace,
      ]) {
        expect(present, contains(required),
            reason: 'no ${required.name} exercise exists, so no plan can '
                'cover that pattern');
      }
    });
  });

  group('backfilling a snapshot written before the tags existed', () {
    /// A snapshot of the current catalog with the three tag fields stripped,
    /// exactly as an older build would have written it.
    Future<String> untaggedSnapshot() async {
      AppDatabase.resetForTesting();
      final store = _MemStore();
      final db = AppDatabase(store: store);
      await db.flush();

      final json = jsonDecode(store.contents!) as Map<String, dynamic>;
      for (final row
          in (json['exercises'] as List).cast<Map<String, dynamic>>()) {
        row.remove('movementPattern');
        row.remove('mechanic');
        row.remove('loadClass');
      }
      return jsonEncode(json);
    }

    test('an untagged snapshot loads and comes back fully tagged', () async {
      final store = _MemStore(await untaggedSnapshot());

      AppDatabase.resetForTesting();
      final db = AppDatabase(store: store);
      await db.load();

      final restored = await db.getAllExercises();
      expect(restored, isNotEmpty);
      for (final exercise in restored) {
        expect(exercise.movementPattern, isNotNull,
            reason: '"${exercise.name}" stayed untagged after restore, so the '
                'generator would treat it as filler forever');
        expect(exercise.loadClass, isNotNull, reason: exercise.name);
      }
    });

    test('an exercise the user edited keeps their edit', () async {
      final store = _MemStore(await untaggedSnapshot());

      AppDatabase.resetForTesting();
      final db = AppDatabase(store: store);
      await db.load();

      // Rename a seeded exercise, save, reload.
      final original = (await db.getAllExercises()).first;
      await db.updateExercise(ExerciseData(
        id: original.id,
        name: 'My renamed lift',
        unit: original.unit,
        primaryMuscle: original.primaryMuscle,
        equipment: original.equipment,
      ));
      await db.flush();

      AppDatabase.resetForTesting();
      final reloaded = AppDatabase(store: store);
      await reloaded.load();

      final after = await reloaded.getExerciseById(original.id);
      expect(after?.name, 'My renamed lift',
          reason: 'the backfill overwrote a user edit; it must only fill '
              'fields that are null');
      expect(after?.movementPattern, isNotNull,
          reason: 'and it should still have gained its metadata');
    });

    test('an exercise the user deleted stays deleted', () async {
      final store = _MemStore(await untaggedSnapshot());

      AppDatabase.resetForTesting();
      final db = AppDatabase(store: store);
      await db.load();

      final doomed = (await db.getAllExercises()).first.id;
      await db.deleteExercise(doomed);
      await db.flush();

      AppDatabase.resetForTesting();
      final reloaded = AppDatabase(store: store);
      await reloaded.load();

      expect(await reloaded.getExerciseById(doomed), isNull,
          reason: 'the backfill walks the restored list, never the seed, so '
              'it cannot resurrect a deleted row');
    });

    test('a user-created exercise is left entirely alone', () async {
      AppDatabase.resetForTesting();
      final store = _MemStore();
      final db = AppDatabase(store: store);
      await db.insertExercise(
          ExerciseData(id: 'mine', name: 'Sandbag carry', unit: 'kg'));
      await db.flush();

      AppDatabase.resetForTesting();
      final reloaded = AppDatabase(store: store);
      await reloaded.load();

      final mine = await reloaded.getExerciseById('mine');
      expect(mine, isNotNull);
      expect(mine!.movementPattern, isNull,
          reason: 'there is no seed row to backfill from, and guessing would '
              'be worse than the safe fallbacks');
      // Reading it is still safe -- that is what the fallbacks are for.
      expect(mine.pattern, MovementPattern.isolation);
      expect(mine.loadClassOrDefault, LoadClass.none);
    });
  });

  group('serialization', () {
    test('the tags survive a JSON round trip', () {
      final original = ExerciseData(
        id: 'x',
        name: 'Probe',
        unit: 'kg',
        movementPattern: MovementPattern.hinge,
        mechanic: Mechanic.compound,
        loadClass: LoadClass.deadliftPattern,
      );

      final restored =
          ExerciseData.fromJson(jsonDecode(jsonEncode(original.toJson())));

      expect(restored.movementPattern, MovementPattern.hinge);
      expect(restored.mechanic, Mechanic.compound);
      expect(restored.loadClass, LoadClass.deadliftPattern);
    });

    test('unknown or malformed tag values decode to null, never throw', () {
      // A payload from a future build with a pattern this one has never heard
      // of must not take the whole import down.
      final restored = ExerciseData.fromJson({
        'id': 'x',
        'name': 'Probe',
        'unit': 'kg',
        'movementPattern': 'jetpack',
        'mechanic': 42,
        'loadClass': <String>[],
      });

      expect(restored.movementPattern, isNull);
      expect(restored.mechanic, isNull);
      expect(restored.loadClass, isNull);
      expect(restored.loadClassOrDefault, LoadClass.none);
    });
  });
}
