/// Legacy dimension constants.
///
/// Superseded by `lib/core/design/tokens.dart`, which is the single scale the
/// app is built on. These forward to it rather than holding their own values:
/// the two used to disagree — `screenHorizontalPadding` was 20 while
/// `AppSpacing.md` was 16 — so a screen built against one was misaligned by
/// 4pt against a screen built against the other.
///
/// New code should use `Space`, `Radii`, `Sizes` and `AppType` directly.
library;

import 'design/tokens.dart';

class UIConstants {
  // Spacing
  static const double screenHorizontalPadding = Space.screen;
  static const double cardSpacing = Space.cardGap;
  static const double sectionSpacing = Space.section;

  // Card styling
  static const double cardBorderRadius = Radii.card;
  static const double cardPadding = Space.card;
  static const double cardElevation = 0;

  // Text sizes
  static const double titleFontSize = AppType.title3;
  static const double headingFontSize = AppType.headline;
  static const double bodyFontSize = AppType.subheadline;
  static const double captionFontSize = AppType.footnote;

  // Icon sizes
  static const double iconSizeSmall = Sizes.iconSm;
  static const double iconSizeMedium = Sizes.iconMd;
  static const double iconSizeLarge = Sizes.iconLg;

  // Controls
  static const double buttonHeight = Sizes.control;
  static const double buttonBorderRadius = Radii.control;
  static const double fabSize = 56.0;

  // AppBar
  static const double appBarIconSize = Sizes.iconMd;
  static const double appBarTitleSize = AppType.title3;
}
