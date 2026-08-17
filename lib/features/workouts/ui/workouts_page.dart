import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ios/date_strip.dart';
import '../../../core/ios/sheets.dart';
import '../../../core/ios/shortcuts.dart';
import '../../../core/ios/swipe_row.dart';
import '../../../shell/platform_page.dart';
import '../../../core/theme.dart';
import '../../../core/ui_constants.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../routing/routes.dart';
import '../../../services/preferences_service.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import 'quick_start_workout_dialog.dart';
import 'workout_keys.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

/// The home of the workouts area.
///
/// Structurally the same screen as the meals home, deliberately: pick a day,
/// see what that day's totals were, see the individual entries, add another.
/// It used to be a different shape entirely -- an undated list of every
/// template stacked above the last five sessions -- which meant the two
/// halves of the app taught you two different ways to read a day. Templates
/// now live on their own screen, exactly as meal templates do.
class WorkoutsPage extends HookConsumerWidget {
  const WorkoutsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedDate = useState(AppDateUtils.today);
    final dateInt = AppDateUtils.dateToInt(selectedDate.value);
    final workoutsColor = ref.watch(preferencesServiceProvider).workoutsColor;
    final sessionsStream = ref.watch(sessionsByDateStreamProvider(dateInt));

    return PlatformPage(
      chrome: PageChrome(
        title: l10n.workouts,
        showBack: false,
        backTooltip: l10n.backToDashboard,
        pinnedHeader: DateStrip(
          date: selectedDate.value,
          onChanged: (next) => selectedDate.value = next,
        ),
        tabIndex: 2,
        actions: [
          ChromeAction(
            icon: CupertinoIcons.calendar,
            tooltip: l10n.calendar,
            onPressed: () => context.push(Routes.calendar),
          ),
          ChromeAction(
            key: WorkoutKeys.startWorkoutFab,
            icon: CupertinoIcons.add,
            tooltip: l10n.startWorkout,
            onPressed: () => showAppSheet<void>(
              context: context,
              builder: (_) => const QuickStartWorkoutDialog(),
            ),
          ),
        ],
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            UIConstants.screenHorizontalPadding,
            UIConstants.cardSpacing,
            UIConstants.screenHorizontalPadding,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: ShortcutRow(
              shortcuts: [
                AppShortcut(
                  icon: CupertinoIcons.square_list,
                  label: l10n.workoutTemplates,
                  color: workoutsColor,
                  onTap: () => context.push(Routes.workoutTemplates),
                ),
                AppShortcut(
                  icon: CupertinoIcons.book,
                  label: l10n.exerciseLibrary,
                  color: workoutsColor,
                  onTap: () => context.push(Routes.exerciseLibrary),
                ),
                AppShortcut(
                  icon: CupertinoIcons.slider_horizontal_3,
                  label: l10n.settings,
                  color: workoutsColor,
                  onTap: () => context.push(Routes.workoutSettings),
                ),
              ],
            ),
          ),
        ),
        _SessionsBody(
          sessionsStream: sessionsStream,
          date: selectedDate.value,
          workoutsColor: workoutsColor,
        ),
      ],
    );
  }
}

/// The day's summary card and its sessions -- one sliver so the whole thing
/// swaps atomically when the date changes.
class _SessionsBody extends ConsumerWidget {
  final Stream<List<WorkoutSessionWithTemplate>> sessionsStream;
  final DateTime date;
  final Color workoutsColor;

