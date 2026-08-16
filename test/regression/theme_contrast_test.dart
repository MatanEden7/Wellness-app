@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/contrast.dart';
import 'package:wellness_app/core/ios/glass.dart';
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
      final ratio = contrastRatio(
          theme.colorScheme.onSurface, theme.scaffoldBackgroundColor);
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

    // A surface can only *look* like a surface if it separates from the page
    // behind it. This is the assertion the old palettes would have failed:
    // light/forest/sunset sat at ~1.05:1 background-to-surface, and dark and
    // gold were byte-identical pairs. Below about 1.10 a card reads as an
    // outline drawn on the page rather than as something resting on it, and a
    // translucent pane reads as nothing at all.
    test('$kind: the surface separates from the background', () {
      final theme = AppTheme.byKind(kind);
      final ratio = contrastRatio(
        theme.colorScheme.surface,
        theme.scaffoldBackgroundColor,
      );
      expect(ratio, greaterThanOrEqualTo(1.10),
          reason: '$kind surface/background separation is only '
              '${ratio.toStringAsFixed(3)}:1 — a card will not read as a '
              'surface');
    });

    test('$kind: the elevated step separates from the surface', () {
      final scheme = AppTheme.byKind(kind).colorScheme;
      final ratio =
          contrastRatio(scheme.surfaceContainerHighest, scheme.surface);
      expect(ratio, greaterThanOrEqualTo(1.05),
          reason: '$kind has no third step: a card inside a card, and the '
              'glass tint that derives from it, have nowhere to go');
    });

    test('$kind: the hairline is structure, not body text', () {
      final scheme = AppTheme.byKind(kind).colorScheme;
      // `outline` falling back to `onSurface` is what made three themes draw
      // their separators in 87% white.
      expect(scheme.outline, isNot(equals(scheme.onSurface)),
          reason: '$kind outline is the body colour — every hairline in the '
              'app will be drawn at full text weight');
      final ratio = contrastRatio(scheme.outline, scheme.surface);
      expect(ratio, lessThan(4.5),
          reason:
              '$kind outline contrasts like text (${ratio.toStringAsFixed(2)}'
              ':1) — a separator that loud competes with the content');
    });

    test('$kind: the three accents are actually three', () {
      final scheme = AppTheme.byKind(kind).colorScheme;
      expect({scheme.primary, scheme.secondary, scheme.tertiary}, hasLength(3),
          reason: '$kind repeats an accent, so nothing can be ranked against '
              'anything else');
    });

    // Glass is translucent, so a card's real background is its tint composited
    // over whatever is behind it. This is what pins the tint alphas in
    // `GlassSpec.resolve`: if a level fails here, that level's alpha goes up.
    // The alpha is not free to be as low as it looks good at.
    for (final level in GlassLevel.values) {
      test('$kind: onSurface readable through $level glass', () {
        final theme = AppTheme.byKind(kind);
        final spec = GlassSpec.resolve(level);
        final composited =
            spec.composite(theme.colorScheme, theme.scaffoldBackgroundColor);
        final ratio = contrastRatio(theme.colorScheme.onSurface, composited);
        expect(ratio, greaterThanOrEqualTo(aaBar),
            reason: '$kind onSurface over $level glass is only '
                '${ratio.toStringAsFixed(2)}:1');
      });
    }

    // A prominent button is the accent colour at `prominentTintAlpha` over
    // whatever is behind it, labelled `onPrimary`. The existing onPrimary/
    // primary check does not cover that: the fill is not `primary`, it is
    // primary *diluted towards the page*, and dilution is exactly what eats
    // the contrast. This is what pins `prominentTintAlpha`.
    for (final level in GlassLevel.values) {
      test('$kind: a prominent $level button is legible', () {
        final theme = AppTheme.byKind(kind);
        final spec = GlassSpec.resolve(level);
        final fill = Color.alphaBlend(
          spec.prominentTint(theme.colorScheme),
          theme.scaffoldBackgroundColor,
        );
        final ratio = contrastRatio(theme.colorScheme.onPrimary, fill);
        expect(ratio, greaterThanOrEqualTo(aaBar),
            reason: '$kind onPrimary on a $level prominent button is only '
                '${ratio.toStringAsFixed(2)}:1');
      });
    }

    // The other backdrop a glass surface can sit on: the page wash, which is
    // the theme's primary and tertiary blended into the scaffold colour. A
    // card floating over the *coloured* part of the gradient is the worst
    // case for legibility, and it is not covered by the check above.
    test('$kind: onSurface readable through full glass over the page wash', () {
      final theme = AppTheme.byKind(kind);
      final spec = GlassSpec.resolve(GlassLevel.full);
      for (final accent in [
        theme.colorScheme.primary,
        theme.colorScheme.tertiary,
      ]) {
        // Matches GlassBackdrop's strongest stop.
        final wash = Color.alphaBlend(
          accent.withValues(alpha: 0.20),
          theme.scaffoldBackgroundColor,
        );
        final ratio = contrastRatio(
          theme.colorScheme.onSurface,
          spec.composite(theme.colorScheme, wash),
        );
        expect(ratio, greaterThanOrEqualTo(aaBar),
            reason: '$kind onSurface over glass over the $accent wash is only '
                '${ratio.toStringAsFixed(2)}:1');
      }
    });
  }
}
