import 'package:flutter/material.dart';

import '../../../core/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import '../../../shell/platform_page.dart';
import '../../../core/theme.dart';
import '../../../services/notification_preferences_service.dart';
import '../../../core/ios/glass.dart';
import '../../../core/design/tokens.dart';
import '../../../core/ios/pickers.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/ios/sheets.dart';
import '../../../core/ios/inset_list.dart';

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
                InsetRow(
                  title: l10n.meals,
                  subtitle: l10n.mealsNotificationDesc,
                  icon: Icons.restaurant,
                  iconColor: Colors.orange,
                  trailing: CupertinoSwitch(
                      value: prefs.mealsEnabled,
                      onChanged: (value) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .setMealsEnabled(value);
                      }),
                ),
                InsetRow(
                  title: l10n.workouts,
                  subtitle: l10n.workoutsNotificationDesc,
                  icon: Icons.fitness_center,
                  iconColor: Colors.blue,
                  trailing: CupertinoSwitch(
                      value: prefs.workoutsEnabled,
                      onChanged: (value) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .setWorkoutsEnabled(value);
                      }),
                ),
                InsetRow(
                  title: l10n.sleep,
                  subtitle: l10n.sleepNotificationDesc,
                  icon: Icons.bedtime,
                  iconColor: Colors.purple,
                  trailing: CupertinoSwitch(
                      value: prefs.sleepEnabled,
                      onChanged: (value) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .setSleepEnabled(value);
                      }),
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
                InsetRow(
                  icon: Icons.hotel,
                  iconColor: Colors.indigo,
                  title: l10n.sleepGoal,
                  subtitle:
                      '${prefs.sleepGoalHours.toStringAsFixed(1)} ${l10n.hours}',
                  onTap: () =>
                      _showSleepGoalDialog(context, ref, prefs.sleepGoalHours),
                ),
                InsetRow(
                  icon: Icons.alarm,
                  iconColor: Colors.teal,
                  title: l10n.sleepLogReminder,
                  subtitle: l10n.sleepLogReminderDesc(
                    TimeOfDay(
                            hour: prefs.sleepReminderHour,
                            minute: prefs.sleepReminderMinute)
                        .format(context),
                  ),
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
                InsetRow(
                  title: l10n.quietHours,
                  subtitle: l10n.quietHoursDesc,
                  icon: Icons.do_not_disturb,
                  iconColor: Colors.redAccent,
                  trailing: CupertinoSwitch(
                      value: prefs.quietHoursEnabled,
                      onChanged: (value) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .setQuietHoursEnabled(value);
                      }),
                ),
                if (prefs.quietHoursEnabled) ...[
                  InsetRow(
                    icon: Icons.bedtime,
                    iconColor: Colors.purple,
                    title: l10n.startTime,
                    subtitle: TimeOfDay(
                            hour: prefs.quietHoursStartHour,
                            minute: prefs.quietHoursStartMinute)
                        .format(context),
                    onTap: () => _showQuietHoursStartDialog(
                      context,
                      ref,
                      TimeOfDay(
                          hour: prefs.quietHoursStartHour,
                          minute: prefs.quietHoursStartMinute),
                    ),
                  ),
                  InsetRow(
                    icon: Icons.wb_sunny,
                    iconColor: Colors.amber,
                    title: l10n.endTime,
                    subtitle: TimeOfDay(
                            hour: prefs.quietHoursEndHour,
                            minute: prefs.quietHoursEndMinute)
                        .format(context),
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
                InsetRow(
                  title: l10n.sound,
                  subtitle: l10n.soundDesc,
                  icon: Icons.volume_up,
                  iconColor: Colors.green,
                  trailing: CupertinoSwitch(
                      value: prefs.soundEnabled,
                      onChanged: (value) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .setSoundEnabled(value);
                      }),
                ),
                InsetRow(
                  title: l10n.vibration,
                  subtitle: l10n.vibrationDesc,
                  icon: Icons.vibration,
                  iconColor: Colors.blueGrey,
                  trailing: CupertinoSwitch(
                      value: prefs.vibrationEnabled,
                      onChanged: (value) {
                        ref
                            .read(notificationPreferencesProvider.notifier)
                            .setVibrationEnabled(value);
                      }),
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

    // A Material `Slider` in a Material `AlertDialog`: the thumb, the track and
    // the value balloon are all Material Design components. iOS uses the
    // `CupertinoSlider` in a bottom sheet, which is what this is now.
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setState) => GlassSheet(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                Space.xl, Space.md, Space.xl, Space.xl),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(l10n.cancel),
                      ),
                      Text(l10n.sleepGoal,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          ref
                              .read(notificationPreferencesProvider.notifier)
                              .setSleepGoalHours(selectedHours);
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text(l10n.save,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.md),
                  Text(
                    '${selectedHours.toStringAsFixed(1)} ${l10n.hours}',
                    style: Theme.of(sheetContext).textTheme.headlineMedium,
                  ),
                  CupertinoSlider(
                    value: selectedHours,
                    min: 4,
                    max: 12,
                    divisions: 40,
                    onChanged: (value) => setState(() => selectedHours = value),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSleepReminderTimeDialog(
      BuildContext context, WidgetRef ref, TimeOfDay currentTime) async {
    final picked = await showAppTimePicker(
      context: context,
      initial: currentTime,
    );

    if (picked != null) {
      ref
          .read(notificationPreferencesProvider.notifier)
          .setSleepReminderTime(picked.hour, picked.minute);
    }
  }

  void _showQuietHoursStartDialog(
      BuildContext context, WidgetRef ref, TimeOfDay currentTime) async {
    final picked = await showAppTimePicker(
      context: context,
      initial: currentTime,
    );

    if (picked != null) {
      ref
          .read(notificationPreferencesProvider.notifier)
          .setQuietHoursStart(picked.hour, picked.minute);
    }
  }

  void _showQuietHoursEndDialog(
      BuildContext context, WidgetRef ref, TimeOfDay currentTime) async {
    final picked = await showAppTimePicker(
      context: context,
      initial: currentTime,
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

    return InsetRow(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: _getLeadTimeLabel(value, l10n),
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

    final picked = await showAppPicker<int>(
      context: context,
      title: l10n.reminderTiming,
      options: options,
      current: currentValue,
      labelOf: (minutes) => _getLeadTimeLabel(minutes, l10n),
    );
    if (picked != null) onChanged(picked);
  }
}
