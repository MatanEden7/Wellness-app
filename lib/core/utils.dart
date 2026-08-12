import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
// import 'package:vibration/vibration.dart';  // Temporarily disabled

// Use AppDateUtils to avoid conflicts with Flutter's DateUtils
class AppDateUtils {
  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _timeFormat = DateFormat('HH:mm');
  static final _dateTimeFormat = DateFormat('MMM d, yyyy HH:mm');

  static String formatDate(DateTime date) => _dateFormat.format(date);

  static String formatTime(DateTime time) => _timeFormat.format(time);

  static String formatDateTime(DateTime dateTime) =>
      _dateTimeFormat.format(dateTime);

  /// Parses an `HH:mm` string as produced by [formatTime].
  ///
  /// Returns null for anything unparseable, so a caller seeding a time picker
  /// from a possibly-empty text field can fall back without a try/catch.
  static TimeOfDay? parseTimeOfDay(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static int dateToInt(DateTime date) {
    return int.parse(_dateFormat.format(date).replaceAll('-', ''));
  }

  static DateTime intToDate(int dateInt) {
    final dateStr = dateInt.toString();
    final year = int.parse(dateStr.substring(0, 4));
    final month = int.parse(dateStr.substring(4, 6));
    final day = int.parse(dateStr.substring(6, 8));
    return DateTime(year, month, day);
  }

  static DateTime get today => DateTime.now();

  static DateTime get startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  static String formatSleepDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}

class Validators {
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '${fieldName ?? 'This field'} must be a valid number';
    }

    if (number <= 0) {
      return '${fieldName ?? 'This field'} must be greater than 0';
    }

    return null;
  }

  static String? nonNegativeNumber(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return '${fieldName ?? 'This field'} must be a valid number';
    }

    if (number < 0) {
      return '${fieldName ?? 'This field'} must be 0 or greater';
    }

    return null;
  }

  static String? positiveInteger(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return '${fieldName ?? 'This field'} must be a valid whole number';
    }

    if (number <= 0) {
      return '${fieldName ?? 'This field'} must be greater than 0';
    }

    return null;
  }
}

class Formatters {
  static String formatMacros(double value) {
    final s = value.toStringAsFixed(1);
    // Trim trailing .0 to save space on small cards
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  static String formatWeight(double value) {
    return value.toStringAsFixed(1);
  }

  static String formatCalories(double value) {
    return value.round().toString();
  }

  static String formatNumber(double value, {int decimals = 1}) {
    return value.toStringAsFixed(decimals);
  }
}

class HapticsHelper {
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Ignore haptic errors
    }
  }

  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Ignore haptic errors
    }
  }

  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Ignore haptic errors
    }
  }

  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Ignore haptic errors
    }
  }

  static Future<void> vibrate({int duration = 200}) async {
    try {
      // Vibration temporarily disabled due to dependency issues
      // if (await Vibration.hasVibrator() ?? false) {
      //   await Vibration.vibrate(duration: duration);
      // }
    } catch (e) {
      // Ignore vibration errors
    }
  }
}
