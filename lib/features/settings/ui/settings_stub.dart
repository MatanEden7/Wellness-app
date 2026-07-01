import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../routing/routes.dart';
import '../../../services/export_import_service.dart';
import '../../../services/preferences_service.dart';
import '../../../services/theme_service.dart';
import '../../../services/language_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsStub extends ConsumerWidget {
  const SettingsStub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: () => context.pop(),
          tooltip: AppLocalizations.of(context)!.backToDashboard,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Data Management Section
            Text(
              AppLocalizations.of(context)!.dataManagement,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.file_download,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.exportData,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.exportDataDescription,
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    onTap: () => _exportData(context, ref),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.file_upload,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.importData,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.importDataDescription,
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    onTap: () => _importData(context, ref),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          
            // Future Settings Placeholder
            Text(
              AppLocalizations.of(context)!.preferences,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.primaryNutritionMetric,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _getNutritionMetricLabel(context, 
                        ref.watch(preferencesServiceProvider).primaryNutritionMetric),
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    onTap: () => _showNutritionMetricDialog(context, ref),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  _buildSettingsTile(
                    context,
                    icon: Icons.calendar_today,
                    iconColor: Colors.blue,
                    title: AppLocalizations.of(context)!.globalTimeframe,
                    subtitle: _getTimeframeModeLabel(context,
                      ref.watch(preferencesServiceProvider).globalTimeframeMode),
                    onTap: () => _showTimeframeModeDialog(context, ref),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  _buildSettingsTile(
                    context,
                    icon: Icons.fitness_center,
                    iconColor: Colors.green,
                    title: AppLocalizations.of(context)!.workoutMetricDisplay,
                    subtitle: _getWorkoutMetricLabel(context,
                      ref.watch(preferencesServiceProvider).workoutMetricMode),
                    onTap: () => _showWorkoutMetricDialog(context, ref),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  _buildSettingsTile(
                    context,
                    icon: Icons.palette,
                    iconColor: Colors.purple,
                    title: AppLocalizations.of(context)!.theme,
                    subtitle: _getThemeLabel(context, ref.watch(currentThemeProvider)),
                    onTap: () => _showThemeDialog(context, ref),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  _buildSettingsTile(
                    context,
                    icon: Icons.color_lens,
                    iconColor: Colors.pink,
                    title: 'Appearance & Colors',
                    subtitle: ref.watch(currentThemeProvider) == AppThemeKind.custom
                        ? 'Customize theme and section colors'
                        : 'Customize section colors',
                    onTap: () => context.push('/settings/appearance'),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  _buildSettingsTile(
                    context,
                    icon: Icons.language,
                    iconColor: Colors.teal,
                    title: AppLocalizations.of(context)!.language,
                    subtitle: _getLanguageLabel(ref.watch(currentLanguageProvider)),
                    onTap: () => _showLanguageDialog(context, ref),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  _buildSettingsTile(
                    context,
                    icon: Icons.notifications,
                    iconColor: Colors.amber,
                    title: AppLocalizations.of(context)!.notifications,
                    subtitle: 'Manage notification preferences',
                    onTap: () => context.push('/settings/notifications'),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  _buildSettingsTile(
                    context,
                    icon: Icons.track_changes,
                    iconColor: Colors.red,
                    title: AppLocalizations.of(context)!.nutritionGoals,
                    subtitle: _getNutritionGoalsSubtitle(context, ref),
                    onTap: () => _showNutritionGoalsDialog(context, ref),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  _buildSettingsTile(
                    context,
                    icon: Icons.scale,
                    iconColor: Colors.indigo,
                    title: AppLocalizations.of(context)!.weightUnit,
                    subtitle: AppLocalizations.of(context)!.kilograms,
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          
            // About Section
            Text(
              AppLocalizations.of(context)!.about,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            AppCard(
              child: Column(
                children: [
                  _buildSettingsTile(
                    context,
                    icon: Icons.info,
                    iconColor: Colors.cyan,
                    title: l10n.appVersion,
                    subtitle: '1.0.0',
                    showTrailing: false,
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  _buildSettingsTile(
                    context,
                    icon: Icons.description,
                    iconColor: Colors.blueGrey,
                    title: AppLocalizations.of(context)!.privacyPolicy,
                    onTap: () => _showComingSoon(context),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  _buildSettingsTile(
                    context,
                    icon: Icons.help,
                    iconColor: Colors.lightBlue,
                    title: AppLocalizations.of(context)!.helpSupport,
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool showTrailing = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 14),
            )
          : null,
      trailing: showTrailing
          ? Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            )
          : null,
      onTap: onTap,
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final exportService = ref.read(exportImportServiceProvider);
      final file = await exportService.exportToFile();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.exportData}: ${file.path}'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.exportFailed}: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final textController = TextEditingController();
    
    final jsonData = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.importData),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste your JSON export data below:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
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
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(textController.text),
            child: Text(AppLocalizations.of(context)!.import),
          ),
        ],
      ),
    );

    if (jsonData != null && jsonData.isNotEmpty && context.mounted) {
      try {
        final importService = ref.read(exportImportServiceProvider);
        
        // Show loading indicator
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        await importService.importFromJson(jsonData);

        // Close loading indicator
        if (context.mounted) {
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.importData} successful!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Close loading indicator if showing
        if (context.mounted) {
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    
    textController.dispose();
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.featureComingSoon),
      ),
    );
  }

  Future<void> _showNutritionMetricDialog(BuildContext context, WidgetRef ref) async {
    final currentMetric = ref.read(preferencesServiceProvider).primaryNutritionMetric;
    final result = await showDialog<NutritionMetric>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.primaryNutritionMetric),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: NutritionMetric.values.map((metric) => 
            RadioListTile<NutritionMetric>(
              title: Text(_getNutritionMetricLabel(context, metric)),
              value: metric,
              groupValue: currentMetric,
              onChanged: (value) => Navigator.of(context).pop(value),
            ),
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(preferencesServiceProvider).setPrimaryNutritionMetric(result);
      if (context.mounted) {
        // Force rebuild by invalidating the provider
        ref.invalidate(preferencesServiceProvider);
      }
    }
  }

  Future<void> _showTimeframeModeDialog(BuildContext context, WidgetRef ref) async {
    final currentMode = ref.read(preferencesServiceProvider).globalTimeframeMode;
    final result = await showDialog<TimeframeMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.globalTimeframe),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TimeframeMode.values.map((mode) => 
            RadioListTile<TimeframeMode>(
              title: Text(_getTimeframeModeLabel(context, mode)),
              value: mode,
              groupValue: currentMode,
              onChanged: (value) => Navigator.of(context).pop(value),
            ),
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(preferencesServiceProvider).setGlobalTimeframeMode(result);
      if (context.mounted) {
        ref.invalidate(preferencesServiceProvider);
      }
    }
  }

  Future<void> _showWorkoutMetricDialog(BuildContext context, WidgetRef ref) async {
    final currentMode = ref.read(preferencesServiceProvider).workoutMetricMode;
    final result = await showDialog<WorkoutMetricMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.workoutMetricDisplay),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: WorkoutMetricMode.values.map((mode) => 
            RadioListTile<WorkoutMetricMode>(
              title: Text(_getWorkoutMetricLabel(context, mode)),
              subtitle: Text(mode == WorkoutMetricMode.count 
                  ? AppLocalizations.of(context)!.workoutCount
                  : AppLocalizations.of(context)!.timeSpent),
              value: mode,
              groupValue: currentMode,
              onChanged: (value) => Navigator.of(context).pop(value),
            ),
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(preferencesServiceProvider).setWorkoutMetricMode(result);
      if (context.mounted) {
        ref.invalidate(preferencesServiceProvider);
      }
    }
  }

  Future<void> _showThemeDialog(BuildContext context, WidgetRef ref) async {
    final currentTheme = ref.read(currentThemeProvider);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                AppLocalizations.of(context)!.chooseTheme,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            // Theme list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: AppThemeKind.values.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final theme = AppThemeKind.values[index];
                  final isSelected = theme == currentTheme;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: isSelected ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected 
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getThemePreviewColor(theme),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      title: Text(
                        _getThemeLabel(context, theme),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(_getThemeDescription(context, theme)),
                      trailing: isSelected 
                        ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                        : null,
                      onTap: () async {
                        await ref.read(currentThemeProvider.notifier).setTheme(theme);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getThemePreviewColor(AppThemeKind theme) {
    switch (theme) {
      case AppThemeKind.light:
        return Colors.white;
      case AppThemeKind.dark:
        return Colors.black;
      case AppThemeKind.gold:
        return const Color(0xFFFFD700);
      case AppThemeKind.ocean:
        return const Color(0xFF0EA5E9);
      case AppThemeKind.forest:
        return const Color(0xFF10B981);
      case AppThemeKind.sunset:
        return const Color(0xFFFF6B35);
      case AppThemeKind.lavender:
        return const Color(0xFF9333EA);
      case AppThemeKind.midnight:
        return const Color(0xFF60A5FA);
      case AppThemeKind.custom:
        return Colors.deepPurple; // Gradient/custom icon
    }
  }

  String _getThemeLabel(BuildContext context, AppThemeKind theme) {
    switch (theme) {
      case AppThemeKind.light:
        return AppLocalizations.of(context)!.light;
      case AppThemeKind.dark:
        return AppLocalizations.of(context)!.dark;
      case AppThemeKind.gold:
        return AppLocalizations.of(context)!.gold;
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

  String _getThemeDescription(BuildContext context, AppThemeKind theme) {
    switch (theme) {
      case AppThemeKind.light:
        return AppLocalizations.of(context)!.cleanAndBright;
      case AppThemeKind.dark:
        return AppLocalizations.of(context)!.easyOnEyes;
      case AppThemeKind.gold:
        return AppLocalizations.of(context)!.luxuryGold;
      case AppThemeKind.ocean:
        return 'Calming blues & teals';
      case AppThemeKind.forest:
        return 'Natural & balanced greens';
      case AppThemeKind.sunset:
        return 'Warm & energetic';
      case AppThemeKind.lavender:
        return 'Mindful & creative';
      case AppThemeKind.midnight:
        return 'Sophisticated dark blue';
      case AppThemeKind.custom:
        return 'Customize your own colors';
    }
  }

  // Language helper methods
  String _getLanguageLabel(AppLanguage language) {
    return language.displayName;
  }

  String _getLanguageDescription(BuildContext context, AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return AppLocalizations.of(context)!.leftToRight;
      case AppLanguage.hebrew:
        return AppLocalizations.of(context)!.rightToLeft;
    }
  }

  Future<void> _showLanguageDialog(BuildContext context, WidgetRef ref) async {
    final currentLanguage = ref.read(currentLanguageProvider);
    final result = await showDialog<AppLanguage>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.chooseLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((language) =>
            RadioListTile<AppLanguage>(
              title: Text(_getLanguageLabel(language)),
              subtitle: Text(_getLanguageDescription(context, language)),
              value: language,
              groupValue: currentLanguage,
              onChanged: (value) => Navigator.of(context).pop(value),
            ),
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(currentLanguageProvider.notifier).setLanguage(result);
    }
  }

  // Localized helper methods
  String _getNutritionMetricLabel(BuildContext context, NutritionMetric metric) {
    final l10n = AppLocalizations.of(context)!;
    switch (metric) {
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

  String _getTimeframeModeLabel(BuildContext context, TimeframeMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case TimeframeMode.day:
        return l10n.day;
      case TimeframeMode.week:
        return l10n.week;
    }
  }

  String _getWorkoutMetricLabel(BuildContext context, WorkoutMetricMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case WorkoutMetricMode.count:
        return l10n.workoutCount;
      case WorkoutMetricMode.time:
        return l10n.timeSpent;
    }
  }

  String _getNutritionGoalsSubtitle(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    
    final goals = [
      prefs.calorieGoal != null,
      prefs.proteinGoal != null,
      prefs.carbsGoal != null,
      prefs.fatGoal != null,
    ];
    
    final setGoals = goals.where((set) => set).length;
    if (setGoals == 0) {
      return l10n.notSet;
    } else {
      return '$setGoals/4 ${l10n.nutritionGoals.toLowerCase()}';
    }
  }

  Future<void> _showNutritionGoalsDialog(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(preferencesServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    
    // Controllers for each goal
    final calorieController = TextEditingController(
      text: prefs.calorieGoal?.toInt().toString() ?? '',
    );
    final proteinController = TextEditingController(
      text: prefs.proteinGoal?.toInt().toString() ?? '',
    );
    final carbsController = TextEditingController(
      text: prefs.carbsGoal?.toInt().toString() ?? '',
    );
    final fatController = TextEditingController(
      text: prefs.fatGoal?.toInt().toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.nutritionGoals),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Calorie Goal
              TextFormField(
                controller: calorieController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.left, // Keep numbers LTR
                decoration: InputDecoration(
                  labelText: l10n.calorieGoal,
                  suffixText: l10n.kcal,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Protein Goal
              TextFormField(
                controller: proteinController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.left, // Keep numbers LTR
                decoration: InputDecoration(
                  labelText: l10n.proteinGoal,
                  suffixText: l10n.grams,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Carbs Goal
              TextFormField(
                controller: carbsController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.left, // Keep numbers LTR
                decoration: InputDecoration(
                  labelText: l10n.carbsGoal,
                  suffixText: l10n.grams,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Fat Goal
              TextFormField(
                controller: fatController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.left, // Keep numbers LTR
                decoration: InputDecoration(
                  labelText: l10n.fatGoal,
                  suffixText: l10n.grams,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              // Validate and save goals
              bool hasError = false;
              
              // Validate calorie goal
              if (calorieController.text.isNotEmpty) {
                final calories = double.tryParse(calorieController.text);
                if (calories == null || !prefs.isValidCalorieGoal(calories)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.calories}: 800-20000')),
                  );
                  hasError = true;
                }
              }
              
              // Validate macro goals
              for (final entry in [
                {'controller': proteinController, 'name': l10n.protein},
                {'controller': carbsController, 'name': l10n.carbs},
                {'controller': fatController, 'name': l10n.fat},
              ]) {
                final controller = entry['controller'] as TextEditingController;
                if (controller.text.isNotEmpty) {
                  final value = double.tryParse(controller.text);
                  if (value == null || !prefs.isValidMacroGoal(value)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${entry['name']}: 10-600 ${l10n.grams}')),
                    );
                    hasError = true;
                  }
                }
              }
              
              if (!hasError) {
                // Save goals
                await prefs.setCalorieGoal(
                  calorieController.text.isEmpty ? null : double.tryParse(calorieController.text),
                );
                await prefs.setProteinGoal(
                  proteinController.text.isEmpty ? null : double.tryParse(proteinController.text),
                );
                await prefs.setCarbsGoal(
                  carbsController.text.isEmpty ? null : double.tryParse(carbsController.text),
                );
                await prefs.setFatGoal(
                  fatController.text.isEmpty ? null : double.tryParse(fatController.text),
                );
                
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ref.invalidate(preferencesServiceProvider);
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _showNutritionColorsDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final prefs = ref.read(preferencesServiceProvider);
          final useTheme = prefs.useThemeColors;
          final themeColor = Theme.of(context).colorScheme.primary;
          
          return AlertDialog(
            title: const Text('Nutrition Colors'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme toggle
                  SwitchListTile(
                    title: const Text('Follow Theme'),
                    subtitle: const Text('Use theme color for all nutrition metrics'),
                    value: useTheme,
                    onChanged: (value) async {
                      await prefs.setUseThemeColors(value);
                      ref.invalidate(preferencesServiceProvider);
                      setDialogState(() {});
                    },
                  ),
                  const Divider(height: 24),
                  
                  // Show custom colors or theme preview
                  if (useTheme) ...[
                    const Text(
                      'All nutrition metrics will use this theme color:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: themeColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!, width: 2),
                        ),
                        child: Icon(
                          Icons.palette,
                          color: themeColor.computeLuminance() > 0.5 
                              ? Colors.black 
                              : Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Customize individual colors:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    _buildColorPicker(
                      context,
                      ref,
                      'Calories',
                      Icons.local_fire_department,
                      prefs.calorieColor,
                      (color) async {
                        await prefs.setCalorieColor(color);
                        ref.invalidate(preferencesServiceProvider);
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildColorPicker(
                      context,
                      ref,
                      'Protein',
                      Icons.egg,
                      prefs.proteinColor,
                      (color) async {
                        await prefs.setProteinColor(color);
                        ref.invalidate(preferencesServiceProvider);
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildColorPicker(
                      context,
                      ref,
                      'Carbs',
                      Icons.grain,
                      prefs.carbsColor,
                      (color) async {
                        await prefs.setCarbsColor(color);
                        ref.invalidate(preferencesServiceProvider);
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildColorPicker(
                      context,
                      ref,
                      'Fat',
                      Icons.water_drop,
                      prefs.fatColor,
                      (color) async {
                        await prefs.setFatColor(color);
                        ref.invalidate(preferencesServiceProvider);
                        setDialogState(() {});
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (!useTheme)
                TextButton(
                  onPressed: () async {
                    await prefs.resetColors();
                    ref.invalidate(preferencesServiceProvider);
                    setDialogState(() {});
                  },
                  child: const Text('Reset to Defaults'),
                ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showSectionColorsDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final prefs = ref.read(preferencesServiceProvider);
          
          return AlertDialog(
            title: const Text('Section Colors'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customize colors for each section:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  _buildColorPicker(
                    context,
                    ref,
                    'Meals',
                    Icons.restaurant,
                    prefs.mealsColor,
                    (color) async {
                      await prefs.setMealsColor(color);
                      ref.invalidate(preferencesServiceProvider);
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildColorPicker(
                    context,
                    ref,
                    'Workouts',
                    Icons.fitness_center,
                    prefs.workoutsColor,
                    (color) async {
                      await prefs.setWorkoutsColor(color);
                      ref.invalidate(preferencesServiceProvider);
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildColorPicker(
                    context,
                    ref,
                    'Sleep',
                    Icons.bedtime,
                    prefs.sleepColor,
                    (color) async {
                      await prefs.setSleepColor(color);
                      ref.invalidate(preferencesServiceProvider);
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await prefs.resetSectionColors();
                  ref.invalidate(preferencesServiceProvider);
                  setDialogState(() {});
                },
                child: const Text('Reset to Defaults'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColorPicker(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    Color currentColor,
    Future<void> Function(Color) onColorChanged,
  ) {
    final presetColors = [
      // Reds
      Colors.red[900]!,
      Colors.red,
      Colors.pink,
      // Purples
      Colors.deepPurple,
      Colors.purple,
      // Blues
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      // Greens
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      // Yellows/Oranges
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
    ];

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: currentColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: currentColor.computeLuminance() > 0.5 
                        ? Colors.black 
                        : Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presetColors.map((color) {
                final isSelected = color.value == currentColor.value;
                return GestureDetector(
                  onTap: () async {
                    await onColorChanged(color);
                    setState(() {
                      // Trigger rebuild to show selection
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[400]!,
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ] : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: color.computeLuminance() > 0.5 
                                ? Colors.black 
                                : Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

}
