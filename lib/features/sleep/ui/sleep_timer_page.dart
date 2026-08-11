import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shell/platform_page.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../features/calendar/domain/models.dart' show EventType;
import '../../../services/notification_preferences_service.dart';
import '../../../services/notification_service.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import 'sleep_page.dart' show qualityLabel;
import 'package:wellness_app/l10n/app_localizations.dart';

class SleepTimerPage extends HookConsumerWidget {
  const SleepTimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentEntry = useState<SleepEntry?>(null);
    final isLoading = useState(false);

    // Check for active sleep session
    useEffect(() {
      _checkForActiveSleepSession(ref, currentEntry);
      return null;
    }, []);

    return PlatformNavPage(
      chrome: PageChrome(title: l10n.sleepTimer),
      body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: currentEntry.value == null
                ? _StartSleepView(
                    onStart: () => _startSleep(ref, currentEntry, isLoading),
                    isLoading: isLoading.value,
                  )
                : _ActiveSleepView(
                    entry: currentEntry.value!,
                    onStop: () => _stopSleep(context, ref, currentEntry, isLoading, l10n),
                    onEdit: () => _editSleep(context, ref, currentEntry),
                    isLoading: isLoading.value,
                  ),
          ),
      ),
    );
  }

  Future<void> _checkForActiveSleepSession(
    WidgetRef ref,
    ValueNotifier<SleepEntry?> currentEntry,
  ) async {
    // Check if there's an active sleep session (started but not ended)
    final entries = await ref.read(sleepRepositoryProvider).watchRecentEntries(limit: 1).first;
    if (entries.isNotEmpty && !entries.first.isCompleted) {
      currentEntry.value = entries.first;
    }
  }

  Future<void> _startSleep(
    WidgetRef ref,
    ValueNotifier<SleepEntry?> currentEntry,
    ValueNotifier<bool> isLoading,
  ) async {
    isLoading.value = true;
    
    try {
      final entry = SleepEntry.create();
      await ref.read(sleepRepositoryProvider).createEntry(entry);
      currentEntry.value = entry;
      HapticsHelper.mediumImpact();
    } catch (e) {
      // Handle error
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _stopSleep(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<SleepEntry?> currentEntry,
    ValueNotifier<bool> isLoading,
    AppLocalizations l10n,
  ) async {
    if (currentEntry.value == null) return;

    isLoading.value = true;

    try {
      final updatedEntry = currentEntry.value!.copyWith(
        endedAt: DateTime.now(),
      );

      await ref.read(sleepRepositoryProvider).updateEntry(updatedEntry);
      currentEntry.value = null;
      HapticsHelper.mediumImpact();

      // Trigger refresh to update UI immediately
      ref.invalidate(sleepRepositoryProvider);

      // sleepGoalHours was configurable in settings and compared against
      // nothing -- reaching it never surfaced anywhere, even though
      // NotificationService.showImmediate() exists for exactly this case.
      await _notifyIfGoalReached(ref, updatedEntry, l10n);

      // Show completion dialog
      if (context.mounted) {
        _showSleepCompletedDialog(context, updatedEntry);
      }
    } catch (e) {
      // Handle error
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _notifyIfGoalReached(
    WidgetRef ref,
    SleepEntry entry,
    AppLocalizations l10n,
  ) async {
    final hours = entry.durationInHours;
    if (hours == null) return;

    final notificationPrefs = ref.read(notificationPreferencesProvider);
    if (hours < notificationPrefs.sleepGoalHours) return;

    try {
      // No categoryId on purpose: the sleep category's buttons are "Start
      // Sleep" and "Snooze 30m", neither of which means anything on an alert
      // announcing that the sleep just finished.
      await ref.read(notificationServiceProvider).showImmediate(
            title: l10n.sleepGoalReachedTitle,
            body: l10n.sleepGoalReachedBody(hours.toStringAsFixed(1)),
            type: EventType.sleep,
            soundEnabled: notificationPrefs.soundEnabled,
            vibrationEnabled: notificationPrefs.vibrationEnabled,
          );
    } catch (e) {
      debugPrint('[SLEEP] Could not show goal-reached notification: $e');
    }
  }

  Future<void> _editSleep(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<SleepEntry?> currentEntry,
  ) async {
    if (currentEntry.value == null) return;

    final result = await showDialog<SleepEntry>(
      context: context,
      builder: (context) => _EditActiveSleepDialog(entry: currentEntry.value!),
    );

    if (result != null) {
      await ref.read(sleepRepositoryProvider).updateEntry(result);
      currentEntry.value = result;
    }
  }

  void _showSleepCompletedDialog(BuildContext context, SleepEntry entry) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
        title: Text(l10n.sleepComplete),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wb_sunny,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.youSleptForHours(
                entry.durationInHours!.toStringAsFixed(1),
              ),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.fromTimeToTime(
                AppDateUtils.formatTime(entry.startedAt),
                AppDateUtils.formatTime(entry.endedAt!),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Go back to sleep page
            },
            child: Text(l10n.done),
          ),
        ],
      );
      },
    );
  }
}

