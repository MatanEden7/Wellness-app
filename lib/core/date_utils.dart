import 'package:intl/intl.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

class AppDateUtils {
  static DateTime get today => DateTime.now();

  /// Midnight on the same calendar day as [value].
  static DateTime startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Midnight on the Sunday that starts [value]'s week.
  ///
  /// The app follows the Israeli convention throughout -- the calendar
  /// highlights Friday/Saturday as the weekend and the Hebrew locale starts
  /// weeks on Sunday. The weekly aggregates used to start on Monday instead,
  /// so "this week" in the stats disagreed with the week shown on the
  /// calendar.
  static DateTime startOfWeek(DateTime value) {
    final day = startOfDay(value);
    // DateTime.weekday is 1=Mon..7=Sun, so Sunday needs to map to 0.
    final daysSinceSunday = day.weekday % 7;
    // Subtracting via the DateTime constructor (not `Duration`) so a week
    // spanning a DST transition still lands on midnight -- `Duration` is
    // exactly N*24h and drifts to 23:00/01:00 across a clock change, same
    // class of bug already fixed in the calendar's day-stepping helper.
    return DateTime(day.year, day.month, day.day - daysSinceSunday);
  }

  /// Midnight on the day after [value]'s week ends.
  static DateTime endOfWeek(DateTime value) {
    final start = startOfWeek(value);
    return DateTime(start.year, start.month, start.day + 7);
  }

  /// Whether [value] falls on or after [start] and strictly before [end].
  ///
  /// Half-open on purpose: the previous `isAfter(dayStart)` checks silently
  /// excluded anything recorded at exactly midnight.
  static bool isInRange(DateTime value, DateTime start, DateTime end) =>
      !value.isBefore(start) && value.isBefore(end);

  static int dateToInt(DateTime date) {
    return int.parse(DateFormat('yyyyMMdd').format(date));
  }

  static DateTime intToDate(int dateInt) {
    final dateStr = dateInt.toString();
    final year = int.parse(dateStr.substring(0, 4));
    final month = int.parse(dateStr.substring(4, 6));
    final day = int.parse(dateStr.substring(6, 8));
    return DateTime(year, month, day);
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  /// Takes [l10n] so the "h"/"m" suffixes follow the app language -- they were
  /// the last English left on the sleep timer's big duration readout.
  static String formatDuration(Duration duration, AppLocalizations l10n) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return l10n.durationHm('$hours', '$minutes');
    }
    return l10n.durationM('$minutes');
  }
}
