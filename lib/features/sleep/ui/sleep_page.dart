import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ios/sheets.dart';
import '../../../core/ios/swipe_row.dart';
import '../../../shell/platform_page.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../routing/routes.dart';
import '../../../services/notification_preferences_service.dart';
import '../../../services/preferences_service.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

/// Sleep history -- every logged night, plus the entry points that produce
/// them (the live timer, and manual entry for a night you forgot to time).
///
/// This is the *home* of the sleep area, not the timer. Reaching only
/// `/sleep/timer` from the dashboard is what made logged entries look lost:
/// the timer has no list on it, so the history had no on-screen route once
/// the bottom tab bar was removed.
class SleepPage extends ConsumerWidget {
  const SleepPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sleepColor = ref.watch(preferencesServiceProvider).sleepColor;
    final entriesStream = ref.watch(recentSleepEntriesStreamProvider(30));
    final goalHours = ref.watch(notificationPreferencesProvider).sleepGoalHours;
    final streakAsync = ref.watch(sleepStreakProvider(goalHours));

    return PlatformPage(
      chrome: PageChrome(
        title: l10n.sleep,
        showBack: false,
        backTooltip: l10n.backToDashboard,
        tabIndex: 3,
        actions: [
          ChromeAction(
            icon: CupertinoIcons.calendar,
            tooltip: l10n.calendar,
            onPressed: () => context.push(Routes.calendar),
          ),
          ChromeAction(
            icon: CupertinoIcons.add,
            tooltip: l10n.addSleepEntryTooltip,
            onPressed: () => showAddSleepSheet(context),
          ),
        ],
      ),
      slivers: [
        SliverToBoxAdapter(
          child: StreamBuilder<List<SleepEntry>>(
          stream: entriesStream,
          builder: (context, snapshot) {
            // Only show the spinner on the very first load -- on later
            // rebuilds the previous list is still valid and flashing a
            // spinner over it reads as data disappearing.
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const LoadingIndicator();
            }

            final entries = snapshot.data ?? [];
            final active =
                entries.where((e) => !e.isCompleted).firstOrNull;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                _SummaryCard(
                  entries: entries,
                  streak: streakAsync.valueOrNull ?? 0,
                  color: sleepColor,
                ),
                const SizedBox(height: AppSpacing.md),
                _TimerCard(active: active, color: sleepColor),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(title: l10n.sleepHistory),
                const SizedBox(height: AppSpacing.md),
                if (entries.isEmpty)
                  EmptyState(
                    title: l10n.sweetDreamsAwait,
                    subtitle: l10n.trackSleepForInsights,
                    icon: Icons.bedtime,
                    actionText: l10n.startSleepTimer,
                    actionIcon: Icons.bedtime,
                    onAction: () => context.push(Routes.sleepTimer),
                  )
                else
                  for (final entry in entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SleepEntryCard(
                        entry: entry,
                        color: sleepColor,
                        onEdit: () =>
                            showAddSleepSheet(context, entry: entry),
                        onDelete: () => _deleteSleepEntry(ref, entry),
                      ),
                    ),
                const SizedBox(height: AppSpacing.lg),
              ],
              ),
            );
          },
        ),
        ),
      ],
    );
  }

  /// Deletes without asking -- the row that calls this has already
  /// confirmed, so that the swipe gesture and the menu item cannot end up
  /// with two different confirmation dialogs.
  Future<void> _deleteSleepEntry(WidgetRef ref, SleepEntry entry) async {
    await ref.read(sleepRepositoryProvider).deleteEntry(entry.id);
    // The entry list rides `watchSleepStream()` and updates itself. This
    // invalidate is for the dashboard's `getLastNightSleepHours()`, which
    // is a one-shot Future read off the watched repository provider.
    ref.invalidate(sleepRepositoryProvider);
  }
}

/// Last night / 7-night average / streak, so the page opens on "how am I
/// sleeping" rather than on a wall of rows.
class _SummaryCard extends StatelessWidget {
  final List<SleepEntry> entries;
  final int streak;
  final Color color;

  const _SummaryCard({
    required this.entries,
    required this.streak,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final completed =
        entries.where((e) => e.durationInHours != null).toList();

    final lastNight =
        completed.isEmpty ? null : completed.first.durationInHours;

    // Average over the last 7 *completed* nights rather than the last 7
    // calendar days -- a gap in logging should not read as "you slept 4h".
    final recent = completed.take(7).toList();
    final average = recent.isEmpty
        ? null
        : recent.fold<double>(0, (sum, e) => sum + e.durationInHours!) /
            recent.length;

    String hours(double? value) => value == null
        ? '--'
        : l10n.hoursShortValue(value.toStringAsFixed(1));

    return SummaryStrip(
      stats: [
        SummaryStat(
          icon: Icons.bedtime,
          label: l10n.lastNightLabel,
          value: hours(lastNight),
          color: color,
        ),
        SummaryStat(
          icon: Icons.show_chart,
          label: l10n.sleepAvgSevenNights,
          value: hours(average),
          color: color,
        ),
        SummaryStat(
          icon: Icons.local_fire_department,
          label: l10n.streakLabel,
          value: '$streak',
          color: streak > 0 ? Colors.deepOrange : color,
        ),
      ],
    );
  }
}

/// Entry point to the live timer. Shows the running session when there is
/// one, so a night in progress is visible from the history page instead of
/// only from the timer screen.
class _TimerCard extends StatelessWidget {
  final SleepEntry? active;
  final Color color;

