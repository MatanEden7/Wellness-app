import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shell/platform_page.dart';
import '../../../core/ios/glass.dart';
import '../../../core/ios/sheets.dart';
import '../../../core/platform/glass_provider.dart';
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
import '../../../core/design/tokens.dart';
import '../../../core/ios/feedback.dart';
import '../../../core/ios/inset_list.dart';

class SettingsStub extends ConsumerWidget {
  const SettingsStub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(preferencesServiceProvider);
    final currentTheme = ref.watch(currentThemeProvider);
    final currentLanguage = ref.watch(currentLanguageProvider);
    final profile = ref.read(userProfileServiceProvider).loadProfile();

    return PlatformChildPage(
      chrome: PageChrome(
        title: l10n.settings,
        backTooltip: l10n.backToDashboard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                value:
                    _nutritionMetricLabel(l10n, prefs.primaryNutritionMetric),
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
                icon: Icons.blur_on,
                iconColor: Colors.blueGrey,
                title: l10n.glassEffect,
                value: _glassLabel(l10n, ref),
                onTap: () => _pickGlassLevel(context, ref),
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
              // This row said "Workout Templates" and opened Workout
              // Settings. Templates now have a screen of their own, so it
              // is two rows, each going where it says.
              SettingsRow(
                icon: Icons.sports_gymnastics,
                iconColor: Colors.indigo,
                title: l10n.workoutSettingsTitle,
                onTap: () => context.push(Routes.workoutSettings),
              ),
              SettingsRow(
                icon: Icons.list_alt,
                iconColor: Colors.indigo,
                title: l10n.workoutTemplates,
                onTap: () => context.push(Routes.workoutTemplates),
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
    );
  }

  // ── Simple one-field dialogs (kept inline because single-select) ──────────

  Future<void> _showNutritionMetricDialog(
      BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(preferencesServiceProvider).primaryNutritionMetric;
    final result = await showAppPicker<NutritionMetric>(
      context: context,
      title: l10n.primaryNutritionMetric,
      options: NutritionMetric.values,
      current: current,
      labelOf: (m) => _nutritionMetricLabel(l10n, m),
    );
    if (result != null) {
      await ref
          .read(preferencesServiceProvider)
          .setPrimaryNutritionMetric(result);
      ref.invalidate(preferencesServiceProvider);
    }
  }

  Future<void> _showTimeframeModeDialog(
      BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(preferencesServiceProvider).globalTimeframeMode;
    final result = await showAppPicker<TimeframeMode>(
      context: context,
      title: l10n.globalTimeframe,
      options: TimeframeMode.values,
      current: current,
      labelOf: (m) => _timeframeModeLabel(l10n, m),
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
    final result = await showAppPicker<WorkoutMetricMode>(
      context: context,
      title: l10n.workoutMetricDisplay,
      options: WorkoutMetricMode.values,
      current: current,
      labelOf: (m) => _workoutMetricLabel(l10n, m),
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
        showAppBanner(context, '${l10n.exportData}: ${file.path}');
      }
    } catch (e) {
      if (context.mounted) {
        showAppError(context, '${l10n.exportFailed}: $e');
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
          GlassButton(
            minHeight: Sizes.control,
            borderRadius: BorderRadius.circular(18),
            padding: const EdgeInsets.symmetric(
                horizontal: Space.md, vertical: Space.sm),
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
          GlassButton(
              minHeight: Sizes.control,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.symmetric(
                  horizontal: Space.md, vertical: Space.sm),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel)),
          GlassButton(
              minHeight: Sizes.control,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.symmetric(
                  horizontal: Space.md, vertical: Space.sm),
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
        builder: (_) =>
            const Center(child: CupertinoActivityIndicator(radius: 14)),
      );
      await ref.read(exportImportServiceProvider).importFromJson(json);
      if (context.mounted) {
        Navigator.of(context).pop();
        showAppSuccess(context, '${l10n.importData} successful!');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        showAppError(context, 'Import failed: $e');
      }
    }
  }

  Future<void> _showDeleteOldDataDialog(
      BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final days = await showAppPicker<int>(
      context: context,
      title: l10n.deleteOldData,
      options: const [90, 180, 365],
      current: null,
      labelOf: l10n.olderThanNDays,
    );
    if (days == null || !context.mounted) return;

    final confirmed = await showAppConfirm(
      context: context,
      title: l10n.deleteOldData,
      message: l10n.deleteOldDataConfirmation(days),
      confirmLabel: l10n.deleteOldData,
    );
    if (!confirmed || !context.mounted) return;

    final cutoff = DateTime.now().subtract(Duration(days: days));
    var removed = await ref.read(databaseProvider).deleteDataOlderThan(cutoff);
    removed +=
        await ref.read(calendarServiceProvider).deleteEventsOlderThan(cutoff);
    ref.invalidate(mealsRepositoryProvider);
    ref.invalidate(workoutSessionsRepositoryProvider);
    ref.invalidate(sleepRepositoryProvider);
    await ref.read(calendarStateProvider.notifier).refresh();
    if (context.mounted) {
      showAppBanner(context, l10n.deleteOldDataResult(removed));
    }
  }

  Future<void> _showResetDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirm(
      context: context,
      title: l10n.resetAllData,
      message: l10n.resetDataWarningBody,
      confirmLabel: l10n.resetAllData,
    );
    if (confirmed && context.mounted) {
      // Both halves are required. The database reset also reseeds the starter
      // catalog (a bare clearAllData left the user unable to log anything),
      // and the calendar lives in SharedPreferences, so no database call can
      // reach it -- without this the reminders survive a "reset all data",
      // every one of them pinned to a template that has just been deleted.
      await ref.read(databaseProvider).resetToFactoryState();
      await ref.read(calendarServiceProvider).clearAllEvents();
      await ref.read(calendarStateProvider.notifier).refresh();
      await ref
          .read(calendarStateProvider.notifier)
          .rescheduleAllNotifications();
      if (context.mounted) {
        showAppSuccess(context, l10n.resetAllDataDone);
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

  /// The row's right-hand value. Reports the *effective* level, not the stored
  /// one: with Reduce Transparency on, the app is opaque whatever the
  /// preference says, and a row reading "Full" over a solid app is a bug
  /// report waiting to happen.
  String _glassLabel(AppLocalizations l10n, WidgetRef ref) {
    if (ref.watch(capabilitiesProvider).reduceTransparency) {
      return l10n.glassEffectReducedByAccessibility;
    }
    return switch (ref.watch(glassLevelProvider)) {
      GlassLevel.off => l10n.glassOff,
      GlassLevel.subtle => l10n.glassSubtle,
      GlassLevel.full => l10n.glassFull,
    };
  }

  Future<void> _pickGlassLevel(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(glassLevelProvider);
    return showAppActionSheet(
      context: context,
      title: l10n.glassEffect,
      actions: [
        for (final level in GlassLevel.values)
          AppAction(
            label: switch (level) {
              GlassLevel.off => l10n.glassOff,
              GlassLevel.subtle => l10n.glassSubtle,
              GlassLevel.full => l10n.glassFull,
            },
            isDefault: level == current,
            onPressed: () =>
                ref.read(glassLevelProvider.notifier).setLevel(level),
          ),
      ],
    );
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
          padding: const EdgeInsets.symmetric(
              horizontal: Space.lg, vertical: Space.md),
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
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
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

    // An InsetRow, not a ListTile: ListTile resolves its own colours and ink
    // against the nearest Material ancestor, and inside a glass section there
    // isn't one -- which is the assertion the settings smoke test was hitting.
    return InsetRow(
      icon: enabled ? Icons.cloud_done : Icons.cloud_off,
      iconColor: Theme.of(context).colorScheme.tertiary,
      title: l10n.cloudBackup,
      subtitle: subtitle,
      trailing: CupertinoSwitch(
        value: enabled,
        onChanged: _busy ? null : _onChanged,
      ),
    );
  }

  Future<void> _onChanged(bool value) async {
    setState(() => _busy = true);
    try {
      final service = ref.read(backupLocationServiceProvider);
      final newPath = await service.setCloudBackupEnabled(value);
      await ref.read(databaseProvider).useSnapshotPath(newPath);
      if (mounted) {
        showAppSuccess(
            context, AppLocalizations.of(context)!.backupSettingUpdated);
      }
    } catch (e) {
      if (mounted) {
        showAppError(context, '${AppLocalizations.of(context)!.error}: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
