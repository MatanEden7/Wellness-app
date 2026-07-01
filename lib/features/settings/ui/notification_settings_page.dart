import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/theme.dart';
import '../../../services/notification_preferences_service.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final prefs = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Category Toggles
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.enableNotifications,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                SwitchListTile(
                  title: Text(l10n.meals),
                  subtitle: Text(l10n.mealsNotificationDesc),
                  secondary: const Icon(Icons.restaurant),
                  value: prefs.mealsEnabled,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier)
                        .setMealsEnabled(value);
                  },
                ),
                SwitchListTile(
                  title: Text(l10n.workouts),
                  subtitle: Text(l10n.workoutsNotificationDesc),
                  secondary: const Icon(Icons.fitness_center),
                  value: prefs.workoutsEnabled,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier)
                        .setWorkoutsEnabled(value);
                  },
                ),
                SwitchListTile(
                  title: Text(l10n.sleep),
                  subtitle: Text(l10n.sleepNotificationDesc),
                  secondary: const Icon(Icons.bedtime),
                  value: prefs.sleepEnabled,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier)
                        .setSleepEnabled(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Lead Time Settings
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.reminderTiming,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                _LeadTimeSetting(
                  title: l10n.mealReminders,
                  icon: Icons.restaurant,
                  value: prefs.mealLeadTime,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier)
                        .setMealLeadTime(value);
                  },
                ),
                _LeadTimeSetting(
                  title: l10n.workoutReminders,
                  icon: Icons.fitness_center,
                  value: prefs.workoutLeadTime,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier)
                        .setWorkoutLeadTime(value);
                  },
                ),
                _LeadTimeSetting(
                  title: l10n.sleepReminders,
                  icon: Icons.bedtime,
                  value: prefs.sleepLeadTime,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier)
                        .setSleepLeadTime(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Sleep Settings
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.sleepSettings,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.hotel),
                  title: Text(l10n.sleepGoal),
                  subtitle: Text('${prefs.sleepGoalHours.toStringAsFixed(1)} ${l10n.hours}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSleepGoalDialog(context, ref, prefs.sleepGoalHours),
                ),
                ListTile(
                  leading: const Icon(Icons.alarm),
                  title: Text(l10n.sleepLogReminder),
                  subtitle: Text(l10n.sleepLogReminderDesc(
                    TimeOfDay(hour: prefs.sleepReminderHour, minute: prefs.sleepReminderMinute)
                        .format(context),
                  )),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSleepReminderTimeDialog(
                    context,
                    ref,
                    TimeOfDay(hour: prefs.sleepReminderHour, minute: prefs.sleepReminderMinute),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Quiet Hours
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text(l10n.quietHours),
                  subtitle: Text(l10n.quietHoursDesc),
                  secondary: const Icon(Icons.do_not_disturb),
                  value: prefs.quietHoursEnabled,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier)
                        .setQuietHoursEnabled(value);
                  },
                ),
                if (prefs.quietHoursEnabled) ...[
                  ListTile(
                    leading: const Icon(Icons.bedtime),
                    title: Text(l10n.startTime),
                    subtitle: Text(
                      TimeOfDay(hour: prefs.quietHoursStartHour, minute: prefs.quietHoursStartMinute)
                          .format(context),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showQuietHoursStartDialog(
                      context,
                      ref,
                      TimeOfDay(hour: prefs.quietHoursStartHour, minute: prefs.quietHoursStartMinute),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.wb_sunny),
                    title: Text(l10n.endTime),
                    subtitle: Text(
                      TimeOfDay(hour: prefs.quietHoursEndHour, minute: prefs.quietHoursEndMinute)
                          .format(context),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showQuietHoursEndDialog(
                      context,
                      ref,
                      TimeOfDay(hour: prefs.quietHoursEndHour, minute: prefs.quietHoursEndMinute),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Sound & Vibration
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.sound),
                  subtitle: Text(l10n.soundDesc),
                  secondary: const Icon(Icons.volume_up),
                  value: prefs.soundEnabled,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier)
                        .setSoundEnabled(value);
                  },
                ),
                SwitchListTile(
                  title: Text(l10n.vibration),
                  subtitle: Text(l10n.vibrationDesc),
                  secondary: const Icon(Icons.vibration),
                  value: prefs.vibrationEnabled,
                  onChanged: (value) {
                    ref.read(notificationPreferencesProvider.notifier)
                        .setVibrationEnabled(value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSleepGoalDialog(BuildContext context, WidgetRef ref, double currentHours) async {
    final l10n = AppLocalizations.of(context)!;
    double selectedHours = currentHours;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.sleepGoal),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${selectedHours.toStringAsFixed(1)} ${l10n.hours}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Slider(
                value: selectedHours,
                min: 4,
                max: 12,
                divisions: 40,
                label: selectedHours.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() => selectedHours = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                ref.read(notificationPreferencesProvider.notifier)
                    .setSleepGoalHours(selectedHours);
                Navigator.of(context).pop();
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepReminderTimeDialog(BuildContext context, WidgetRef ref, TimeOfDay currentTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    
    if (picked != null) {
      ref.read(notificationPreferencesProvider.notifier)
          .setSleepReminderTime(picked.hour, picked.minute);
    }
  }

  void _showQuietHoursStartDialog(BuildContext context, WidgetRef ref, TimeOfDay currentTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    
    if (picked != null) {
      ref.read(notificationPreferencesProvider.notifier)
          .setQuietHoursStart(picked.hour, picked.minute);
    }
  }

  void _showQuietHoursEndDialog(BuildContext context, WidgetRef ref, TimeOfDay currentTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    
    if (picked != null) {
      ref.read(notificationPreferencesProvider.notifier)
          .setQuietHoursEnd(picked.hour, picked.minute);
    }
  }
}

class _LeadTimeSetting extends ConsumerWidget {
  final String title;
  final IconData icon;
  final int value;
  final Function(int) onChanged;

  const _LeadTimeSetting({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(_getLeadTimeLabel(value, l10n)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLeadTimeDialog(context, value, onChanged, l10n),
    );
  }

  String _getLeadTimeLabel(int minutes, AppLocalizations l10n) {
    if (minutes == 0) return l10n.atTime;
    if (minutes == 5) return l10n.fiveMinBefore;
    if (minutes == 10) return l10n.tenMinBefore;
    if (minutes == 15) return l10n.fifteenMinBefore;
    if (minutes == 30) return l10n.thirtyMinBefore;
    return l10n.xMinBefore(minutes);
  }

  void _showLeadTimeDialog(
    BuildContext context,
    int currentValue,
    Function(int) onChanged,
    AppLocalizations l10n,
  ) async {
    final options = [0, 5, 10, 15, 30];
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reminderTiming),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((minutes) {
            return RadioListTile<int>(
              title: Text(_getLeadTimeLabel(minutes, l10n)),
              value: minutes,
              groupValue: currentValue,
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