  const _TimerCard({required this.active, required this.color});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final running = active != null;

    return IconRowTile(
      icon: running ? Icons.wb_sunny : Icons.bedtime,
      label: running ? l10n.sleepingEllipsis : l10n.sleepTimer,
      subtitle: running
          ? l10n.startedAtLabel(AppDateUtils.formatTime(active!.startedAt))
          : l10n.readyForSleepSubtitle,
      color: running ? Colors.deepOrange : color,
      onTap: () => context.push(Routes.sleepTimer),
    );
  }
}

class _SleepEntryCard extends StatelessWidget {
  final SleepEntry entry;
  final Color color;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  const _SleepEntryCard({
    required this.entry,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final duration = entry.durationInHours;

    return SwipeActionRow(
      rowKey: ValueKey(entry.id),
      deleteLabel: l10n.delete,
      confirmTitle: l10n.deleteSleep,
      confirmMessage: l10n.areYouSure,
      onDelete: onDelete,
      onEdit: onEdit,
      editLabel: l10n.edit,
      actions: [
        AppAction(
          label: l10n.edit,
          icon: CupertinoIcons.pencil,
          onPressed: onEdit,
        ),
      ],
      child: AppCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SettingsIconBadge(Icons.bedtime, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateUtils.formatDate(entry.startedAt),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.endedAt == null
                          ? '${l10n.bedtime} ${AppDateUtils.formatTime(entry.startedAt)}'
                          : '${AppDateUtils.formatTime(entry.startedAt)} → '
                              '${AppDateUtils.formatTime(entry.endedAt!)}',
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
              const SizedBox(width: AppSpacing.sm),
              _DurationChip(duration: duration, color: color),
              AppRowMenuButton(
                title: AppDateUtils.formatDate(entry.startedAt),
                tooltip: l10n.sleep,
                actions: [
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
                        title: l10n.deleteSleep,
                        message: l10n.areYouSure,
                        confirmLabel: l10n.delete,
                      );
                      if (confirmed) await onDelete();
                    },
                  ),
                ],
              ),
            ],
          ),
          if (entry.quality != null || entry.note != null) ...[
            const SizedBox(height: AppSpacing.sm),
            if (entry.quality != null)
              Row(
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      index < entry.quality! ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    // Not `entry.qualityText` -- that getter hardcodes
                    // English on the domain model.
                    qualityLabel(l10n, entry.quality!),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            if (entry.note != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                entry.note!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ],
      ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final double? duration;
  final Color color;

  const _DurationChip({required this.duration, required this.color});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inProgress = duration == null;
    final tint = inProgress ? Colors.orange : color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        inProgress
            ? l10n.inProgress
            : l10n.hoursShortValue(duration!.toStringAsFixed(1)),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// Opens the manual sleep entry form. Pass [entry] to edit an existing night.
///
/// A single entry point so the dashboard "+" sheet and the sleep page can't
/// drift into presenting the same form two different ways.
Future<void> showAddSleepSheet(BuildContext context, {SleepEntry? entry}) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => AddSleepSheet(entry: entry),
  );
}

/// Manual sleep entry form -- add a new entry or edit an existing one.
class AddSleepSheet extends HookConsumerWidget {
  final SleepEntry? entry;

