import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Helper class for RTL support
class RTLHelper {
  /// Check if current locale is RTL
  static bool isRTL(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'he' || locale.languageCode == 'ar';
  }

  /// Get text direction based on locale
  static TextDirection getTextDirection(BuildContext context) {
    return isRTL(context) ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Wrap widget with proper directionality for RTL
  static Widget withDirectionality(BuildContext context, Widget child) {
    return Directionality(
      textDirection: getTextDirection(context),
      child: child,
    );
  }

  /// The "go to the previous thing" chevron, pointing the way it means.
  ///
  /// `CupertinoIcons.chevron_back` and `chevron_forward` read as directional
  /// but their glyphs are fixed — back is always left-pointing. A `Row` mirrors
  /// its children under RTL, so the Previous control correctly moves to the
  /// right-hand side and then still draws a left-pointing arrow: both chevrons
  /// end up pointing at the wrong neighbour. Choosing the glyph by direction is
  /// what keeps "previous" pointing towards where previous actually is.
  static IconData chevronBack(BuildContext context) => isRTL(context)
      ? CupertinoIcons.chevron_forward
      : CupertinoIcons.chevron_back;

  /// The mirror of [chevronBack], for "go to the next thing".
  static IconData chevronForward(BuildContext context) => isRTL(context)
      ? CupertinoIcons.chevron_back
      : CupertinoIcons.chevron_forward;

  /// Wrap numeric content to always be LTR
  static Widget numericLTR(Widget child) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    );
  }

  /// Get alignment based on text direction
  static Alignment getStartAlignment(BuildContext context) {
    return isRTL(context) ? Alignment.centerRight : Alignment.centerLeft;
  }

  /// Get alignment based on text direction
  static Alignment getEndAlignment(BuildContext context) {
    return isRTL(context) ? Alignment.centerLeft : Alignment.centerRight;
  }

  /// Get text align based on text direction
  static TextAlign getStartTextAlign(BuildContext context) {
    return isRTL(context) ? TextAlign.right : TextAlign.left;
  }

  /// Get text align based on text direction
  static TextAlign getEndTextAlign(BuildContext context) {
    return isRTL(context) ? TextAlign.left : TextAlign.right;
  }

  /// Get cross axis alignment for rows
  static CrossAxisAlignment getStartCrossAxisAlignment(BuildContext context) {
    return isRTL(context) ? CrossAxisAlignment.end : CrossAxisAlignment.start;
  }

  /// Get main axis alignment for rows
  static MainAxisAlignment getStartMainAxisAlignment(BuildContext context) {
    return isRTL(context) ? MainAxisAlignment.end : MainAxisAlignment.start;
  }
}
