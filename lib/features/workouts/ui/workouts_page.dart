import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../routing/routes.dart';
import '../../../services/language_service.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import '../domain/session_actions.dart';
import 'quick_start_workout_dialog.dart';
import 'workout_keys.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

class WorkoutsPage extends ConsumerWidget {
  const WorkoutsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(currentLanguageProvider);
    final templatesAsync = ref.watch(workoutTemplatesStreamProvider);
    final recentSessionsAsync = ref.watch(recentSessionsStreamProvider(5));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.workouts,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: () => context.pop(),
          tooltip: AppLocalizations.of(context)!.backToDashboard,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, size: 22),
            onPressed: () => context.push(Routes.calendar),
            tooltip: AppLocalizations.of(context)!.calendar,
          ),
          // Two actions, not four: the title wrapped on a 393pt screen.
          // Starting a workout is the FAB, the exercise library and template
          // creation each have a labelled button in the page body, so only
          // settings has nowhere else to live.
          IconButton(
            icon: const Icon(Icons.settings, size: 22),
            onPressed: () => context.push(Routes.workoutSettings),
            tooltip: AppLocalizations.of(context)!.workoutSettingsTooltip,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Starting a workout is the FAB; this is the one shortcut it
              // doesn't cover.
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: AppLocalizations.of(context)!.exerciseLibrary,
                  onPressed: () => context.push(Routes.exerciseLibrary),
                  isSecondary: true,
                  icon: Icons.library_books,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

            // Workout Templates
            SectionHeader(
              title: AppLocalizations.of(context)!.workoutTemplates,
              action: AppButton(
                text: AppLocalizations.of(context)!.createTemplate,
                onPressed: () => context.push(Routes.templateEditor),
                isSecondary: true,
                icon: Icons.add,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            StreamBuilder<List<WorkoutTemplate>>(
              stream: templatesAsync,
              builder: (context, snapshot) {
                // Only show loading on initial load (no data yet)
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const LoadingIndicator();
                }

                final templates = snapshot.data ?? [];

                if (templates.isEmpty) {
                  return EmptyState(
                    title: AppLocalizations.of(context)!.designYourWorkouts,
                    subtitle: AppLocalizations.of(context)!.startYourFitness,
                    icon: Icons.fitness_center,
                    actionText: AppLocalizations.of(context)!.createFirstTemplate,
                    actionIcon: Icons.add,
                    onAction: () => context.push(Routes.templateEditor),
                  );
                }

                return Column(
                  children: templates.map((template) {
                    return _WorkoutTemplateCard(
                      template: template,
                      language: language,
                      onStart: () => _startWorkout(context, ref, template),
                      onEdit: () => context.push('/workouts/templates/${template.id}'),
                      onDelete: () => _deleteTemplate(context, ref, template),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Recent Workouts
            SectionHeader(
              title: AppLocalizations.of(context)!.recentWorkouts,
            ),
            const SizedBox(height: AppSpacing.md),

            StreamBuilder<List<WorkoutSessionWithTemplate>>(
              stream: recentSessionsAsync,
              builder: (context, snapshot) {
                // Only show loading on initial load (no data yet)
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const LoadingIndicator();
                }

                final sessionsWithTemplate = snapshot.data ?? [];

                if (sessionsWithTemplate.isEmpty) {
                  return EmptyState(
                    title: AppLocalizations.of(context)!.yourFitnessJourneyAwaits,
                    subtitle: AppLocalizations.of(context)!.completeWorkoutsWillAppear,
                    icon: Icons.history,
                    actionText: AppLocalizations.of(context)!.startQuickWorkout,
                    actionIcon: Icons.play_arrow,
                    onAction: () => _startQuickWorkout(context, ref),
                  );
                }

                return Column(
                  children: sessionsWithTemplate.map((sessionWithTemplate) {
                    return _WorkoutSessionCard(
                      sessionWithTemplate: sessionWithTemplate,
                      onTap: () => context.push('/workouts/session/${sessionWithTemplate.session.id}'),
                    );
                  }).toList(),
                );
              },
            ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: WorkoutKeys.startWorkoutFab,
        onPressed: () => showAppSheet<void>(
          context: context,
          builder: (_) => const QuickStartWorkoutDialog(),
        ),
        icon: const Icon(Icons.play_arrow),
        label: Text(AppLocalizations.of(context)!.startWorkout),
      ),
    );
  }

  Future<void> _startQuickWorkout(BuildContext context, WidgetRef ref) async {
    final session = await startQuickWorkoutSession(ref);
    if (context.mounted) {
      context.push('/workouts/session/${session.id}');
    }
  }

  Future<void> _startWorkout(BuildContext context, WidgetRef ref, WorkoutTemplate template) async {
    final session = await startWorkoutSessionFromTemplate(ref, template);
    if (context.mounted) {
      context.push('/workouts/session/${session.id}');
    }
  }

  Future<void> _deleteTemplate(BuildContext context, WidgetRef ref, WorkoutTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteTemplate),
        content: Text('${AppLocalizations.of(context)!.areYouSure} "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(workoutTemplatesRepositoryProvider).deleteTemplate(template.id);
      // Trigger refresh to update UI immediately
      ref.invalidate(workoutTemplatesRepositoryProvider);
    }
  }
}

class _WorkoutTemplateCard extends StatelessWidget {
  final WorkoutTemplate template;
  final AppLanguage language;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WorkoutTemplateCard({
    required this.template,
    required this.language,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    template.displayName(language),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'start',
                      child: Row(
                        children: [
                          const Icon(Icons.play_arrow, color: Colors.green, size: 20),
                          const SizedBox(width: 12),
                          Text(AppLocalizations.of(context)!.startWorkout),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20),
                          const SizedBox(width: 12),
                          Text(AppLocalizations.of(context)!.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.delete,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                onSelected: (value) {
                  switch (value) {
                    case 'start':
                      onStart();
                      break;
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                ),
              ],
            ),
            if (template.notes != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              template.notes!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppLocalizations.of(context)!.exercisesCount(template.exercises.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: AppLocalizations.of(context)!.startWorkout,
              onPressed: onStart,
              icon: Icons.play_arrow,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _WorkoutSessionCard extends StatelessWidget {
  final WorkoutSessionWithTemplate sessionWithTemplate;
  final VoidCallback onTap;

  const _WorkoutSessionCard({
    required this.sessionWithTemplate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final session = sessionWithTemplate.session;
    final templateName = sessionWithTemplate.templateName ?? AppLocalizations.of(context)!.quickWorkout;
    final startTime = AppDateUtils.formatTime(session.startedAt);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '$templateName • $startTime',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  session.isCompleted ? Icons.check_circle : Icons.play_circle,
                  color: session.isCompleted ? Colors.green : Colors.orange,
                  size: 24,
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppDateUtils.formatDate(session.startedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (session.duration != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${AppLocalizations.of(context)!.duration}: ${AppDateUtils.formatDuration(session.duration!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
            if (session.sets.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppLocalizations.of(context)!.setsCompletedCount(session.sets.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

