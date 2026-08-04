@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/features/settings/ui/advanced_color_picker.dart';

/// Regression coverage for the hue-slider bug in ISSUES.md #32: `CustomPaint`
/// with no `child` and no explicit `size` collapsed to `Size.zero` when its
/// parent only constrained height, so the rainbow track never rendered and
/// only the thumb (painted past the zero-width box) was visible. A plain
/// `flutter analyze` + the fast unit suite both stayed green through that --
/// only a manual screenshot caught it. These tests assert the painted area is
/// actually non-zero, which would have failed on the original code, plus a
/// golden snapshot so a future layout regression fails CI instead of
/// shipping.
///
/// The rest-timer "progress ring" proposed alongside these two in
/// PRODUCT_PLAN.md C4 turned out, on inspection, to be a `FractionallySizedBox`
/// progress bar (`workout_session_page.dart`'s `_RestTimerCard`), not a
/// `CustomPainter` -- there's no equivalent zero-size risk there, so it's
/// excluded here.
void main() {
  testWidgets('HuePicker paints a non-zero-size track', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: HuePicker(hue: 120, onChanged: (_) {}),
            ),
          ),
        ),
      ),
    );

    final paintFinder = find.descendant(
        of: find.byType(HuePicker), matching: find.byType(CustomPaint));
    final customPaint = tester.widget<CustomPaint>(paintFinder);
    final renderBox = tester.renderObject<RenderBox>(paintFinder);
    expect(renderBox.size.width, greaterThan(0),
        reason: 'the rainbow track collapsed to zero width, as it did before '
            'the SizedBox.expand fix');
    expect(renderBox.size.height, greaterThan(0));
    expect(customPaint.painter, isNotNull);

    await expectLater(
      find.byType(HuePicker),
      matchesGoldenFile('goldens/hue_picker.png'),
    );
  });

  testWidgets('SaturationBrightnessPicker paints a non-zero-size square',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: SaturationBrightnessPicker(
                hue: 200,
                saturation: 0.6,
                value: 0.8,
                onChanged: (_, __) {},
              ),
            ),
          ),
        ),
      ),
    );

    final renderBox = tester.renderObject<RenderBox>(find.descendant(
        of: find.byType(SaturationBrightnessPicker),
        matching: find.byType(CustomPaint)));
    expect(renderBox.size.width, greaterThan(0));
    expect(renderBox.size.height, greaterThan(0));

    await expectLater(
      find.byType(SaturationBrightnessPicker),
      matchesGoldenFile('goldens/saturation_brightness_picker.png'),
    );
  });
}
