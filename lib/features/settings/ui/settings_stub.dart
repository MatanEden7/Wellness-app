import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../data/db/drift_database.dart';
import '../../calendar/data/calendar_service.dart';
import '../../meals/data/repositories.dart';
import '../../sleep/data/repositories.dart';
import '../../workouts/data/repositories.dart';
import '../../../services/backup_location_service.dart';
import '../../../services/export_import_service.dart';
import '../../../services/preferences_service.dart';
import '../../../services/theme_service.dart';
import '../../../services/language_service.dart';
import '../../../services/user_profile_service.dart';
import '../../../routing/routes.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_row.dart';

class SettingsStub extends ConsumerWidget {
  const SettingsStub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(preferencesServiceProvider);
    final currentTheme = ref.watch(currentThemeProvider);
    final currentLanguage = ref.watch(currentLanguageProvider);
    final profile = ref.read(userProfileServiceProvider).loadProfile();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: () => context.pop(),
          tooltip: l10n.backToDashboard,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ── Profile card ────────────────────────────────────────────────
            _ProfileCard(
              weightKg: profile?.weightKg,
              goal: profile?.goal,
              onTap: () => context.push(Routes.profile),
            ),
            const SizedBox(height: 24),

            // ── Preferences ─────────────────────────────────────────────────
            SettingsSection(
              title: l10n.preferences,
              children: [
                SettingsRow(
                  icon: Icons.local_fire_department,
                  iconColor: Colors.orange,
                  title: l10n.primaryNutritionMetric,
                  value: _nutritionMetricLabel(l10n, prefs.primaryNutritionMetric),
                  onTap: () => _showNutritionMetricDialog(context, ref),
                ),
                SettingsRow(
                  icon: Icons.calendar_today,
                  iconColor: Colors.blue,
                  title: l10n.globalTimeframe,
                  value: _timeframeModeLabel(l10n, prefs.globalTimeframeMode),
                  onTap: () => _showTimeframeModeDialog(context, ref),
                ),
                SettingsRow(
                  icon: Icons.fitness_center,
                  iconColor: Colors.green,
                  title: l10n.workoutMetricDisplay,
                  value: _workoutMetricLabel(l10n, prefs.workoutMetricMode),
                  onTap: () => _showWorkoutMetricDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Appearance ──────────────────────────────────────────────────
            SettingsSection(
              title: l10n.appearance,
              children: [
                SettingsRow(
                  icon: Icons.palette,
                  iconColor: Colors.purple,
                  title: l10n.theme,
                  value: _themeLabel(l10n, currentTheme),
                  onTap: () => context.push(Routes.themePage),
                ),
                SettingsRow(
                  icon: Icons.color_lens,
                  iconColor: Colors.pink,
                  title: l10n.appearance,
                  subtitle: currentTheme == AppThemeKind.custom
                      ? l10n.customizeThemeAndColors
                      : l10n.customizeSectionColors,
                  onTap: () => context.push(Routes.appearanceEditor),
                ),
                SettingsRow(
                  icon: Icons.language,
                  iconColor: Colors.teal,
                  title: l10n.language,
                  value: currentLanguage.displayName,
                  onTap: () => context.push(Routes.languagePage),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Health ──────────────────────────────────────────────────────
            SettingsSection(
              title: 'Health',
              children: [
                SettingsRow(
                  icon: Icons.notifications,
                  iconColor: Colors.amber,
                  title: l10n.notifications,
                  onTap: () => context.push(Routes.notificationSettings),
                ),
                SettingsRow(
                  icon: Icons.track_changes,
                  iconColor: Colors.red,
                  title: l10n.nutritionGoals,
                  value: _nutritionGoalsSummary(prefs),
                  onTap: () => context.push(Routes.nutritionGoals),
                ),
                SettingsRow(
                  icon: Icons.sports_gymnastics,
                  iconColor: Colors.indigo,
                  title: l10n.workoutTemplates,
                  onTap: () => context.push(Routes.workoutSettings),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Data ────────────────────────────────────────────────────────
            SettingsSection(
              title: l10n.dataManagement,
              children: [
                SettingsRow(
                  icon: Icons.file_download,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: l10n.exportData,
                  subtitle: l10n.exportDataDescription,
                  onTap: () => _exportData(context, ref),
                ),
                SettingsRow(
                  icon: Icons.file_upload,
                  iconColor: Theme.of(context).colorScheme.secondary,
                  title: l10n.importData,
                  subtitle: l10n.importDataDescription,
                  onTap: () => _importData(context, ref),
                ),
                _CloudBackupTile(),
                SettingsRow(
                  icon: Icons.auto_delete,
                  iconColor: Colors.orange,
                  title: l10n.deleteOldData,
                  subtitle: l10n.deleteOldDataDescription,
                  onTap: () => _showDeleteOldDataDialog(context, ref),
                ),
                SettingsRow(
                  icon: Icons.delete_forever,
                  iconColor: Colors.red,
                  title: l10n.resetAllData,
                  onTap: () => _showResetDialog(context, ref),
                  destructive: true,
                  showChevron: false,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── About ───────────────────────────────────────────────────────
            SettingsSection(
              title: l10n.about,
              children: [
                SettingsRow(
                  icon: Icons.info_outline,
                  iconColor: Colors.cyan,
                  title: l10n.appVersion,
                  value: '1.0.0',
                  showChevron: false,
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Simple one-field dialogs (kept inline because single-select) ──────────

  Future<void> _showNutritionMetricDialog(
      BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(preferencesServiceProvider).primaryNutritionMetric;
    final result = await showDialog<NutritionMetric>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.primaryNutritionMetric),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: NutritionMetric.values
              .map((m) => RadioListTile<NutritionMetric>(
                    title: Text(_nutritionMetricLabel(l10n, m)),
                    value: m,
                    groupValue: current,
                    onChanged: (v) => Navigator.of(ctx).pop(v),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel)),
        ],
      ),
    );
    if (result != null) {
      await ref.read(preferencesServiceProvider).setPrimaryNutritionMetric(result);
      ref.invalidate(preferencesServiceProvider);
    }
  }

  Future<void> _showTimeframeModeDialog(
      BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(preferencesServiceProvider).globalTimeframeMode;
    final result = await showDialog<TimeframeMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.globalTimeframe),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TimeframeMode.values
              .map((m) => RadioListTile<TimeframeMode>(
                    title: Text(_timeframeModeLabel(l10n, m)),
                    value: m,
                    groupValue: current,
                    onChanged: (v) => Navigator.of(ctx).pop(v),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel)),
        ],
      ),
    );
    if (result != null) {
      await ref.read(preferencesServiceProvider).setGlobalTimeframeMode(result);
      ref.invalidate(preferencesServiceProvider);
    }
  }

  Future<void> _showWorkoutMetricDialog(
      BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(preferencesServiceProvider).workoutMetricMode;
    final result = await showDialog<WorkoutMetricMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.workoutMetricDisplay),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: WorkoutMetricMode.values
              .map((m) => RadioListTile<WorkoutMetricMode>(
                    title: Text(_workoutMetricLabel(l10n, m)),
                    value: m,
                    groupValue: current,
                    onChanged: (v) => Navigator.of(ctx).pop(v),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel)),
        ],
      ),
    );
    if (result != null) {
      await ref.read(preferencesServiceProvider).setWorkoutMetricMode(result);
      ref.invalidate(preferencesServiceProvider);
    }
  }

  // ── Data operations ───────────────────────────────────────────────────────

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    // Anchor for the iPad share popover. UIKit needs a non-nil source rect to
    // present a popover from; without one the share sheet throws on iPad
    // ("UIPopoverPresentationController should have a non-nil sourceView...").
    // This app ships for iPhone *and* iPad (TARGETED_DEVICE_FAMILY = "1,2"),
    // so it is a real crash, not a theoretical one. Ignored on iPhone, where
    // the sheet slides up from the bottom regardless.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    try {
      final file = await ref.read(exportImportServiceProvider).exportToFile();
      // Previously the export sat in the app's Documents directory with just
      // a SnackBar showing the path -- unreachable by the user on iOS. The
      // share sheet lets them actually save it to Files, AirDrop it, etc.
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: l10n.exportData,
        sharePositionOrigin: origin,
      );
      if (context.mounted && result.status == ShareResultStatus.dismissed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.exportData}: ${file.path}'),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.exportFailed}: $e')));
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final textCtrl = TextEditingController();
    final json = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importData),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.pasteJsonExportLabel,
                  style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: '{"version": "1.0.0", ...}',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['json'],
                withData: true,
              );
              final bytes = result?.files.single.bytes;
              if (bytes != null && ctx.mounted) {
                Navigator.of(ctx).pop(utf8.decode(bytes));
              }
            },
            child: Text(l10n.chooseFile),
          ),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(textCtrl.text),
              child: Text(l10n.import)),
        ],
      ),
    );
    textCtrl.dispose();

    if (json == null || json.isEmpty || !context.mounted) return;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      await ref.read(exportImportServiceProvider).importFromJson(json);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.importData} successful!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _showDeleteOldDataDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.deleteOldData),
        children: [
          for (final option in const [90, 180, 365])
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(option),
              child: Text(l10n.olderThanNDays(option)),
            ),
        ],
      ),
    );
    if (days == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteOldData),
        content: Text(l10n.deleteOldDataConfirmation(days)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteOldData,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final cutoff = DateTime.now().subtract(Duration(days: days));
    var removed = await ref.read(databaseProvider).deleteDataOlderThan(cutoff);
    removed += await ref.read(calendarServiceProvider).deleteEventsOlderThan(cutoff);
    ref.invalidate(mealsRepositoryProvider);
    ref.invalidate(workoutSessionsRepositoryProvider);
    ref.invalidate(sleepRepositoryProvider);
    await ref.read(calendarStateProvider.notifier).refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.deleteOldDataResult(removed)),
      ));
    }
  }

  Future<void> _showResetDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resetAllData),
        content: Text(l10n.resetDataWarningBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.resetAllData,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(databaseProvider).clearAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.resetAllDataDone)));
      }
    }
  }

  // ── Label helpers ─────────────────────────────────────────────────────────

  String _nutritionMetricLabel(AppLocalizations l10n, NutritionMetric m) {
    switch (m) {
      case NutritionMetric.calories:
        return l10n.calories;
      case NutritionMetric.protein:
        return l10n.protein;
      case NutritionMetric.carbs:
        return l10n.carbs;
      case NutritionMetric.fat:
        return l10n.fat;
    }
  }

  String _timeframeModeLabel(AppLocalizations l10n, TimeframeMode m) {
    switch (m) {
      case TimeframeMode.day:
        return l10n.day;
      case TimeframeMode.week:
        return l10n.week;
    }
  }

  String _workoutMetricLabel(AppLocalizations l10n, WorkoutMetricMode m) {
    switch (m) {
      case WorkoutMetricMode.count:
        return l10n.workoutCount;
      case WorkoutMetricMode.time:
        return l10n.timeSpent;
    }
  }

  String _themeLabel(AppLocalizations l10n, AppThemeKind t) {
    switch (t) {
      case AppThemeKind.light:
        return l10n.light;
      case AppThemeKind.dark:
        return l10n.dark;
      case AppThemeKind.gold:
        return l10n.gold;
      case AppThemeKind.ocean:
        return 'Ocean';
      case AppThemeKind.forest:
        return 'Forest';
      case AppThemeKind.sunset:
        return 'Sunset';
      case AppThemeKind.lavender:
        return 'Lavender';
      case AppThemeKind.midnight:
        return 'Midnight';
      case AppThemeKind.custom:
        return 'Custom';
    }
  }

  String _nutritionGoalsSummary(PreferencesService prefs) {
    final set = [
      prefs.calorieGoal,
      prefs.proteinGoal,
      prefs.carbsGoal,
      prefs.fatGoal,
    ].where((g) => g != null).length;
    return set == 0 ? 'Not set' : '$set/4 goals set';
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.weightKg,
    required this.goal,
    required this.onTap,
  });

  final double? weightKg;
  final String? goal;
  final VoidCallback onTap;

  String _goalLabel(String goal) {
    switch (goal) {
      case 'fat_loss':
        return 'Fat Loss';
      case 'muscle_gain':
        return 'Muscle Gain';
      case 'maintenance':
        return 'Maintenance';
      case 'mobility_rehab':
        return 'Mobility & Rehab';
      default:
        return goal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(Icons.person,
                    size: 28, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Profile',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (weightKg != null && goal != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${weightKg!.toStringAsFixed(1)} kg  ·  ${_goalLabel(goal!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ] else
                      Text(
                        'Tap to complete setup',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cloud backup toggle ───────────────────────────────────────────────────────

class _CloudBackupTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CloudBackupTile> createState() => _CloudBackupTileState();
}

class _CloudBackupTileState extends ConsumerState<_CloudBackupTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.watch(backupLocationServiceProvider);
    final enabled = service.isCloudBackupEnabled;

    final String subtitle;
    if (!enabled) {
      subtitle = l10n.cloudBackupOffSubtitle;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      subtitle = l10n.cloudBackupOnSubtitleAndroid;
    } else {
      subtitle = l10n.cloudBackupOnSubtitle;
    }

    return SwitchListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      secondary: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          enabled ? Icons.cloud_done : Icons.cloud_off,
          color: Theme.of(context).colorScheme.tertiary,
          size: 19,
        ),
      ),
      title: Text(l10n.cloudBackup,
          style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              )),
      value: enabled,
      onChanged: _busy ? null : _onChanged,
    );
  }

  Future<void> _onChanged(bool value) async {
    setState(() => _busy = true);
    try {
      final service = ref.read(backupLocationServiceProvider);
      final newPath = await service.setCloudBackupEnabled(value);
      await ref.read(databaseProvider).useSnapshotPath(newPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                AppLocalizations.of(context)!.backupSettingUpdated)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('${AppLocalizations.of(context)!.error}: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
