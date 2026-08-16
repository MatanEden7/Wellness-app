@Tags(['persistence', 'workouts'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/workouts/data/repositories.dart';
import 'package:wellness_app/features/workouts/domain/models.dart';

/// Per-exercise rest: the fallback rule, and the two seams that would drop it.
///
/// Rest is not cosmetic. It is most of the difference between a session that
/// fits in 45 minutes and one that runs to 75, and between how a heavy
/// compound and a cable curl should be run. The app previously applied a
/// single global 90s preference to every exercise alike.
///
/// The seams matter more than the field. `updateTemplate` implements an edit
/// by deleting every child row and re-inserting it **from the domain model**,
/// so a field carried on the row but not the model is silently wiped by any
/// edit -- the exact shape of ISSUES #64, where editing anything dropped
/// `sourceEventId`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    AppDatabase.resetForTesting();
    database = AppDatabase();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() => container.dispose());

  TemplateExerciseData row({int? reps, int? rest}) => TemplateExerciseData(
        id: 'te',
        templateId: 't',
        exerciseId: 'e',
        orderIndex: 0,
        defaultSets: 3,
        defaultReps: reps,
        defaultRestSeconds: rest,
      );

  group('the fallback when no rest is prescribed', () {
    test('an explicit value always wins', () {
      expect(row(reps: 10, rest: 42).restSeconds, 42);
    });

    test('heavier rep ranges get longer rest', () {
      // Monotonic: fewer reps means heavier work means more recovery. The
      // exact numbers matter less than the ordering never inverting.
      final five = row(reps: 5).restSeconds;
      final eight = row(reps: 8).restSeconds;
      final twelve = row(reps: 12).restSeconds;
      final twenty = row(reps: 20).restSeconds;

      expect(five, greaterThan(eight));
      expect(eight, greaterThan(twelve));
      expect(twelve, greaterThan(twenty));
    });

    test('a row with no reps at all still yields a usable rest', () {
      expect(row().restSeconds, greaterThan(0),
          reason: 'the rest timer would be handed null and the session would '
              'have no recovery period at all');
    });
  });

  group('the field survives the seams', () {
    test('a JSON round trip keeps it', () {
      final restored = TemplateExerciseData.fromJson(
          jsonDecode(jsonEncode(row(reps: 8, rest: 150).toJson())));

      expect(restored.defaultRestSeconds, 150);
    });

    test('a row written before the field existed decodes to null', () {
      final restored = TemplateExerciseData.fromJson({
        'id': 'te',
        'templateId': 't',
        'exerciseId': 'e',
        'orderIndex': 0,
        'defaultSets': 3,
        'defaultReps': 8,
      });

      expect(restored.defaultRestSeconds, isNull);
      expect(restored.restSeconds, 120,
          reason: 'and still produces the rest an 8-rep set deserves');
    });

    test('editing a template does not wipe the prescribed rest', () async {
      // The regression this file exists for. updateTemplate deletes every
      // child and rebuilds it from the domain model.
      final repo = container.read(workoutTemplatesRepositoryProvider);
      final exercise = (await database.getAllExercises()).first;

      await repo
          .createTemplate(WorkoutTemplate(id: 't', name: 'v1', exercises: [
        TemplateExercise(
            id: 'te',
            templateId: 't',
            exerciseId: exercise.id,
            orderIndex: 0,
            defaultSets: 4,
            defaultReps: 8,
            defaultRestSeconds: 150),
      ]));

      expect(
          (await database.getTemplateExercisesByTemplateId('t'))
              .single
              .defaultRestSeconds,
          150,
          reason: 'lost on the way in');

      // Read it back through the repository and save it again unchanged --
      // exactly what the template editor does when the user renames a
      // template and taps save.
      final loaded = await repo.getTemplateById('t');
      await repo.updateTemplate(loaded!.copyWith(name: 'v2'));

      expect(
          (await database.getTemplateExercisesByTemplateId('t'))
              .single
              .defaultRestSeconds,
          150,
          reason: 'renaming a template reset every rest interval in it');
    });

    test('it survives a snapshot restart', () async {
      final store = _MemStore();
      AppDatabase.resetForTesting();
      final db = AppDatabase(store: store);
      await db.insertTemplateExercise(TemplateExerciseData(
          id: 'te',
          templateId: 't',
          exerciseId: 'e',
          orderIndex: 0,
          defaultSets: 3,
          defaultReps: 8,
          defaultRestSeconds: 150));
      await db.flush();

      AppDatabase.resetForTesting();
      final reloaded = AppDatabase(store: store);
      await reloaded.load();

      expect(
          (await reloaded.getTemplateExercisesByTemplateId('t'))
              .single
              .defaultRestSeconds,
          150);
    });
  });
}

class _MemStore implements SnapshotStore {
  String? contents;

  @override
  Future<String?> read() async => contents;

  @override
  Future<void> write(String c) async => contents = c;
}
