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
