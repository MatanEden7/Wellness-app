import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../calendar/data/calendar_service.dart';
import '../../calendar/domain/models.dart';
import '../domain/models.dart';
import 'repositories.dart';

// Data class for daily workout buckets
class DailyWorkouts {
  final List<WorkoutSessionWithTemplate> planned;
  final List<WorkoutSessionWithTemplate> active;
  final List<WorkoutSessionWithTemplate> completed;

  const DailyWorkouts({
    required this.planned,
    required this.active,
    required this.completed,
  });

  bool get isEmpty => planned.isEmpty && active.isEmpty && completed.isEmpty;
  bool get hasActive => active.isNotEmpty;

  List<WorkoutSessionWithTemplate> get orderedList {
    return [...active, ...planned, ...completed.reversed];
  }
}

// Provider for daily workouts by selected date
final dailyWorkoutsProvider =
    StreamProvider.family<DailyWorkouts, DateTime>((ref, selectedDate) async* {
  final repository = ref.watch(workoutSessionsRepositoryProvider);

  // Get all sessions for the day - using Drift watch queries for real-time updates
  final allSessionsStream = repository.watchRecentSessions(limit: 100);

  // Always yield initial empty state first (no spinner)
  yield const DailyWorkouts(planned: [], active: [], completed: []);

  await for (final allSessions in allSessionsStream) {
    final targetDate =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    final planned = <WorkoutSessionWithTemplate>[];
    final active = <WorkoutSessionWithTemplate>[];
    final completed = <WorkoutSessionWithTemplate>[];

    for (final sessionWithTemplate in allSessions) {
      final session = sessionWithTemplate.session;
      final sessionDate = DateTime(
        session.startedAt.year,
        session.startedAt.month,
        session.startedAt.day,
      );

      // Only include sessions from the target date
      if (sessionDate.isAtSameMomentAs(targetDate)) {
        if (session.endedAt == null) {
          // Active session (no end time)
          active.add(sessionWithTemplate);
        } else {
          // Completed session (has end time)
          completed.add(sessionWithTemplate);
        }
      }
    }

    // Planned workouts come from real scheduled calendar events for this day.
    //
    // This previously fabricated them: it took the first two workout
    // templates and presented them as sessions at 9AM/10AM on *any* date with
    // no logged sessions -- past days included -- so the UI showed workouts
    // the user had never scheduled.
    final scheduledWorkouts = await _plannedFromCalendar(ref, targetDate);
    for (final scheduled in scheduledWorkouts) {
      // Don't double-count something already started or finished today.
      final alreadyLogged = [...active, ...completed].any(
        (s) => s.session.templateId == scheduled.templateId,
      );
      if (alreadyLogged) continue;

      planned.add(WorkoutSessionWithTemplate(
        session: WorkoutSession(
          id: 'planned_${scheduled.eventId}',
          templateId: scheduled.templateId,
          startedAt: scheduled.scheduledAt,
          endedAt: null,
        ),
        templateName: scheduled.title,
      ));
    }
    planned.sort((a, b) => a.session.startedAt.compareTo(b.session.startedAt));

    yield DailyWorkouts(
      planned: planned,
      active: active,
      completed: completed,
    );
  }
});

/// A workout the user actually scheduled, resolved from the calendar.
class _ScheduledWorkout {
  const _ScheduledWorkout({
    required this.eventId,
    required this.templateId,
    required this.title,
    required this.scheduledAt,
  });

  final String eventId;
  final String? templateId;
  final String title;
  final DateTime scheduledAt;
}

Future<List<_ScheduledWorkout>> _plannedFromCalendar(
  Ref ref,
  DateTime day,
) async {
  try {
    final calendarService = ref.read(calendarServiceProvider);
    final events = await calendarService.getEventsForDate(day);

    return events
        .where((e) =>
            e.type == EventType.workout &&
            e.status == EventStatus.planned &&
            // getEventsForDate also surfaces already-logged sessions as
            // derived events; those are handled from the sessions stream.
            !e.id.startsWith('workout_'))
        .map((e) => _ScheduledWorkout(
              eventId: e.id,
              templateId: e.templateId,
              title: e.title,
              scheduledAt: e.scheduledAt,
            ))
        .toList();
  } catch (e) {
    debugPrint('[WORKOUTS] Could not load planned workouts: $e');
    return const [];
  }
}

/// Today's workouts.
///
/// Keyed on the date at midnight rather than `DateTime.now()`: a family key
/// with millisecond precision made every read a distinct provider instance
/// with its own stream subscription that was never reused.
final todayWorkoutsProvider = Provider<AsyncValue<DailyWorkouts>>((ref) {
  final now = DateTime.now();
  return ref
      .watch(dailyWorkoutsProvider(DateTime(now.year, now.month, now.day)));
});
