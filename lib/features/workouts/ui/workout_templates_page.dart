import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ios/app_scaffold.dart';
import '../../../core/ios/sheets.dart';
import '../../../core/ios/swipe_row.dart';
import '../../../core/theme.dart';
import '../../../core/ui_constants.dart';
import '../../../core/widgets.dart';
import '../../../routing/routes.dart';
import '../../../services/language_service.dart';
import '../../../services/preferences_service.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import '../domain/session_actions.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

/// Saved workout templates -- the workouts counterpart of the meal templates
/// screen, down to the layout of a row and the placement of its primary
/// button.
///
/// These used to be the top half of the workouts home screen, which is why
/// that screen could not also be a day view. "Use now" there means starting a
/// session from the template, exactly as it means logging a meal here.
class WorkoutTemplatesPage extends ConsumerWidget {
  const WorkoutTemplatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(currentLanguageProvider);
    final workoutsColor = ref.watch(preferencesServiceProvider).workoutsColor;
    final templatesStream = ref.watch(workoutTemplatesStreamProvider);

    return AppScaffold(
      title: l10n.workoutTemplates,
      actions: [
        NavBarAction(
          icon: CupertinoIcons.add,
          tooltip: l10n.createTemplate,
          onPressed: () => context.push(Routes.templateEditor),
        ),
      ],
      slivers: [
        StreamBuilder<List<WorkoutTemplate>>(
          stream: templatesStream,
          builder: (context, snapshot) {
            // See the workouts home screen: spinner on the first load only.
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingIndicator(),
              );
            }

            final templates = snapshot.data ?? [];

            if (templates.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: l10n.designYourWorkouts,
                  subtitle: l10n.startYourFitness,
                  icon: Icons.fitness_center,
                  actionText: l10n.createFirstTemplate,
                  actionIcon: Icons.add,
                  onAction: () => context.push(Routes.templateEditor),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                UIConstants.screenHorizontalPadding,
                UIConstants.cardSpacing,
                UIConstants.screenHorizontalPadding,
                UIConstants.sectionSpacing,
              ),
              sliver: SliverList.builder(
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return _WorkoutTemplateCard(
                    template: template,
                    language: language,
                    color: workoutsColor,
                    onStart: () => _startWorkout(context, ref, template),
                    onEdit: () =>
                        context.push('${Routes.workoutTemplates}/${template.id}'),
                    onDelete: () => _deleteTemplate(ref, template),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _startWorkout(
      BuildContext context, WidgetRef ref, WorkoutTemplate template) async {
    final session = await startWorkoutSessionFromTemplate(ref, template);
    if (context.mounted) {
      context.push('/workouts/session/${session.id}');
    }
  }

  Future<void> _deleteTemplate(WidgetRef ref, WorkoutTemplate template) async {
    await ref
        .read(workoutTemplatesRepositoryProvider)
        .deleteTemplate(template.id);
    ref.invalidate(workoutTemplatesRepositoryProvider);
  }
}

class _WorkoutTemplateCard extends StatelessWidget {
  final WorkoutTemplate template;
  final AppLanguage language;
  final Color color;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  const _WorkoutTemplateCard({
    required this.template,
    required this.language,
    required this.color,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = template.displayName(language);

    return SwipeActionRow(
      rowKey: ValueKey(template.id),
      deleteLabel: l10n.delete,
      confirmTitle: l10n.deleteTemplate,
      confirmMessage: l10n.deleteTemplateConfirmation(name),
      onDelete: onDelete,
      onEdit: onEdit,
      editLabel: l10n.edit,
      actions: [
        AppAction(
          label: l10n.startWorkout,
          icon: CupertinoIcons.play_arrow,
          isDefault: true,
          onPressed: onStart,
        ),
        AppAction(
          label: l10n.edit,
          icon: CupertinoIcons.pencil,
          onPressed: onEdit,
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          onTap: onEdit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppRowMenuButton(
                    title: name,
                    tooltip: l10n.workoutTemplates,
                    actions: [
                      AppAction(
                        label: l10n.startWorkout,
                        icon: CupertinoIcons.play_arrow,
                        isDefault: true,
                        onPressed: onStart,
                      ),
                      AppAction(
                        label: l10n.edit,
                        icon: CupertinoIcons.pencil,
                        onPressed: onEdit,
                      ),
                      AppAction(
                        label: l10n.delete,
                        icon: CupertinoIcons.delete,
                        isDestructive: true,
                        onPressed: () async {
                          final confirmed = await showAppConfirm(
                            context: context,
                            title: l10n.deleteTemplate,
                            message: l10n.deleteTemplateConfirmation(name),
                            confirmLabel: l10n.delete,
                          );
                          if (confirmed) await onDelete();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (template.displayNotes(language) != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  template.displayNotes(language)!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.exercisesCount(template.exercises.length),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: l10n.startWorkout,
                  onPressed: onStart,
                  icon: Icons.play_arrow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
