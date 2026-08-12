/// The design system, in one file.
///
/// Everything visual in this app resolves to a value defined here: type sizes,
/// spacing, corner radii, control heights. It exists because an audit found the
/// alternative — two competing spacing scales, 18 font sizes, 13 corner radii
/// and six tap heights — which is what made the interface read as unfinished
/// however good any individual screen was.
///
/// The values are Apple's, not invented: the iOS type ramp, the 44pt tap
/// target, the concentricity rule from the iOS 26 design system. Where a number
/// is a judgement call rather than a spec, the comment says so.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

// ─── Type ────────────────────────────────────────────────────────────────────

/// The iOS type ramp, mapped onto Material's `TextTheme` slots.
///
/// The mapping matters more than it looks. Feature code writes
/// `theme.textTheme.bodyLarge` and should simply *get* iOS Body — so the ramp
/// is expressed as a `TextTheme` rather than as a set of constants nobody
/// remembers to use. The previous theme had no 17pt slot at all, which is why
/// 20 call sites wrote `fontSize: 17` by hand: the system had no way to say the
/// most common size in an iOS app.
abstract final class AppType {
  /// Large Title — the collapsing screen title.
  static const double largeTitle = 34;

  /// Title 1 / 2 / 3.
  static const double title1 = 28;
  static const double title2 = 22;
  static const double title3 = 20;

  /// Headline: body size, semibold. Row titles, card titles.
  static const double headline = 17;

  /// Body: the default reading size on iOS.
  static const double body = 17;

  /// Callout, Subheadline, Footnote, Caption.
  static const double callout = 16;
  static const double subheadline = 15;
  static const double footnote = 13;
  static const double caption = 12;

  /// Built once and tinted per theme. `onSurface` carries the body colour and
  /// `muted` the secondary one, so a theme supplies two colours rather than
  /// repeating a ten-slot block — which is how the old file ended up with nine
  /// near-identical copies and one theme (`custom`) with none at all.
  static TextTheme ramp({required Color onSurface, required Color muted}) {
    TextStyle s(double size, FontWeight weight, Color color) => TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: color,
          // -0.4 at Large Title tightening to 0 at caption is roughly SF's own
          // optical tracking; without it large text reads loose against SF.
          letterSpacing: size >= title2 ? -0.4 : 0,
        );

    return TextTheme(
      displayLarge: s(largeTitle, FontWeight.w700, onSurface),
      headlineLarge: s(title1, FontWeight.w700, onSurface),
      headlineMedium: s(title2, FontWeight.w600, onSurface),
      headlineSmall: s(title3, FontWeight.w600, onSurface),
      // Headline and Body are the same size and differ only in weight, which
      // is exactly how iOS distinguishes a row's title from its content.
      titleLarge: s(title3, FontWeight.w600, onSurface),
      titleMedium: s(headline, FontWeight.w600, onSurface),
      titleSmall: s(subheadline, FontWeight.w600, onSurface),
      bodyLarge: s(body, FontWeight.w400, onSurface),
      bodyMedium: s(callout, FontWeight.w400, onSurface),
      bodySmall: s(footnote, FontWeight.w400, muted),
      labelLarge: s(headline, FontWeight.w600, onSurface),
      labelMedium: s(subheadline, FontWeight.w500, muted),
      labelSmall: s(caption, FontWeight.w400, muted),
    );
  }
}

// ─── Spacing ─────────────────────────────────────────────────────────────────

/// One 4pt grid. There is no second scale.
///
/// The audit found `AppSpacing` (4/8/16/24) and `UIConstants` (12/18/20/24)
/// both live, disagreeing about screen padding, with 86% of paddings written as
/// raw literals anyway — and the single most common pair in the app,
/// `horizontal: 14, vertical: 7`, belonging to neither.
abstract final class Space {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Screen gutter. 20 is iOS's, and it is what the app's own
  /// `screenHorizontalPadding` already used — the Material 16 was the outlier.
  static const double screen = xl;

  /// Inside a card, and between cards.
  static const double card = lg;
  static const double cardGap = md;

  /// Between one section of a screen and the next.
  static const double section = xxl;
}

// ─── Radii ───────────────────────────────────────────────────────────────────

/// Corner radii, and the rule that relates them.
abstract final class Radii {
  static const double sheet = 24;
  static const double card = 16;
  static const double control = 12;
  static const double field = 10;

  /// A capsule: radius is half the height. Apple's shape for large controls,
  /// and the one that stays concentric at any size for free.
  static double capsule(double height) => height / 2;

  /// Apple's concentricity rule: a child nested inside a rounded parent takes
  /// the parent's radius minus the padding between them, so the two curves
  /// share a centre. Without it the child's corner is either pinched or flared
  /// against its parent's, which is the visual tension the rule exists to stop.
  ///
  /// Floored at 4 rather than 0: a fully square child inside a rounded parent
  /// reads as a rendering mistake.
  static double inner(double parentRadius, double padding) =>
      math.max(4, parentRadius - padding);

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

// ─── Sizes ───────────────────────────────────────────────────────────────────

/// Control metrics. The floor is Apple's; the rest hang off it.
abstract final class Sizes {
  /// The minimum comfortable tap target. Nothing interactive may be smaller —
  /// the audit found 24+ controls at 36 and several at 32.
  static const double tap = 44;

  /// A standard control: rows, chips, pills, bar buttons.
  static const double control = tap;

  /// A primary action with room to breathe. Apple's "large" control size, and
  /// a capsule at this height has an 25pt radius.
  static const double controlLarge = 50;

  /// Chrome.
  static const double navBar = 44;
  static const double largeTitleExtra = 52;
  static const double pinnedHeader = 56;
  static const double tabBar = 56;

  /// Icon sizes: glyph inside a control, a row's leading icon, a hero glyph.
  static const double iconSm = 18;
  static const double iconMd = 22;
  static const double iconLg = 28;

  /// The iOS hairline. Half a point, not one.
  static const double hairline = 0.5;
}
