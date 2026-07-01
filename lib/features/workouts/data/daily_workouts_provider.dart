import 'package:hooks_riverpod/hooks_riverpod.dart';
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
final dailyWorkoutsProvider = StreamProvider.family<DailyWorkouts, DateTime>((ref, selectedDate) async* {
  final repository = ref.watch(workoutSessionsRepositoryProvider);
  
  // Get all sessions for the day - using Drift watch queries for real-time updates
  final allSessionsStream = repository.watchRecentSessions(limit: 100);
  
  // Always yield initial empty state first (no spinner)
  yield const DailyWorkouts(planned: [], active: [], completed: []);
  
  await for (final allSessions in allSessionsStream) {
    final targetDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
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
    
    // TODO: Add planned sessions logic when planning feature is implemented
    // For now, we'll use workout templates as "planned" if no sessions exist
    if (active.isEmpty && completed.isEmpty) {
      final templatesRepository = ref.watch(workoutTemplatesRepositoryProvider);
      final templates = await templatesRepository.watchAllTemplates().first;
      
      // Convert first 2 templates to "planned" sessions for demo
      for (int i = 0; i < templates.length && i < 2; i++) {
        final template = templates[i];
        final plannedSession = WorkoutSession(
          id: 'planned_${template.id}',
          templateId: template.id,
          startedAt: DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            9 + i, // 9 AM, 10 AM etc.
          ),
          endedAt: null,
        );
        
        planned.add(WorkoutSessionWithTemplate(
          session: plannedSession,
          templateName: template.name,
        ));
      }
    }
    
    yield DailyWorkouts(
      planned: planned,
      active: active,
      completed: completed,
    );
  }
});

// Provider for today's workouts (convenience)
final todayWorkoutsProvider = Provider<AsyncValue<DailyWorkouts>>((ref) {
  final today = DateTime.now();
  return ref.watch(dailyWorkoutsProvider(today));
});