  const AddSleepSheet({super.key, this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sleepColor = ref.watch(preferencesServiceProvider).sleepColor;
    final startTimeController = useTextEditingController(
      text: entry != null ? AppDateUtils.formatTime(entry!.startedAt) : '',
    );
    final endTimeController = useTextEditingController(
      text: entry?.endedAt != null
          ? AppDateUtils.formatTime(entry!.endedAt!)
          : '',
    );
    final noteController = useTextEditingController(text: entry?.note ?? '');
    final selectedDate = useState(entry?.startedAt ?? DateTime.now());
    final selectedQuality = useState<int?>(entry?.quality);
    final isLoading = useState(false);

    final isEditing = entry != null;

    return AppSheet(
      title: isEditing ? l10n.editSleepEntry : l10n.addSleepEntryTooltip,
      icon: Icons.bedtime,
      iconColor: sleepColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.date}: ${AppDateUtils.formatDate(selectedDate.value)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(l10n.change),
                onPressed: () => _selectDate(context, selectedDate),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          TextFormField(
            controller: startTimeController,
            decoration: InputDecoration(
              labelText: l10n.bedtime,
              hintText: '22:30',
              suffixIcon: const Icon(Icons.bedtime),
            ),
            onTap: () => _selectTime(context, startTimeController),
            readOnly: true,
          ),
          const SizedBox(height: AppSpacing.md),

          TextFormField(
            controller: endTimeController,
            decoration: InputDecoration(
              labelText: l10n.wakeTimeOptional,
              hintText: '07:00',
              suffixIcon: const Icon(Icons.wb_sunny),
            ),
            onTap: () => _selectTime(context, endTimeController),
            readOnly: true,
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            l10n.sleepQuality,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final rating = index + 1;
              final isSelected = (selectedQuality.value ?? 0) >= rating;
              return IconButton(
                // Tapping the selected rating clears it, matching the timer's
                // edit dialog -- otherwise a mis-tap can never be undone.
                onPressed: () => selectedQuality.value =
                    selectedQuality.value == rating ? null : rating,
                icon: Icon(
                  isSelected ? Icons.star : Icons.star_border,
                  size: 32,
                  color: Colors.amber,
                ),
              );
            }),
          ),
          if (selectedQuality.value != null)
            Center(
              child: Text(
                qualityLabel(l10n, selectedQuality.value!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: AppSpacing.md),

          TextFormField(
            controller: noteController,
            decoration: InputDecoration(
              labelText: l10n.notesOptional,
              hintText: l10n.howDidYouSleep,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.lg),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    isLoading.value ? null : () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                text: isEditing ? l10n.update : l10n.add,
                isLoading: isLoading.value,
                onPressed: isLoading.value
                    ? null
                    : () => _saveSleepEntry(
                          context,
                          ref,
                          selectedDate.value,
                          startTimeController.text,
                          endTimeController.text,
                          selectedQuality.value,
                          noteController.text,
                          isLoading,
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    ValueNotifier<DateTime> selectedDate,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null) {
      selectedDate.value = date;
    }
  }

  Future<void> _selectTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    // Seed the picker with whatever the field already holds, so re-opening it
    // to nudge a time by ten minutes doesn't reset to "now".
    final existing = AppDateUtils.parseTimeOfDay(controller.text);
    final time = await showTimePicker(
      context: context,
      initialTime: existing ?? TimeOfDay.now(),
    );
    if (time != null) {
      controller.text = '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _saveSleepEntry(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    String startTime,
    String endTime,
    int? quality,
    String note,
    ValueNotifier<bool> isLoading,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (startTime.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.pleaseEnterBedtime)));
      return;
    }

    isLoading.value = true;

    try {
      final startParts = startTime.split(':');
      final startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );

      DateTime? endDateTime;
      if (endTime.isNotEmpty) {
        final endParts = endTime.split(':');
        endDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(endParts[0]),
          int.parse(endParts[1]),
        );

        // A wake time earlier in the clock than the bedtime means the night
        // crossed midnight.
        if (!endDateTime.isAfter(startDateTime)) {
          endDateTime = DateTime(
            date.year,
            date.month,
            date.day + 1,
            int.parse(endParts[0]),
            int.parse(endParts[1]),
          );
        }
      }

      final repository = ref.read(sleepRepositoryProvider);
      if (entry != null) {
        await repository.updateEntry(
          entry!.copyWith(
            startedAt: startDateTime,
            endedAt: endDateTime,
            quality: quality,
            note: note.trim().isEmpty ? null : note.trim(),
          ),
        );
      } else {
        await repository.createEntry(
          SleepEntry.create(
            startedAt: startDateTime,
            endedAt: endDateTime,
            quality: quality,
            note: note.trim().isEmpty ? null : note.trim(),
          ),
        );
      }

      // Refreshes the dashboard's one-shot "last night" read; the entry list
      // itself updates off the sleep stream.
      ref.invalidate(sleepRepositoryProvider);

      // No `isLoading = false` on this path -- the sheet is closing, and
      // writing hook state on the way out just rebuilds a widget that is
      // about to be disposed.
      navigator.pop();
    } catch (e) {
      isLoading.value = false;
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.error}: $e')),
      );
    }
  }
}

/// Shared 1-5 wording for a sleep quality rating, so the history card, the
/// manual form and the timer's edit dialog can't label the same star count
/// differently.
String qualityLabel(AppLocalizations l10n, int quality) {
  switch (quality) {
    case 1:
      return l10n.poor;
    case 2:
      return l10n.fair;
    case 3:
      return l10n.good;
    case 4:
      return l10n.veryGood;
    case 5:
      return l10n.excellent;
    default:
      return '';
  }
}
