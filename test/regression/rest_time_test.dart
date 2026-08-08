@Tags(['workouts'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/features/workouts/domain/rest_time.dart';

/// Rest time had three independent defects before this was centralized:
///
///   1. The rep-based ladder lived on `TemplateExerciseData.restSeconds` and
///      was never called -- the repository mapped the raw nullable field.
///   2. The session page resolved `defaultRestSeconds ?? globalDefault`,
///      skipping the ladder, so an exercise with no explicit rest got a flat
///      90s whether it was a 5-rep squat or a 20-rep lateral raise.
///   3. `SetEntry.restSeconds` was never written by anyone.
///
/// These pin the resolution order so it can't silently collapse back to a
/// single global number.
void main() {
  const globalDefault = 90;

  group('restSecondsForReps ladder', () {
    test('heavy low-rep work rests longest', () {
      expect(restSecondsForReps(1), 180);
      expect(restSecondsForReps(5), 180);
    });

    test('moderate rep ranges step down', () {
      expect(restSecondsForReps(6), 120);
      expect(restSecondsForReps(8), 120);
      expect(restSecondsForReps(9), 90);
      expect(restSecondsForReps(12), 90);
    });

    test('high-rep metabolic work rests shortest', () {
      expect(restSecondsForReps(13), 60);
      expect(restSecondsForReps(30), 60);
    });
  });

  group('resolveRestSeconds precedence', () {
    test('an explicit per-exercise value wins over everything', () {
      expect(
        resolveRestSeconds(
          explicitSeconds: 45,
          reps: 5, // ladder would say 180
          globalDefaultSeconds: globalDefault,
        ),
        45,
      );
    });

    test('falls to the rep ladder when no explicit value is set', () {
      // The exact case defect #2 got wrong: this must be 180, not the 90s
      // global default.
      expect(
        resolveRestSeconds(reps: 5, globalDefaultSeconds: globalDefault),
        180,
      );
      expect(
        resolveRestSeconds(reps: 20, globalDefaultSeconds: globalDefault),
        60,
      );
    });

    test('falls to the global default only when there is no rep count', () {
      expect(resolveRestSeconds(globalDefaultSeconds: globalDefault), 90);
      expect(
        resolveRestSeconds(globalDefaultSeconds: 120),
        120,
      );
    });

    test('null explicit means unset, not zero', () {
      expect(
        resolveRestSeconds(
          explicitSeconds: null,
          reps: 5,
          globalDefaultSeconds: globalDefault,
        ),
        180,
      );
    });

    test('a non-positive explicit value is treated as unset', () {
      // Guards a template row that stored 0 from an empty text field.
      expect(
        resolveRestSeconds(
          explicitSeconds: 0,
          reps: 5,
          globalDefaultSeconds: globalDefault,
        ),
        180,
      );
    });

    test('a non-positive rep count does not trigger the ladder', () {
      expect(
        resolveRestSeconds(reps: 0, globalDefaultSeconds: globalDefault),
        globalDefault,
      );
    });
  });

  group('formatRest', () {
    test('renders minutes and zero-padded seconds', () {
      expect(formatRest(60), '1:00');
      expect(formatRest(90), '1:30');
      expect(formatRest(180), '3:00');
      expect(formatRest(45), '0:45');
      expect(formatRest(125), '2:05');
    });
  });

  test('every preset is renderable and on the ladder scale', () {
    expect(restPresets, isNotEmpty);
    for (final preset in restPresets) {
      expect(preset, greaterThan(0));
      expect(formatRest(preset), matches(RegExp(r'^\d+:\d{2}$')));
    }
  });
}
