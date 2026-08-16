@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/widgets.dart';
import 'package:wellness_app/features/settings/ui/advanced_color_picker.dart';
import 'package:wellness_app/features/settings/ui/widgets/settings_row.dart';
import 'package:flutter/cupertino.dart';

/// Widget-level interaction tests: tap a widget in isolation, assert its
/// callback fired with the right value. Previously the suite jumped straight
/// from pure unit tests to full-app `integration_test/sanity` smoke tests
/// that only check "does this screen render" -- nothing exercised a single
/// widget's tap/drag behavior on its own, so a callback wired to the wrong
/// value (right widget, wrong handler) could slip through both tiers.
void main() {
  group('AppButton', () {
    testWidgets('tap invokes onPressed', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppButton(text: 'Save', onPressed: () => tapped = true),
        ),
      ));

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('tap does nothing while isLoading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: 'Save',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      ));

      // Tap the button itself rather than its label: the label shares the row
      // with a spinner while loading, and the tap target is the whole pane.
      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(tapped, isFalse,
          reason: 'a loading button must not fire its callback -- it should '
              'read as disabled, not just visually busy');
    });
  });

  group('SettingsRow', () {
    testWidgets('tap invokes onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SettingsRow(
            icon: Icons.settings,
            iconColor: Colors.blue,
            title: 'Notifications',
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.text('Notifications'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('SettingsSwitch', () {
    testWidgets('tap invokes onChanged with the flipped value', (tester) async {
      bool? newValue;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SettingsSwitch(
            icon: Icons.notifications,
            iconColor: Colors.orange,
            title: 'Meal Reminders',
            value: false,
            onChanged: (v) => newValue = v,
          ),
        ),
      ));

      await tester.tap(find.byType(CupertinoSwitch));
      await tester.pump();

      expect(newValue, isTrue);
    });
  });

  group('HuePicker', () {
    testWidgets('tap reports the hue at that position', (tester) async {
      double? reportedHue;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: HuePicker(hue: 0, onChanged: (h) => reportedHue = h),
            ),
          ),
        ),
      ));

      // Tapping the left edge should report a hue near 0.
      await tester.tapAt(
          tester.getTopLeft(find.byType(HuePicker)) + const Offset(2, 20));
      await tester.pump();

      expect(reportedHue, isNotNull);
      expect(reportedHue, lessThan(20));
    });
  });

  group('SaturationBrightnessPicker', () {
    testWidgets('tap reports saturation/value near the tap position',
        (tester) async {
      double? reportedSat;
      double? reportedVal;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: SaturationBrightnessPicker(
                hue: 200,
                saturation: 0,
                value: 1,
                onChanged: (s, v) {
                  reportedSat = s;
                  reportedVal = v;
                },
              ),
            ),
          ),
        ),
      ));

      final topLeft =
          tester.getTopLeft(find.byType(SaturationBrightnessPicker));
      // Top-left of the square is max brightness, zero saturation.
      await tester.tapAt(topLeft + const Offset(2, 2));
      await tester.pump();

      expect(reportedSat, isNotNull);
      expect(reportedSat, lessThan(0.1));
      expect(reportedVal, greaterThan(0.9));
    });
  });
}
