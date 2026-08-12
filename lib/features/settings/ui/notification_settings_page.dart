import 'package:flutter/material.dart';

import '../../../core/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import '../../../shell/platform_page.dart';
import '../../../core/theme.dart';
import '../../../services/notification_preferences_service.dart';
import '../../../core/ios/glass.dart';
import '../../../core/design/tokens.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final prefs = ref.watch(notificationPreferencesProvider);

    return PlatformChildPage(
      chrome: PageChrome(
        title: l10n.notifications,
        backTooltip: l10n.backToDashboard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Toggles
          AppCard(
            padding: EdgeInsets.zero,
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
                  secondary: const SettingsIconBadge(Icons.restaurant,
                      color: Colors.orange),
                  value: prefs.mealsEnabled,
                  onChanged: (value) {
                    ref
                        .read(notificationPreferencesProvider.notifier)
                        .setMealsEnabled(value);
                  },
                ),
                SwitchListTile(
                  title: Text(l10n.workouts),
                  subtitle: Text(l10n.workoutsNotificationDesc),
                  secondary: const SettingsIconBadge(Icons.fitness_center,
                      color: Colors.blue),
                  value: prefs.workoutsEnabled,
                  onChanged: (value) {
                    ref
                        .read(notificationPreferencesProvider.notifier)
                        .setWorkoutsEnabled(value);
                  },
                ),
                SwitchListTile(
                  title: Text(l10n.sleep),
                  subtitle: Text(l10n.sleepNotificationDesc),
                  secondary: const SettingsIconBadge(Icons.bedtime,
                      color: Colors.purple),
                  value: prefs.sleepEnabled,
                  onChanged: (value) {
                    ref
                        .read(notificationPreferencesProvider.notifier)
                        .setSleepEnabled(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Lead Time Settings
          AppCard(
            padding: EdgeInsets.zero,
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
                  iconColor: Colors.orange,
                  value: prefs.mealLeadTime,
                  onChanged: (value) {
                    ref
                        .read(notificationPreferencesProvider.notifier)
                        .setMealLeadTime(value);
                  },
                ),
                _LeadTimeSetting(
                  title: l10n.workoutReminders,
                  icon: Icons.fitness_center,
                  iconColor: Colors.blue,
                  value: prefs.workoutLeadTime,
                  onChanged: (value) {
                    ref
                        .read(notificationPreferencesProvider.notifier)
                        .setWorkoutLeadTime(value);
                  },
                ),
                _LeadTimeSetting(
                  title: l10n.sleepReminders,
                  icon: Icons.bedtime,
                  iconColor: Colors.purple,
                  value: prefs.sleepLeadTime,
                  onChanged: (value) {
                    ref
                        .read(notificationPreferencesProvider.notifier)
                        .setSleepLeadTime(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Sleep Settings
          AppCard(
            padding: EdgeInsets.zero,
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
                  leading: const SettingsIconBadge(Icons.hotel,
                      color: Colors.indigo),
                  title: Text(l10n.sleepGoal),
                  subtitle: Text(
                      '${prefs.sleepGoalHours.toStringAsFixed(1)} ${l10n.hours}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _showSleepGoalDialog(context, ref, prefs.sleepGoalHours),
                ),
                ListTile(
                  leading:
                      const SettingsIconBadge(Icons.alarm, color: Colors.teal),
                  title: Text(l10n.sleepLogReminder),
                  subtitle: Text(l10n.sleepLogReminderDesc(
                    TimeOfDay(
                            hour: prefs.sleepReminderHour,
                            minute: prefs.sleepReminderMinute)
                        .format(context),
                  )),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSleepReminderTimeDialog(
                    context,
                    ref,
                    TimeOfDay(
                        hour: prefs.sleepReminderHour,
                        minute: prefs.sleepReminderMinute),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Quiet Hours
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text(l10n.quietHours),
                  subtitle: Text(l10n.quietHoursDesc),
                  secondary: const SettingsIconBadge(Icons.do_not_disturb,
                      color: Colors.redAccent),
                  value: prefs.quietHoursEnabled,
                  onChanged: (value) {
                    ref
                        .read(notificationPreferencesProvider.notifier)
                        .setQuietHoursEnabled(value);
                  },
                ),
                if (prefs.quietHoursEnabled) ...[
                  ListTile(
                    leading: const SettingsIconBadge(Icons.bedtime,
                        color: Colors.purple),
                    title: Text(l10n.startTime),
                    subtitle: Text(
                      TimeOfDay(
                              hour: prefs.quietHoursStartHour,
                              minute: prefs.quietHoursStartMinute)
                          .format(context),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showQuietHoursStartDialog(
                      context,
                      ref,
                      TimeOfDay(
                          hour: prefs.quietHoursStartHour,
                          minute: prefs.quietHoursStartMinute),
                    ),
                  ),
                  ListTile(
                    leading: const SettingsIconBadge(Icons.wb_sunny,
                        color: Colors.amber),
                    title: Text(l10n.endTime),
                    subtitle: Text(
                      TimeOfDay(
                              hour: prefs.quietHoursEndHour,
                              minute: prefs.quietHoursEndMinute)
                          .format(context),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showQuietHoursEndDialog(
                      context,
                      ref,
                      TimeOfDay(
                          hour: prefs.quietHoursEndHour,
                          minute: prefs.quietHoursEndMinute),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Sound & Vibration
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.sound),
                  subtitle: Text(l10n.soundDesc),
                  secondary: const SettingsIconBadge(Icons.volume_up,
                      color: Colors.green),
                  value: prefs.soundEnabled,
                  onChanged: (value) {
                    ref
                        .read(notificationPreferencesProvider.notifier)
                        .setSoundEnabled(value);
                  },
                ),
                SwitchListTile(
                  title: Text(l10n.vibration),
                  subtitle: Text(l10n.vibrationDesc),
                  secondary: const SettingsIconBadge(Icons.vibration,
                      color: Colors.blueGrey),
                  value: prefs.vibrationEnabled,
                  onChanged: (value) {
                    ref
                        .read(notificationPreferencesProvider.notifier)
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

  void _showSleepGoalDialog(
      BuildContext context, WidgetRef ref, double currentHours) async {
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
            GlassButton(
              minHeight: Sizes.control,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.symmetric(
                  horizontal: Space.md, vertical: Space.sm),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            GlassButton(
              prominent: true,
              onPressed: () {
                ref
                    .read(notificationPreferencesProvider.notifier)
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

  void _showSleepReminderTimeDialog(
      BuildContext context, WidgetRef ref, TimeOfDay currentTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (picked != null) {
      ref
          .read(notificationPreferencesProvider.notifier)
          .setSleepReminderTime(picked.hour, picked.minute);
    }
  }

  void _showQuietHoursStartDialog(
      BuildContext context, WidgetRef ref, TimeOfDay currentTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (picked != null) {
      ref
          .read(notificationPreferencesProvider.notifier)
          .setQuietHoursStart(picked.hour, picked.minute);
    }
  }

  void _showQuietHoursEndDialog(
      BuildContext context, WidgetRef ref, TimeOfDay currentTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (picked != null) {
      ref
          .read(notificationPreferencesProvider.notifier)
          .setQuietHoursEnd(picked.hour, picked.minute);
    }
  }
}

class _LeadTimeSetting extends ConsumerWidget {
  final String title;
  final IconData icon;
  final int value;
  final Function(int) onChanged;
  final Color? iconColor;

  const _LeadTimeSetting({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: SettingsIconBadge(icon, color: iconColor),
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
          GlassButton(
            minHeight: Sizes.control,
            borderRadius: BorderRadius.circular(18),
            padding: const EdgeInsets.symmetric(
                horizontal: Space.md, vertical: Space.sm),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
