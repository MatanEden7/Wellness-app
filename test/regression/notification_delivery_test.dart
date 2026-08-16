@Tags(['notifications'])
library;

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellness_app/features/calendar/domain/models.dart';
import 'package:wellness_app/services/notification_preferences_service.dart';
import 'package:wellness_app/services/notification_service.dart';

/// Regression coverage for whether a notification can be *interacted with*
/// and whether it *makes a sound* -- the two halves that the action-dispatch
/// tests (`notification_actions_test.dart`,
/// `integration_test/regression/notification_action_handler_test.dart`)
/// assume are working before they ever get to run.
///
/// Those tests inject a `NotificationResponse` straight into the handler, so
/// they pass whether or not the OS would ever have delivered one. Everything
/// here covers the layer underneath that: which isolate iOS routes an action
/// to, and whether a preference change reaches notifications that are already
/// sitting in the OS queue.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('iOS action routing', () {
    /// Every action the app declares, flattened.
    Iterable<DarwinNotificationAction> allActions() =>
        NotificationService.notificationCategories
            .expand((category) => category.actions)
            .cast<DarwinNotificationAction>();

    test('every action is foreground, or it never reaches the handler', () {
      // iOS chooses the destination isolate from this option alone -- not
      // from whether the app is running. An action without it is handed to
      // the background isolate, which has no ProviderContainer, no open
      // database and no navigator, so NotificationActionHandler never sees
      // it. meal_remove and all three snoozes used to be in exactly that
      // state: the buttons rendered, and pressing them did nothing, ever.
      for (final action in allActions()) {
        expect(
          action.options,
          contains(DarwinNotificationActionOption.foreground),
          reason: '"${action.identifier}" is not foreground, so pressing it '
              'would be delivered to the background isolate and dropped',
        );
      }
    });

    test('the declared actions are exactly the ones the handler dispatches on',
        () {
      // NotificationActionHandler._handleAction switches on these ids. A
      // category action with no matching case is a dead button; a case with
      // no declared action is unreachable code.
      expect(
        allActions().map((a) => a.identifier).toSet(),
        {
          'meal_approve',
          'meal_remove',
          'meal_snooze',
          'workout_start',
          'workout_snooze',
          'sleep_start',
          'sleep_stop',
          'sleep_snooze',
        },
      );
    });

    test('each event type maps to the category carrying its buttons', () {
      final ids = NotificationService.notificationCategories
          .map((c) => c.identifier)
          .toSet();

      for (final type in EventType.values) {
        expect(ids, contains(NotificationService.categoryIdFor(type)),
            reason: 'a scheduled $type would show no action buttons at all');
      }
    });

    test('the rest timer id cannot collide with an event notification', () {
      // Event ids are hashed into a non-negative int; the rest timer sits
      // outside that range so a completed rest never silently replaces a
      // pending meal or workout reminder.
      expect(NotificationService.restTimerNotificationId, lessThan(0));
    });
  });

  group('preference changes reach already-scheduled notifications', () {
    late NotificationPreferencesNotifier prefs;
    late int resyncs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = NotificationPreferencesNotifier(
        await SharedPreferences.getInstance(),
      );
      resyncs = 0;
      prefs.onScheduleAffectingChange = () async => resyncs++;
    });

    // Sound, vibration, lead time, quiet hours and the category switches are
    // all read at *schedule* time. Without a resync, flipping one left every
    // pending reminder exactly as it was -- sound off still chimed, meals off
    // still fired meal reminders -- until the event happened to be edited.
    test('every schedule-affecting setter triggers a resync', () async {
      await prefs.setSoundEnabled(false);
      expect(resyncs, 1, reason: 'muting must re-issue pending reminders');

      await prefs.setVibrationEnabled(false);
      await prefs.setMealsEnabled(false);
      await prefs.setWorkoutsEnabled(false);
      await prefs.setSleepEnabled(false);
      await prefs.setMealLeadTime(15);
      await prefs.setWorkoutLeadTime(15);
      await prefs.setSleepLeadTime(15);
      await prefs.setQuietHoursEnabled(true);
      await prefs.setQuietHoursStart(23, 0);
      await prefs.setQuietHoursEnd(6, 30);

      expect(resyncs, 11);
    });

    test('settings that no scheduled notification reads do not resync',
        () async {
      // sleepGoalHours is compared against a finished sleep session, and the
      // sleep-log reminder time is not scheduled at all -- neither changes
      // anything sitting in the OS queue, so neither should churn it.
      await prefs.setSleepGoalHours(9.5);
      await prefs.setSleepReminderTime(11, 15);

      expect(resyncs, 0);
    });

    test('an unattached notifier still applies changes', () async {
      // The callback is optional -- tests and any non-app container construct
      // this notifier without one, and a null callback must not throw.
      prefs.onScheduleAffectingChange = null;

      await prefs.setSoundEnabled(false);

      expect(prefs.state.soundEnabled, isFalse);
    });
  });

  group('rest timer sound', () {
    // The beep used to be a comment saying "in production, you'd want to add
    // an actual beep sound file to assets" -- the player was given a volume
    // and never a source, so the sound switch and volume slider in workout
    // settings produced nothing audible.
    const asset = 'assets/audio/rest_timer_beep.wav';

    test('the beep asset exists and is real audio', () {
      final file = File(asset);
      expect(file.existsSync(), isTrue, reason: '$asset is missing');

      final header = file.readAsBytesSync().sublist(0, 12);
      expect(String.fromCharCodes(header.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(header.sublist(8, 12)), 'WAVE');
      expect(file.lengthSync(), greaterThan(1000),
          reason: 'a silent or truncated file would be no better than none');
    });

    test('the asset is declared in pubspec.yaml', () {
      // An asset that exists on disk but is not declared is not bundled, and
      // setAsset() fails at runtime on device while working fine in tests.
      expect(
          File('pubspec.yaml').readAsStringSync(), contains('- assets/audio/'));
    });
  });
}
