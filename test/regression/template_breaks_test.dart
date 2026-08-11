import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/workouts/domain/models.dart';

/// Breaks in a workout template.
///
/// A break is an ordinary row in the same ordered list as the exercises --
/// that is what lets it sit anywhere between them and be dragged like one --
/// distinguished only by `isRest`. Everything that walks a template's rows
/// therefore has to know the difference, and everything that persists them has
/// to carry the flag. These pin both.
void main() {
  setUp(AppDatabase.resetForTesting);

  WorkoutTemplate templateWithBreak() {
    final template = WorkoutTemplate.create(name: 'Upper Body');
    return template.copyWith(
      customRest: true,
      exercises: [
        TemplateExercise.create(
          templateId: template.id,
          exerciseId: 'bench',
          orderIndex: 0,
          defaultSets: 3,
          defaultReps: 10,
        ),
        TemplateExercise.rest(
          templateId: template.id,
          orderIndex: 1,
          seconds: 150,
        ),
        TemplateExercise.create(
          templateId: template.id,
          exerciseId: 'rows',
          orderIndex: 2,
          defaultSets: 3,
          defaultReps: 10,
        ),
      ],
    );
  }

  test('a break survives a save and reload, in its place in the order',
      () async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase();

    final template = templateWithBreak();
    // Written through the same row mapping the repository uses.
    await database.insertWorkoutTemplate(WorkoutTemplateData(
      id: template.id,
      name: template.name,
      customRest: template.customRest,
    ));
    for (final item in template.exercises) {
      await database.insertTemplateExercise(TemplateExerciseData(
        id: item.id,
        templateId: template.id,
        exerciseId: item.exerciseId,
        orderIndex: item.orderIndex,
        defaultSets: item.defaultSets,
        defaultReps: item.defaultReps,
        defaultRestSeconds: item.defaultRestSeconds,
        isRest: item.isRest,
      ));
    }

    final reloaded = await database.getWorkoutTemplateById(template.id);
    final rows = await database.getTemplateExercisesByTemplateId(template.id);

    expect(reloaded!.customRest, isTrue);
    expect(rows.length, 3);
    // Position matters: a break belongs *between* two exercises, and losing
    // its index would silently move it to the end.
    expect(rows[1].isRest, isTrue, reason: 'the break is the middle row');
    expect(rows[1].defaultRestSeconds, 150);
    expect(rows[0].isRest, isFalse);
    expect(rows[2].isRest, isFalse);
  });

  test('a break round-trips through JSON, and old rows read back as exercises',
      () {
    final row = TemplateExerciseData(
      id: 'r1',
      templateId: 't1',
      exerciseId: '',
      orderIndex: 1,
      defaultSets: 0,
      defaultRestSeconds: 150,
      isRest: true,
    );

    final restored = TemplateExerciseData.fromJson(row.toJson());
    expect(restored.isRest, isTrue);
    expect(restored.defaultRestSeconds, 150);

    // Backups written before breaks existed have no `isRest` key at all; they
    // are all exercises, and must not come back as zero-length breaks.
    final legacy = TemplateExerciseData.fromJson({
      'id': 'r0',
      'templateId': 't1',
      'exerciseId': 'bench',
      'orderIndex': 0,
      'defaultSets': 3,
      'defaultReps': 10,
    });
    expect(legacy.isRest, isFalse);

    final legacyTemplate = WorkoutTemplateData.fromJson({
      'id': 't1',
      'name': 'Old Template',
    });
    expect(legacyTemplate.customRest, isFalse,
        reason: 'templates predating this feature keep automatic rest');
  });

  test('a break carries a duration even when none was stored', () {
    const bare = TemplateExercise(
      id: 'r1',
      templateId: 't1',
      exerciseId: '',
      orderIndex: 0,
      isRest: true,
    );
    // Not zero: a break with no length is a break the session would blink
    // straight past.
    expect(bare.restDuration, greaterThan(0));
  });
}
