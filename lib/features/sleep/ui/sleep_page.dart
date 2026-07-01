import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../routing/routes.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SleepPage extends ConsumerWidget {
  const SleepPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(sleepRepositoryProvider).watchRecentEntries();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.sleep,
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
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            onPressed: () => _showAddSleepDialog(context, ref),
            tooltip: l10n.addSleepEntryTooltip,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sleep Entries
            Expanded(
              child: StreamBuilder<List<SleepEntry>>(
                stream: entriesAsync,
                builder: (context, snapshot) {
                  // Only show loading on initial load (no data yet)
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const LoadingIndicator();
                  }

                  final entries = snapshot.data ?? [];

                  if (entries.isEmpty) {
                    return EmptyState(
                      title: AppLocalizations.of(context)!.sweetDreamsAwait,
                      subtitle: AppLocalizations.of(context)!.trackSleepForInsights,
                      icon: Icons.bedtime,
                      actionText: AppLocalizations.of(context)!.startSleepTimer,
                      actionIcon: Icons.bedtime,
                      onAction: () => context.push(Routes.sleepTimer),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _SleepEntryCard(
                        entry: entry,
                        onEdit: () => _showEditSleepDialog(context, ref, entry),
                        onDelete: () => _deleteSleepEntry(context, ref, entry),
                      );
                    },
                  );
                },
              ),
            ),
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: l10n.manualEntry,
                      onPressed: () => _showAddSleepDialog(context, ref),
                      isSecondary: true,
                      icon: Icons.add,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      text: l10n.sleepTimer,
                      onPressed: () => context.push(Routes.sleepTimer),
                      icon: Icons.bedtime,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddSleepDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => const _AddSleepDialog(),
    );
  }

  Future<void> _showEditSleepDialog(BuildContext context, WidgetRef ref, SleepEntry entry) async {
    await showDialog(
      context: context,
      builder: (context) => _AddSleepDialog(entry: entry),
    );
  }

  Future<void> _deleteSleepEntry(BuildContext context, WidgetRef ref, SleepEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteSleep),
        content: Text(AppLocalizations.of(context)!.areYouSure),
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
      await ref.read(sleepRepositoryProvider).deleteEntry(entry.id);
      // Trigger refresh to update UI immediately
      ref.invalidate(sleepRepositoryProvider);
    }
  }
}

class _SleepEntryCard extends StatelessWidget {
  final SleepEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SleepEntryCard({
    required this.entry,
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
                    AppDateUtils.formatDate(entry.startedAt),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  itemBuilder: (context) => [
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
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          
          Row(
            children: [
              Icon(
                Icons.bedtime,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Bedtime: ${AppDateUtils.formatTime(entry.startedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          
          if (entry.endedAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.wb_sunny,
                  size: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Wake up: ${AppDateUtils.formatTime(entry.endedAt!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          // Duration and Quality
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (entry.durationInHours != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.durationInHours!.toStringAsFixed(1)}h',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.inProgress,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              
              if (entry.quality != null)
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < entry.quality! ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.amber,
                      );
                    }),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      entry.qualityText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
            ],
          ),

          if (entry.note != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              entry.note!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _AddSleepDialog extends HookConsumerWidget {
  final SleepEntry? entry;

  const _AddSleepDialog({this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final startTimeController = useTextEditingController(
      text: entry?.startedAt != null ? AppDateUtils.formatTime(entry!.startedAt) : '',
    );
    final endTimeController = useTextEditingController(
      text: entry?.endedAt != null ? AppDateUtils.formatTime(entry!.endedAt!) : '',
    );
    final noteController = useTextEditingController(text: entry?.note ?? '');
    final selectedDate = useState(entry?.startedAt ?? DateTime.now());
    final selectedQuality = useState<int?>(entry?.quality);
    final isLoading = useState(false);

    final isEditing = entry != null;

    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edit Sleep Entry' : l10n.addSleepEntryTooltip,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Date
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date: ${AppDateUtils.formatDate(selectedDate.value)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(AppLocalizations.of(context)!.change),
                  onPressed: () => _selectDate(context, selectedDate),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Sleep Time
            TextFormField(
              controller: startTimeController,
              decoration: InputDecoration(
                labelText: l10n.bedtime,
                hintText: '22:30',
                suffixIcon: Icon(Icons.bedtime),
              ),
              onTap: () => _selectTime(context, startTimeController),
              readOnly: true,
            ),
            const SizedBox(height: AppSpacing.md),

            // Wake Time
            TextFormField(
              controller: endTimeController,
              decoration: InputDecoration(
                labelText: l10n.wakeTimeOptional,
                hintText: '07:00',
                suffixIcon: Icon(Icons.wb_sunny),
              ),
              onTap: () => _selectTime(context, endTimeController),
              readOnly: true,
            ),
            const SizedBox(height: AppSpacing.md),

            // Quality Rating
            Text(
              'Sleep Quality',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final rating = index + 1;
                final isSelected = selectedQuality.value == rating;
                return GestureDetector(
                  onTap: () => selectedQuality.value = rating,
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
                  _getQualityText(selectedQuality.value!),
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
                hintText: 'How did you sleep?',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isLoading.value ? null : () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  text: isEditing ? 'Update' : 'Add',
                  onPressed: isLoading.value ? null : () => _saveSleepEntry(
                    context,
                    ref,
                    isEditing,
                    entry,
                    selectedDate.value,
                    startTimeController.text,
                    endTimeController.text,
                    selectedQuality.value,
                    noteController.text,
                    isLoading,
                  ),
                  isLoading: isLoading.value,
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
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null) {
      selectedDate.value = date;
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      controller.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getQualityText(int quality) {
    switch (quality) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Future<void> _saveSleepEntry(
    BuildContext context,
    WidgetRef ref,
    bool isEditing,
    SleepEntry? existingEntry,
    DateTime date,
    String startTime,
    String endTime,
    int? quality,
    String note,
    ValueNotifier<bool> isLoading,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (startTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterBedtime)),
      );
      return;
    }

    isLoading.value = true;

    try {
      final startTimeParts = startTime.split(':');
      final startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(startTimeParts[0]),
        int.parse(startTimeParts[1]),
      );

      DateTime? endDateTime;
      if (endTime.isNotEmpty) {
        final endTimeParts = endTime.split(':');
        endDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(endTimeParts[0]),
          int.parse(endTimeParts[1]),
        );
        
        // If end time is before start time, assume it's the next day
        if (endDateTime.isBefore(startDateTime)) {
          endDateTime = endDateTime.add(const Duration(days: 1));
        }
      }

      final sleepEntry = isEditing
          ? existingEntry!.copyWith(
              startedAt: startDateTime,
              endedAt: endDateTime,
              quality: quality,
              note: note.trim().isEmpty ? null : note.trim(),
            )
          : SleepEntry.create(
              startedAt: startDateTime,
              endedAt: endDateTime,
              quality: quality,
              note: note.trim().isEmpty ? null : note.trim(),
            );

      if (isEditing) {
        await ref.read(sleepRepositoryProvider).updateEntry(sleepEntry);
      } else {
        await ref.read(sleepRepositoryProvider).createEntry(sleepEntry);
      }

      // Trigger refresh to update UI immediately
      ref.invalidate(sleepRepositoryProvider);

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving sleep entry: $e')),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