  const _SessionsBody({
    required this.sessionsStream,
    required this.date,
    required this.workoutsColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return SliverToBoxAdapter(
      child: StreamBuilder<List<WorkoutSessionWithTemplate>>(
        stream: sessionsStream,
        builder: (context, snapshot) {
          // Only on the very first load: on later rebuilds the list we
          // already have is still valid, and flashing a spinner over it
          // reads as data disappearing.
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.only(top: 80),
              child: LoadingIndicator(),
            );
          }

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 48),
              child: EmptyState(
                title: l10n.noWorkoutsYet,
                subtitle: '${l10n.trackYourTrainingFor.trim()} '
                    '${AppDateUtils.formatDate(date)}',
                icon: Icons.fitness_center,
                actionText: l10n.startQuickWorkout,
                actionIcon: Icons.play_arrow,
                onAction: () => showAppSheet<void>(
                  context: context,
                  builder: (_) => const QuickStartWorkoutDialog(),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(
              UIConstants.screenHorizontalPadding,
              UIConstants.cardSpacing,
              UIConstants.screenHorizontalPadding,
              UIConstants.sectionSpacing,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DayTrainingCard(sessions: sessions, color: workoutsColor),
                const SizedBox(height: UIConstants.cardSpacing),
                for (final entry in sessions)
                  WorkoutSessionCard(
                    sessionWithTemplate: entry,
                    color: workoutsColor,
                    onTap: () =>
                        context.push('/workouts/session/${entry.session.id}'),
                    onDelete: () => _deleteSession(context, ref, entry),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteSession(BuildContext context, WidgetRef ref,
      WorkoutSessionWithTemplate entry) async {
    await ref
        .read(workoutSessionsRepositoryProvider)
        .deleteSession(entry.session.id);
    ref.invalidate(workoutSessionsRepositoryProvider);
  }
}

/// What the day added up to: sets, volume, time under the bar. The workouts
/// counterpart of the meals page's daily totals card, in the same slot.
class _DayTrainingCard extends StatelessWidget {
  final List<WorkoutSessionWithTemplate> sessions;
  final Color color;

  const _DayTrainingCard({required this.sessions, required this.color});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    var sets = 0;
    var volume = 0.0;
    var minutes = 0;
    for (final entry in sessions) {
      sets += entry.session.sets.length;
      for (final set in entry.session.sets) {
        // Bodyweight sets carry no weight; they still count as sets but
        // cannot contribute to a kg total.
        volume += (set.weight ?? 0) * set.reps;
      }
      minutes += entry.session.duration?.inMinutes ?? 0;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.workoutTotals,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SummaryStrip(
            stats: [
              SummaryStat(
                icon: Icons.fitness_center,
                label: l10n.sets,
                value: '$sets',
                color: color,
              ),
              SummaryStat(
                icon: Icons.scale,
                label: l10n.volumeLabel,
                value: '${Formatters.formatCalories(volume)} ${l10n.kg}',
                color: color,
              ),
              SummaryStat(
                icon: Icons.timer_outlined,
                label: l10n.duration,
                value: '$minutes ${l10n.minutesShort}',
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One logged session. Shared with the workout templates screen's "recent"
/// list, hence public.
class WorkoutSessionCard extends StatelessWidget {
  final WorkoutSessionWithTemplate sessionWithTemplate;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;
  final Color color;

  const WorkoutSessionCard({
    super.key,
    required this.sessionWithTemplate,
    required this.onTap,
    required this.onDelete,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final session = sessionWithTemplate.session;
    final name = sessionWithTemplate.templateName ?? l10n.quickWorkout;

    return SwipeActionRow(
      rowKey: ValueKey(session.id),
      deleteLabel: l10n.delete,
      confirmTitle: l10n.deleteWorkout,
      confirmMessage: '${l10n.areYouSure} "$name"?',
      onDelete: onDelete,
      onEdit: onTap,
      editLabel: l10n.edit,
      actions: [
        AppAction(
          label: l10n.edit,
          icon: CupertinoIcons.pencil,
          onPressed: onTap,
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          onTap: onTap,
          child: Row(
            children: [
              SettingsIconBadge(
                session.isCompleted
                    ? Icons.check_circle_outline
                    : Icons.play_circle_outline,
                color: color,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        AppDateUtils.formatTime(session.startedAt),
                        if (session.duration != null)
                          AppDateUtils.formatDuration(
                              session.duration!, AppLocalizations.of(context)!),
                        if (session.sets.isNotEmpty)
                          l10n.setsCompletedCount(session.sets.length),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppRowMenuButton(
                title: name,
                tooltip: l10n.workout,
                actions: [
                  AppAction(
                    label: l10n.edit,
                    icon: CupertinoIcons.pencil,
                    onPressed: onTap,
                  ),
                  AppAction(
                    label: l10n.delete,
                    icon: CupertinoIcons.delete,
                    isDestructive: true,
                    onPressed: () async {
                      final confirmed = await showAppConfirm(
                        context: context,
                        title: l10n.deleteWorkout,
                        message: '${l10n.areYouSure} "$name"?',
                        confirmLabel: l10n.delete,
                      );
                      if (confirmed) await onDelete();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
