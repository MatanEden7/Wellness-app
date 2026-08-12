import 'dart:async';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Provider for timezone service
final timezoneServiceProvider = Provider<TimezoneService>((ref) {
  throw UnimplementedError('TimezoneService provider must be overridden');
});

// Provider for current timezone
final currentTimezoneProvider = StateProvider<String>((ref) {
  return 'UTC';
});

class TimezoneService {
  String? _currentTimezone;
  final _timezoneController = StreamController<String>.broadcast();

  Stream<String> get timezoneChanges => _timezoneController.stream;
  String? get currentTimezone => _currentTimezone;

  // Initialize timezone database and set local timezone
  Future<void> initialize() async {
    // Initialize timezone database with all timezones
    tz.initializeTimeZones();

    // Get device timezone
    await updateTimezone();

    // Start listening for timezone changes
    _startTimezoneMonitoring();
  }

  // Update to current device timezone
  Future<void> updateTimezone() async {
    try {
      final String timezone = await FlutterNativeTimezone.getLocalTimezone();
      _currentTimezone = timezone;

      // Set as default timezone
      tz.setLocalLocation(tz.getLocation(timezone));

      // Notify listeners
      _timezoneController.add(timezone);
    } catch (e) {
      // Fallback to UTC if device timezone is not found
      _currentTimezone = 'UTC';
      tz.setLocalLocation(tz.UTC);
      _timezoneController.add('UTC');
    }
  }

  // Monitor for timezone changes (e.g., user travels)
  void _startTimezoneMonitoring() {
    // Check timezone every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (_) async {
      final newTimezone = await FlutterNativeTimezone.getLocalTimezone();
      if (newTimezone != _currentTimezone) {
        await updateTimezone();
      }
    });
  }

  // Convert DateTime to TZDateTime in local timezone
  tz.TZDateTime toLocalTZ(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  // Convert TZDateTime to DateTime
  DateTime toDateTime(tz.TZDateTime tzDateTime) {
    return DateTime.fromMillisecondsSinceEpoch(
      tzDateTime.millisecondsSinceEpoch,
      isUtc: false,
    );
  }

  // Get timezone offset in hours
  int getTimezoneOffsetHours() {
    return tz.local.currentTimeZone.offset ~/ Duration.millisecondsPerHour;
  }

  // Get timezone abbreviation (e.g., PST, EST)
  String getTimezoneAbbreviation() {
    return tz.local.name;
  }

  void dispose() {
    _timezoneController.close();
  }
}
