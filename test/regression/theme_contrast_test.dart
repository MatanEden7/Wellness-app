@Tags(['ui'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/contrast.dart';
import 'package:wellness_app/core/theme.dart';

/// The Appearance & Colors picker already warns on low contrast for
/// *user-chosen* colors -- this audits the *fixed* palette (the built-in
/// themes nobody customizes) against the same WCAG AA bar (4.5:1), since
/// low-contrast complaints usually come from defaults, not from something a
/// user picked. `AppThemeKind.custom` is excluded: its contrast is already
/// covered live by the picker's own indicator, and depends on user input.
void main() {
  const aaBar = 4.5;

  for (final kind in AppThemeKind.values) {
    if (kind == AppThemeKind.custom) continue;

    test('$kind: onSurface readable on surface', () {
      final scheme = AppTheme.byKind(kind).colorScheme;
      final ratio = contrastRatio(scheme.onSurface, scheme.surface);
      expect(ratio, greaterThanOrEqualTo(aaBar),
          reason: '$kind onSurface/surface contrast is only '
              '${ratio.toStringAsFixed(2)}:1');
    });

    test('$kind: onSurface readable on the scaffold background', () {
      final theme = AppTheme.byKind(kind);
      final ratio =
          contrastRatio(theme.colorScheme.onSurface, theme.scaffoldBackgroundColor);
      expect(ratio, greaterThanOrEqualTo(aaBar),
          reason: '$kind onSurface/scaffoldBackgroundColor contrast is only '
              '${ratio.toStringAsFixed(2)}:1');
    });

    test('$kind: onPrimary readable on primary', () {
      final scheme = AppTheme.byKind(kind).colorScheme;
      final ratio = contrastRatio(scheme.onPrimary, scheme.primary);
      expect(ratio, greaterThanOrEqualTo(aaBar),
          reason: '$kind onPrimary/primary contrast is only '
              '${ratio.toStringAsFixed(2)}:1');
    });
  }
}
