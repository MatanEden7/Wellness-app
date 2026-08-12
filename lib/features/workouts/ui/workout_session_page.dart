import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../shell/platform_page.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../services/notification_service.dart';
import '../../../services/notification_preferences_service.dart';
import '../../../services/time_service.dart';
import '../../../services/preferences_service.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import '../domain/rest_time.dart';
import '../domain/session_actions.dart';
import 'exercise_picker_sheet.dart';
import 'workout_keys.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import '../../../core/ios/glass.dart';
import '../../../core/design/surfaces.dart';
import '../../../core/design/tokens.dart';
import '../../../core/ios/feedback.dart';

class WorkoutSessionPage extends HookConsumerWidget {
  final String sessionId;

  const WorkoutSessionPage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final session = useState<WorkoutSession?>(null);
    final template = useState<WorkoutTemplate?>(null);
    final exercises = useState<List<Exercise>>([]);
    final currentExerciseIndex = useState(0);
    final isLoading = useState(true);

    // Load session data
    useEffect(() {
      _loadSessionData(ref, sessionId, session, template, exercises, isLoading);
      return null;
    }, [sessionId]);

    if (isLoading.value || session.value == null) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Loading workout...'),
      );
    }

    final currentSession = session.value!;
    final isCompleted = currentSession.isCompleted;

    return PlatformNavPage(
      chrome: PageChrome(
        title: template.value?.name ?? l10n.workoutSession,
        actions: [
          if (!isCompleted)
            ChromeAction(
              key: WorkoutKeys.addExerciseFab,
              icon: CupertinoIcons.add,
              tooltip: l10n.addExercise,
              onPressed: () =>
                  _addExercise(context, ref, session, template, exercises),
            ),
          if (!isCompleted)
            ChromeAction(
              label: l10n.finishWorkout,
              tooltip: l10n.finishWorkoutTooltip,
              isProminent: true,
              onPressed: () => _finishWorkout(context, ref, currentSession),
            ),
        ],
      ),
      body: Column(
        children: [
          // Session Info
          ContentSurface.tinted(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Space.xl, vertical: Space.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SessionStat(
                        label: l10n.duration,
                        value: _formatSessionDuration(currentSession),
                        icon: Icons.timer,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Theme.of(context).dividerColor,
                      ),
                      _SessionStat(
                        label: l10n.sets,
                        value: currentSession.sets.length.toString(),
                        icon: Icons.fitness_center,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Theme.of(context).dividerColor,
                      ),
                      _SessionStat(
                        label: l10n.exercises,
                        value: exercises.value.length.toString(),
                        icon: Icons.list,
                      ),
                    ],
                  ),
                  if (!isCompleted && exercises.value.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Builder(
                      builder: (context) {
                        // Calculate total target sets across all exercises
                        int totalTargetSets = 0;
                        for (final exercise in exercises.value) {
                          final templateExercise =
                              template.value?.exercises.firstWhere(
                            (te) => te.exerciseId == exercise.id,
                            orElse: () => TemplateExercise.create(
                              templateId: '',
                              exerciseId: exercise.id,
                              orderIndex: 0,
                            ),
                          );
                          totalTargetSets += templateExercise?.defaultSets ?? 3;
                        }

                        // Total completed sets across entire workout
                        final totalCompletedSets = currentSession.sets.length;
                        final progress = totalTargetSets > 0
                            ? totalCompletedSets / totalTargetSets
                            : 0.0;

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            minHeight: 8,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Exercise ${currentExerciseIndex.value + 1} of ${exercises.value.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Exercise List or Current Exercise
          Expanded(
            child: isCompleted
                ? _CompletedWorkoutView(
                    session: currentSession, exercises: exercises.value)
                : _ActiveWorkoutView(
                    session: currentSession,
                    template: template.value,
                    exercises: exercises.value,
                    currentExerciseIndex: currentExerciseIndex,
                    onSetCompleted: (setEntry) =>
                        _addSetEntry(ref, setEntry, session),
                    onNextExercise: () {
                      if (currentExerciseIndex.value <
                          exercises.value.length - 1) {
                        currentExerciseIndex.value++;
                      }
                    },
                    onFinishWorkout: () =>
                        _finishWorkout(context, ref, currentSession),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSessionData(
    WidgetRef ref,
    String sessionId,
    ValueNotifier<WorkoutSession?> session,
    ValueNotifier<WorkoutTemplate?> template,
    ValueNotifier<List<Exercise>> exercises,
    ValueNotifier<bool> isLoading,
  ) async {
    try {
      final sessionData = await ref
          .read(workoutSessionsRepositoryProvider)
          .getSessionById(sessionId);
      if (sessionData == null) return;

      session.value = sessionData;

      if (sessionData.templateId != null) {
        final templateData = await ref
            .read(workoutTemplatesRepositoryProvider)
            .getTemplateById(sessionData.templateId!);
        template.value = templateData;

        if (templateData != null) {
          final exerciseList = <Exercise>[];
          for (final templateExercise in templateData.exercises) {
            // Rest rows are breaks in the plan, not things to perform. They
            // would resolve to a null exercise and be dropped anyway; saying
            // so explicitly stops that looking like a lookup failure.
            if (templateExercise.isRest) continue;
            final exercise = await ref
                .read(exercisesRepositoryProvider)
                .getExerciseById(templateExercise.exerciseId);
            if (exercise != null) {
              exerciseList.add(exercise);
            }
          }
          exercises.value = exerciseList;
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _addSetEntry(
    WidgetRef ref,
    SetEntry setEntry,
    ValueNotifier<WorkoutSession?> session,
  ) async {
    // Save the set with the current session ID
    final setWithSessionId = setEntry.copyWith(sessionId: sessionId);
    await ref
        .read(workoutSessionsRepositoryProvider)
        .addSetEntry(setWithSessionId);

    // Force a small delay to ensure DB write completes
    await Future.delayed(const Duration(milliseconds: 100));

    // Reload session to update UI with new set
    final updatedSession = await ref
        .read(workoutSessionsRepositoryProvider)
        .getSessionById(sessionId);
    if (updatedSession != null) {
      session.value = updatedSession;
    }
  }

  /// Adds an exercise to the running session.
  ///
  /// For a quick workout this is what brings the session's template into
  /// existence -- see [addExerciseToSession]. The prescription (weight, sets,
  /// reps, rest) is stored on that template, so it persists across app
  /// restarts and the workout can be run again later.
  Future<void> _addExercise(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<WorkoutSession?> session,
    ValueNotifier<WorkoutTemplate?> template,
    ValueNotifier<List<Exercise>> exercises,
  ) async {
    final currentSession = session.value;
    if (currentSession == null) return;

    final l10n = AppLocalizations.of(context)!;
    final adHocName = l10n
        .quickWorkoutNamed(AppDateUtils.formatDate(currentSession.startedAt));

    final prescription = await showExercisePicker(context);
    if (prescription == null) return;

    final result = await addExerciseToSession(
      ref,
      session: currentSession,
      template: template.value,
      exerciseId: prescription.exercise.id,
      adHocName: adHocName,
      sets: prescription.sets,
      reps: prescription.reps,
      weight: prescription.weight,
      restSeconds: prescription.restSeconds,
    );

    session.value = result.session;
    template.value = result.template;
    exercises.value = [...exercises.value, prescription.exercise];

    if (context.mounted) {
      showAppBanner(
          context, l10n.exerciseAddedToWorkout(prescription.exercise.name));
    }
  }

  Future<void> _finishWorkout(
      BuildContext context, WidgetRef ref, WorkoutSession session) async {
    final completedSession = session.copyWith(endedAt: DateTime.now());
    await ref
        .read(workoutSessionsRepositoryProvider)
        .updateSession(completedSession);
    if (context.mounted) {
      context.pop();
    }
  }

  String _formatSessionDuration(WorkoutSession session) {
    final duration =
        session.duration ?? DateTime.now().difference(session.startedAt);
    return AppDateUtils.formatDuration(duration);
  }
}

class _SessionStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SessionStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _ActiveWorkoutView extends HookConsumerWidget {
  final WorkoutSession session;
  final WorkoutTemplate? template;
  final List<Exercise> exercises;
  final ValueNotifier<int> currentExerciseIndex;
  final Future<void> Function(SetEntry) onSetCompleted;
  final VoidCallback? onNextExercise;
  final VoidCallback onFinishWorkout;

  const _ActiveWorkoutView({
    required this.session,
    required this.template,
    required this.exercises,
    required this.currentExerciseIndex,
    required this.onSetCompleted,
    this.onNextExercise,
    required this.onFinishWorkout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (exercises.isEmpty) {
      // No action button: the FAB below is the add-exercise entry point, and
      // this used to send people to the Exercise Library, which browses the
      // catalog and cannot hand anything back to the session.
      return EmptyState(
        title: l10n.noExercisesYet,
        subtitle: l10n.addExercisesToGetStarted,
        icon: Icons.fitness_center,
      );
    }

    final currentExercise = exercises[currentExerciseIndex.value];
    final templateExercise = template?.exercises.firstWhere(
      (te) => te.exerciseId == currentExercise.id,
      orElse: () => TemplateExercise.create(
        templateId: '',
        exerciseId: currentExercise.id,
        orderIndex: 0,
      ),
    );

    final showExerciseDetails = useState(false);
    final showRestTimer = useState<int?>(null);

    return Column(
      children: [
        // Current Exercise Header - Hide during rest timer
        if (showRestTimer.value == null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            // Tap, not long-press: expanding the details was previously
            // bound to a long-press with no affordance for it, so the muscle
            // and notes were effectively invisible.
            child: GestureDetector(
              onTap: () {
                showExerciseDetails.value = !showExerciseDetails.value;
                HapticsHelper.lightImpact();
              },
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            currentExercise.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Row(
                          children: [
                            if (currentExercise.primaryMuscle != null ||
                                currentExercise.notes != null)
                              Icon(
                                showExerciseDetails.value
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 20,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            const SizedBox(width: 8),
                            if (currentExerciseIndex.value > 0)
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () {
                                  showRestTimer.value =
                                      null; // Reset rest timer
                                  currentExerciseIndex.value--;
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: l10n.previous,
                              ),
                            if (currentExerciseIndex.value <
                                exercises.length - 1)
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () {
                                  showRestTimer.value =
                                      null; // Reset rest timer
                                  currentExerciseIndex.value++;
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: l10n.next,
                              ),
                          ],
                        ),
                      ],
                    ),
                    // The prescription itself, always visible -- it is what
                    // the set counter and the rest timer are both driven by.
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.setsAndRestSummary(
                        templateExercise?.defaultSets ?? 3,
                        formatRest(
                          resolveRestSeconds(
                            explicitSeconds:
                                templateExercise?.defaultRestSeconds,
                            reps: templateExercise?.defaultReps,
                            globalDefaultSeconds: ref
                                .watch(preferencesServiceProvider)
                                .defaultRestTime,
                          ),
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                    // Show details only when expanded
                    if (showExerciseDetails.value) ...[
                      if (currentExercise.primaryMuscle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${l10n.primaryMuscle}: ${currentExercise.primaryMuscle}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (currentExercise.notes != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          currentExercise.notes!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),

        // Sets View (fills remaining space)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _ExerciseSetsView(
              session: session,
              exercise: currentExercise,
              templateExercise: templateExercise,
              onSetCompleted: onSetCompleted,
              onExerciseComplete:
                  currentExerciseIndex.value < exercises.length - 1
                      ? () {
                          showRestTimer.value =
                              null; // Reset rest timer when moving to next exercise
                          onNextExercise?.call();
                        }
                      : null,
              onFinishWorkout: onFinishWorkout,
              showRestTimer: showRestTimer,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseSetsView extends HookConsumerWidget {
  final WorkoutSession session;
  final Exercise exercise;
  final TemplateExercise? templateExercise;
  final Future<void> Function(SetEntry) onSetCompleted;
  final VoidCallback? onExerciseComplete;
  final VoidCallback onFinishWorkout;
  final ValueNotifier<int?> showRestTimer;

  const _ExerciseSetsView({
    required this.session,
    required this.exercise,
    required this.templateExercise,
    required this.onSetCompleted,
    this.onExerciseComplete,
    required this.onFinishWorkout,
    required this.showRestTimer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedSets =
        session.sets.where((set) => set.exerciseId == exercise.id).toList();
    final targetSets = templateExercise?.defaultSets ?? 3;
    final prefs = ref.watch(preferencesServiceProvider);
    final theme = Theme.of(context);
    final isLoading = useState(false);

    // Check if exercise is complete
    final isExerciseComplete = completedSets.length >= targetSets;

    final reps = templateExercise?.defaultReps ?? 10;
    final weight = templateExercise?.defaultWeight;

    // One answer for "how long is the rest here", used both to start the
    // timer and to stamp the set that was just logged. An explicit value on
    // the template wins; otherwise the rep count picks it, and only then does
    // the global Workout Settings default apply.
    final restForThisSet = resolveRestSeconds(
      explicitSeconds: templateExercise?.defaultRestSeconds,
      reps: templateExercise?.defaultReps,
      globalDefaultSeconds: prefs.defaultRestTime,
    );

    return Column(
      children: [
        // Main content area - scrollable
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Show rest timer OR current set display
                      if (showRestTimer.value != null)
                        _RestTimerCard(
                          initialSeconds: showRestTimer.value!,
                          exerciseName: exercise.name,
                          onComplete: () => showRestTimer.value = null,
                          onSkip: () => showRestTimer.value = null,
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Space.xl, vertical: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!isExerciseComplete) ...[
                                Text(
                                  'SET ${completedSets.length + 1} OF $targetSets',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  '$reps',
                                  style: TextStyle(
                                    fontSize: 80,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(context)!.repsUppercase,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w500,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                                // No prescribed weight means bodyweight, and
                                // the chip says so rather than vanishing --
                                // an absent chip reads as missing data.
                                const SizedBox(height: 24),
                                ContentSurface.tinted(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Space.xl,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      weight == null ||
                                              exercise.unit == 'bodyweight'
                                          ? AppLocalizations.of(context)!
                                              .bodyweight
                                          : '${Formatters.formatWeight(weight)} ${exercise.unit}',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme
                                            .colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (isExerciseComplete) ...[
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 64,
                                  color: Colors.green,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  AppLocalizations.of(context)!
                                      .exerciseComplete,
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$targetSets sets completed',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                      // Completed sets at bottom (only show when NOT resting)
                      if (completedSets.isNotEmpty &&
                          showRestTimer.value == null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          margin:
                              const EdgeInsets.symmetric(horizontal: Space.lg),
                          child: ContentSurface(
                            borderRadius: BorderRadius.circular(12),
                            padding: const EdgeInsets.all(Space.lg),
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.completedSets,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: completedSets
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final index = entry.key;
                                    final set = entry.value;
                                    return _CompactSetChip(
                                      setNumber: index + 1,
                                      setEntry: set,
                                      exercise: exercise,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Fixed bottom action panel - ALWAYS VISIBLE
        ContentSurface(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          color: theme.colorScheme.surface,
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            child: SafeArea(
              top: false,
              child: _buildActionButton(
                context,
                theme,
                completedSets,
                targetSets,
                isExerciseComplete,
                isLoading,
                onSetCompleted,
                onExerciseComplete,
                onFinishWorkout,
                reps,
                weight,
                restForThisSet,
                showRestTimer,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    ThemeData theme,
    List<SetEntry> completedSets,
    int targetSets,
    bool isExerciseComplete,
    ValueNotifier<bool> isLoading,
    Future<void> Function(SetEntry) onSetCompleted,
    VoidCallback? onExerciseComplete,
    VoidCallback onFinishWorkout,
    int reps,
    double? weight,
    int restForThisSet,
    ValueNotifier<int?> showRestTimer,
  ) {
    if (isExerciseComplete) {
      if (onExerciseComplete != null) {
        // Not the last exercise - show "Next Exercise" button
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: GlassButton(
            prominent: true,
            tint: Colors.green,
            borderRadius: BorderRadius.circular(16),
            onPressed: onExerciseComplete,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_forward_rounded, size: 24),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.nextExercise,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      } else {
        // Last exercise - show "Finish Workout" button
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: GlassButton(
            prominent: true,
            tint: Colors.orange,
            borderRadius: BorderRadius.circular(16),
            onPressed: onFinishWorkout,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 24),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.finishWorkout,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (completedSets.length < targetSets) {
      final isResting = showRestTimer.value != null;

      return SizedBox(
        width: double.infinity,
        height: 56,
        child: isLoading.value
            ? ContentSurface.tinted(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
              )
            : GlassButton(
                prominent: true,
                tint: isResting
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
                onPressed: isResting
                    ? () {
                        // Skip rest timer
                        showRestTimer.value = null;
                        HapticsHelper.lightImpact();
                      }
                    : () async {
                        // Complete set
                        isLoading.value = true;
                        try {
                          final setEntry = SetEntry.create(
                            sessionId: '',
                            exerciseId: exercise.id,
                            orderIndex: completedSets.length,
                            reps: reps,
                            weight: weight,
                            // Was never written, so every logged set had a
                            // null rest and history could not show what was
                            // actually prescribed.
                            restSeconds: restForThisSet,
                          );
                          await onSetCompleted(setEntry);
                          HapticsHelper.mediumImpact();

                          // Check if we should start rest timer
                          final updatedCompletedSets = session.sets
                              .where((set) => set.exerciseId == exercise.id)
                              .length;
                          if (updatedCompletedSets < targetSets) {
                            // Per-exercise rest when the template prescribes
                            // it, falling back to the global preference.
                            // One 90s value for both a heavy squat and a
                            // cable curl is wrong in both directions: it
                            // wastes a third of the session on the isolation
                            // work and under-recovers the compound.
                            showRestTimer.value = restForThisSet;
                          }
                        } finally {
                          isLoading.value = false;
                        }
                      },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isResting ? Icons.skip_next : Icons.check_circle_rounded,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isResting
                          ? 'Skip Rest'
                          : 'Complete Set ${completedSets.length + 1}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
      );
    }

    return const SizedBox.shrink();
  }
}

// Compact chip for completed sets
class _CompactSetChip extends StatelessWidget {
  final int setNumber;
  final SetEntry setEntry;
  final Exercise exercise;

  const _CompactSetChip({
    required this.setNumber,
    required this.setEntry,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ContentSurface.tinted(
      color: Colors.green.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.md, vertical: Space.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 16, color: Colors.green),
            const SizedBox(width: 6),
            Text(
              '$setNumber: ${setEntry.reps}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (setEntry.weight != null) ...[
              Text(' × ', style: TextStyle(color: Colors.grey.shade600)),
              Text(
                '${Formatters.formatWeight(setEntry.weight!)}${exercise.unit}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RestTimerCard extends HookConsumerWidget {
  final int initialSeconds;
  final String exerciseName;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const _RestTimerCard({
    required this.initialSeconds,
    required this.exerciseName,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final timerController =
        ref.watch(restTimerControllerProvider(initialSeconds));
    final notificationService = ref.read(notificationServiceProvider);
    final notificationPrefs = ref.watch(notificationPreferencesProvider);
    final prefs = ref.watch(preferencesServiceProvider);

    final audioPlayer = useMemoized(() => AudioPlayer());
    final isMuted = useState(false);

    // Auto-start timer when created (delayed to avoid modifying provider during build)
    useEffect(() {
      Future.microtask(() {
        ref.read(restTimerControllerProvider(initialSeconds).notifier).start();
      });
      return null;
    }, []);

    // Handle timer completion with beep and auto-dismiss
    useEffect(() {
      if (timerController.isCompleted) {
        if (!isMuted.value) {
          _playTimerBeep(audioPlayer, prefs);
          notificationService.showRestTimerNotification(
            title: l10n.restTimerCompleteTitle,
            body: l10n.restTimerCompleteBody(exerciseName),
            soundEnabled: notificationPrefs.soundEnabled,
            vibrationEnabled: notificationPrefs.vibrationEnabled,
          );
          HapticsHelper.heavyImpact();
        }
        // Auto-dismiss timer after completion
        Future.delayed(const Duration(seconds: 1), () {
          audioPlayer.stop();
          onComplete();
        });
      }
      return null;
    }, [timerController.isCompleted]);

    // Cleanup audio player
    useEffect(() {
      return () => audioPlayer.dispose();
    }, []);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top label with mute button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.restTimerUppercase,
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: Icon(
                  isMuted.value ? Icons.volume_off : Icons.volume_up,
                  size: 18,
                ),
                onPressed: () => isMuted.value = !isMuted.value,
                color: isMuted.value ? Colors.grey : theme.colorScheme.primary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: l10n.muteSound,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Large countdown timer
          Text(
            _formatTime(timerController.remainingSeconds),
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: timerController.remainingSeconds <= 10
                  ? Colors.red
                  : theme.colorScheme.primary,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),

          // Progress bar
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              widthFactor:
                  1 - (timerController.remainingSeconds / initialSeconds),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: timerController.remainingSeconds <= 10
                      ? Colors.red
                      : theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reduce 15s
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: timerController.remainingSeconds > 15
                    ? () {
                        final newTime = timerController.remainingSeconds - 15;
                        ref
                            .read(restTimerControllerProvider(initialSeconds)
                                .notifier)
                            .reset(newTime);
                        ref
                            .read(restTimerControllerProvider(initialSeconds)
                                .notifier)
                            .start();
                      }
                    : null,
                iconSize: 28,
                tooltip: '-15s',
                color: timerController.remainingSeconds > 15
                    ? Colors.orange
                    : Colors.grey,
              ),

              const SizedBox(width: 16),

              // Pause/Resume
              IconButton(
                icon: Icon(
                  timerController.isRunning
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                ),
                onPressed: timerController.isRunning
                    ? () => ref
                        .read(restTimerControllerProvider(initialSeconds)
                            .notifier)
                        .pause()
                    : () => ref
                        .read(restTimerControllerProvider(initialSeconds)
                            .notifier)
                        .resume(),
                iconSize: 40,
                color: theme.colorScheme.primary,
                tooltip: timerController.isRunning ? l10n.pause : l10n.resume,
              ),

              const SizedBox(width: 16),

              // Add 15s
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  ref
                      .read(
                          restTimerControllerProvider(initialSeconds).notifier)
                      .reset(
                        timerController.remainingSeconds + 15,
                      );
                  ref
                      .read(
                          restTimerControllerProvider(initialSeconds).notifier)
                      .start();
                },
                iconSize: 28,
                tooltip: '+15s',
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Path of the rest-timer beep. Declared in `pubspec.yaml`'s `assets:`.
  static const String _beepAsset = 'assets/audio/rest_timer_beep.wav';

  /// Plays the end-of-rest beep at the user's configured volume.
  ///
  /// This used to set the volume on a player that had no audio source and
  /// then just buzz the haptics engine three times, so "Rest timer sound"
  /// and its volume slider produced no sound at all. Haptics are kept as a
  /// deliberate fallback for a silenced device, where the beep is inaudible.
  Future<void> _playTimerBeep(
      AudioPlayer player, PreferencesService prefs) async {
    if (!prefs.restTimerSoundEnabled) return;

    try {
      await player.setVolume(prefs.restTimerVolume);
      await player.setAsset(_beepAsset);
      await player.play();
    } catch (e) {
      debugPrint('Error playing timer beep: $e');
      // Audio failed -- fall back to the buzz pattern so the end of the rest
      // period is still signalled.
      for (int i = 0; i < 3; i++) {
        HapticsHelper.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _CompletedWorkoutView extends StatelessWidget {
  final WorkoutSession session;
  final List<Exercise> exercises;

  const _CompletedWorkoutView({
    required this.session,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          AppCard(
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  AppLocalizations.of(context)!.workoutComplete,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Duration: ${AppDateUtils.formatDuration(session.duration!)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '${session.sets.length} sets completed',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Exercise Summary
          ...exercises.map((exercise) {
            final exerciseSets = session.sets
                .where((set) => set.exerciseId == exercise.id)
                .toList();
            if (exerciseSets.isEmpty) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...exerciseSets.asMap().entries.map((entry) {
                      final index = entry.key;
                      final set = entry.value;
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                size: 16, color: Colors.green),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Set ${index + 1}: ',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            Text('${set.reps} reps'),
                            if (set.weight != null) ...[
                              const Text(' × '),
                              Text(
                                '${Formatters.formatWeight(set.weight!)} ${exercise.unit}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
