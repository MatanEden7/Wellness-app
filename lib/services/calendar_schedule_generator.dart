import '../data/db/drift_database.dart';
import '../features/calendar/data/calendar_service.dart';
import '../features/calendar/domain/models.dart';
import 'user_profile_service.dart';

class CalendarScheduleGenerator {
  final AppDatabase _database;
  final CalendarService _calendarService;
  final UserProfile _profile;

  CalendarScheduleGenerator(this._database, this._calendarService, this._profile);

  Future<void> generateSchedule() async {
    print('[CALENDAR-GEN] 📅 Generating workout schedule for ${_profile.trainingDaysPerWeek} days/week');
    
    // Get all workout templates
    final templates = await _database.getAllWorkoutTemplates();
    if (templates.isEmpty) {
      print('[CALENDAR-GEN] ⚠️ No workout templates found, skipping schedule generation');
      return;
    }

    // Filter out mobility and rehab templates for scheduling (they're optional)
    final mainTemplates = templates.where((t) => 
      !t.name.toLowerCase().contains('mobility') && 
      !t.name.toLowerCase().contains('rehab')
    ).toList();

    if (mainTemplates.isEmpty) {
      print('[CALENDAR-GEN] ⚠️ No main workout templates found');
      return;
    }

    // Get the schedule days based on training frequency
    final scheduleDays = _getScheduleDays();
    
    // Generate schedule for next 4 weeks
    final startDate = DateTime.now();
    await _generateWeeklySchedule(startDate, mainTemplates, scheduleDays, 4);
    
    print('[CALENDAR-GEN] ✅ Generated 4-week workout schedule');
  }

  List<int> _getScheduleDays() {
    // Returns weekday numbers (1 = Monday, 7 = Sunday)
    if (_profile.trainingDaysPerWeek >= 5) {
      // 5-day PPL: Mon, Tue, Thu, Fri, Sat
      return [1, 2, 4, 5, 6];
    } else if (_profile.trainingDaysPerWeek >= 4) {
      // 4-day: Mon, Tue, Thu, Fri
      return [1, 2, 4, 5];
    } else if (_profile.trainingDaysPerWeek >= 3) {
      // 3-day: Mon, Wed, Fri
      return [1, 3, 5];
    } else {
      // 2-day: Mon, Thu
      return [1, 4];
    }
  }

  Future<void> _generateWeeklySchedule(
    DateTime startDate,
    List<WorkoutTemplateData> templates,
    List<int> scheduleDays,
    int weeks,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (var week = 0; week < weeks; week++) {
      final weekStart = startDate.add(Duration(days: week * 7));
      
      // Find the Monday of this week
      final monday = weekStart.subtract(Duration(days: weekStart.weekday - 1));
      
      var templateIndex = 0;
      
      for (final dayOfWeek in scheduleDays) {
        final workoutDate = monday.add(Duration(days: dayOfWeek - 1));
        
        // Only schedule future workouts
        if (workoutDate.isBefore(today)) continue;
        
        final template = templates[templateIndex % templates.length];
        templateIndex++;
        
        // Set notification time (morning workout default: 7 AM)
        final notificationTime = DateTime(
          workoutDate.year,
          workoutDate.month,
          workoutDate.day,
          7, // 7 AM default
          0,
        );
        
        // Create calendar event using the factory method
        final event = ScheduledEvent.create(
          title: template.name,
          type: EventType.workout,
          scheduledAt: notificationTime,
          templateId: template.id,
          metadata: {
            'leadMinutes': 10, // As per spec: notifications lead_minutes: 10
          },
        );
        await _calendarService.saveEvent(event);
      }
    }
  }
}