class _StartSleepView extends StatelessWidget {
  final VoidCallback onStart;
  final bool isLoading;

  const _StartSleepView({
    required this.onStart,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.bedtime,
          size: 140,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 48),
        
        Text(
          AppLocalizations.of(context)!.readyForSleep,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        Text(
          AppLocalizations.of(context)!.readyForSleepSubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 17,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        
        SizedBox(
          width: 220,
          height: 56,
          child: AppButton(
            text: l10n.startSleepAction,
            onPressed: isLoading ? null : onStart,
            isLoading: isLoading,
            icon: Icons.bedtime,
          ),
        ),
        const SizedBox(height: 32),
        
        Text(
          l10n.currentTimeLabel(AppDateUtils.formatTime(DateTime.now())),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _ActiveSleepView extends HookWidget {
  final SleepEntry entry;
  final VoidCallback onStop;
  final VoidCallback onEdit;
  final bool isLoading;

  const _ActiveSleepView({
    required this.entry,
    required this.onStop,
    required this.onEdit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Update every second to show live duration
    final currentTime = useState(DateTime.now());
    
    useEffect(() {
      final timer = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now())
          .listen((time) => currentTime.value = time);
      return timer.cancel;
    }, []);

    final duration = currentTime.value.difference(entry.startedAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.bedtime,
          size: 100,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 32),
        
        Text(
          AppLocalizations.of(context)!.sleepingEllipsis,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        // Sleep Duration
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                '${hours}h ${minutes}m',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 56,
                  letterSpacing: -1,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.sleepDuration,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Sleep Start Time
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bedtime,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.startedAtLabel(AppDateUtils.formatTime(entry.startedAt)),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        
        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: AppButton(
                text: l10n.edit,
                onPressed: isLoading ? null : onEdit,
                isSecondary: true,
                icon: Icons.edit,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 56,
                child: AppButton(
                  text: l10n.wakeUpAction,
                  onPressed: isLoading ? null : onStop,
                  isLoading: isLoading,
                  icon: Icons.wb_sunny,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        Text(
          l10n.currentTimeLabel(AppDateUtils.formatTime(currentTime.value)),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _EditActiveSleepDialog extends HookWidget {
  final SleepEntry entry;

  const _EditActiveSleepDialog({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final startTimeController = useTextEditingController(
      text: AppDateUtils.formatTime(entry.startedAt),
    );
    final noteController = useTextEditingController(text: entry.note ?? '');
    final selectedDate = useState(entry.startedAt);
    final selectedQuality = useState<int?>(entry.quality);

    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.editSleepSession,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Date
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.date}: ${AppDateUtils.formatDate(selectedDate.value)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(l10n.change),
                  onPressed: () => _selectDate(context, selectedDate),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Start Time
            TextFormField(
              controller: startTimeController,
              decoration: InputDecoration(
                labelText: l10n.sleepStartTime,
                suffixIcon: const Icon(Icons.bedtime),
              ),
              onTap: () => _selectTime(context, startTimeController),
              readOnly: true,
            ),
            const SizedBox(height: AppSpacing.md),

            // Quality Rating
            Text(
              AppLocalizations.of(context)!.sleepQualityOptional,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final rating = index + 1;
                final isSelected = selectedQuality.value == rating;
                return GestureDetector(
                  onTap: () => selectedQuality.value = isSelected ? null : rating,
                  child: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    size: 32,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            if (selectedQuality.value != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(
                  qualityLabel(l10n, selectedQuality.value!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            // Notes
            TextFormField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: l10n.notesOptional,
                hintText: l10n.howAreYouFeeling,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  text: l10n.save,
                  onPressed: () => _saveSleepEntry(
                    context,
                    selectedDate.value,
                    startTimeController.text,
                    selectedQuality.value,
                    noteController.text,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, ValueNotifier<DateTime> selectedDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      selectedDate.value = date;
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final currentTime = TimeOfDay.fromDateTime(entry.startedAt);
    final time = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    if (time != null) {
      controller.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }


  void _saveSleepEntry(
    BuildContext context,
    DateTime date,
    String startTime,
    int? quality,
    String note,
  ) {
    try {
      final startTimeParts = startTime.split(':');
      final startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(startTimeParts[0]),
        int.parse(startTimeParts[1]),
      );

      final updatedEntry = entry.copyWith(
        startedAt: startDateTime,
        quality: quality,
        note: note.trim().isEmpty ? null : note.trim(),
      );

      Navigator.of(context).pop(updatedEntry);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating sleep entry: $e')),
      );
    }
  }
}
