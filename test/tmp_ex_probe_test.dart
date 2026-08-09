import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/data/db/drift_database.dart';
import 'package:wellness_app/features/workouts/domain/exercise_tags.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('probe', () async {
    final db = AppDatabase();
    final all = await db.getAllExercises();
    debugPrint('TOTAL ${all.length}');

    const kits = {
      'bodyweight only': {Equipment.bodyweight},
      'bands only': {Equipment.bodyweight, Equipment.bands},
      'dumbbells': {Equipment.bodyweight, Equipment.dumbbells},
      'full gym': {
        Equipment.bodyweight, Equipment.dumbbells, Equipment.barbellRack,
        Equipment.machines, Equipment.bands, Equipment.kettlebells,
        Equipment.cable, Equipment.pullupBar,
      },
    };

    debugPrint('\nREHAB POOL per body part (generator takes up to 5):');
    debugPrint('${'body part'.padRight(12)}${kits.keys.map((k) => k.padLeft(17)).join()}');
    for (final part in BodyPart.values) {
      final row = StringBuffer(part.name.padRight(12));
      for (final kit in kits.values) {
        final n = all.where((e) =>
            e.rehabFor.contains(part) &&
            (e.equipment.isEmpty || e.equipment.any(kit.contains))).length;
        row.write(('$n${n < 4 ? "  <<" : ""}').padLeft(17));
      }
      debugPrint(row.toString());
    }

    debugPrint('\nTRAINING POOL per muscle (non-rehab):');
    final train = all.where((e) => e.primaryMuscle != 'Rehab').toList();
    final muscles = train.map((e) => e.primaryMuscle).whereType<String>().toSet().toList()..sort();
    for (final m in muscles) {
      final row = StringBuffer(m.padRight(12));
      for (final kit in kits.values) {
        final n = train.where((e) =>
            e.primaryMuscle == m &&
            (e.equipment.isEmpty || e.equipment.any(kit.contains))).length;
        row.write(('$n${n < 3 ? "  <<" : ""}').padLeft(17));
      }
      debugPrint(row.toString());
    }

    debugPrint('\nMOVEMENT PATTERN coverage (non-rehab):');
    for (final p in MovementPattern.values) {
      final n = train.where((e) => e.movementPattern == p).length;
      debugPrint('  ${p.name.padRight(16)} $n${n == 0 ? "   <<< NONE" : ""}');
    }
  });
}
