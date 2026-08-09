import 'package:flutter/material.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../services/preferences_service.dart';
import '../../../services/theme_service.dart';
import 'advanced_color_picker.dart';

class AppearanceEditorPage extends HookConsumerWidget {
  const AppearanceEditorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesServiceProvider);
    final currentTheme = ref.watch(currentThemeProvider);
    final scrollController = useScrollController();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appearance),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
            tooltip: AppLocalizations.of(context)!.backToDashboard,
          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _showResetDialog(context, ref),
            tooltip: AppLocalizations.of(context)!.resetAllColors,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currentTheme == AppThemeKind.custom
                            ? 'Customize all app colors. Changes apply immediately.'
                            : 'Customize section colors. Switch to Custom theme to edit theme colors.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Theme Colors Section (only show if custom theme is selected)
              if (currentTheme == AppThemeKind.custom) ...[
                _buildSectionHeader(context, 'Theme Colors', Icons.palette),
                const SizedBox(height: 12),
                _ColorPickerTile(
                  label: 'Primary',
                  icon: Icons.circle,
                  currentColor: prefs.customPrimaryColor,
                  onColorChanged: (color) async {
                    await prefs.setCustomPrimaryColor(color);
                    ref.invalidate(preferencesServiceProvider);
                  },
                ),
                const SizedBox(height: 8),
                _ColorPickerTile(
                  label: 'Background',
                  icon: Icons.square,
                  currentColor: prefs.customBackgroundColor,
                  onColorChanged: (color) async {
                    await prefs.setCustomBackgroundColor(color);
                    ref.invalidate(preferencesServiceProvider);
                  },
                ),
                const SizedBox(height: 8),
                _ColorPickerTile(
                  label: 'Surface',
                  icon: Icons.layers,
                  currentColor: prefs.customSurfaceColor,
                  onColorChanged: (color) async {
                    await prefs.setCustomSurfaceColor(color);
                    ref.invalidate(preferencesServiceProvider);
                  },
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    await prefs.resetThemeColors();
                    ref.invalidate(preferencesServiceProvider);
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(AppLocalizations.of(context)!.resetThemeColors),
                ),
                const SizedBox(height: 32),
              ],
              
              // Section Colors
              _buildSectionHeader(context, 'Section Colors', Icons.category),
              const SizedBox(height: 12),
              _ColorPickerTile(
                label: AppLocalizations.of(context)!.meals,
                icon: Icons.restaurant,
                currentColor: prefs.mealsColor,
                onColorChanged: (color) async {
                  await prefs.setMealsColor(color);
                  ref.invalidate(preferencesServiceProvider);
                },
              ),
              const SizedBox(height: 8),
              _ColorPickerTile(
                label: AppLocalizations.of(context)!.workouts,
                icon: Icons.fitness_center,
                currentColor: prefs.workoutsColor,
                onColorChanged: (color) async {
                  await prefs.setWorkoutsColor(color);
                  ref.invalidate(preferencesServiceProvider);
                },
              ),
              const SizedBox(height: 8),
              _ColorPickerTile(
                label: AppLocalizations.of(context)!.sleep,
                icon: Icons.bedtime,
                currentColor: prefs.sleepColor,
                onColorChanged: (color) async {
                  await prefs.setSleepColor(color);
                  ref.invalidate(preferencesServiceProvider);
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  await prefs.resetSectionColors();
                  ref.invalidate(preferencesServiceProvider);
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(AppLocalizations.of(context)!.resetSectionColors),
              ),
              
              const SizedBox(height: 32),
              
              // Nutrition Colors
              _buildSectionHeader(context, 'Nutrition Colors', Icons.local_fire_department),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.followTheme),
                subtitle: Text(AppLocalizations.of(context)!.followThemeDesc),
                value: prefs.useThemeColors,
                onChanged: (value) async {
                  await prefs.setUseThemeColors(value);
                  ref.invalidate(preferencesServiceProvider);
                },
              ),
              if (!prefs.useThemeColors) ...[
                const SizedBox(height: 8),
                _ColorPickerTile(
                  label: AppLocalizations.of(context)!.calories,
                  icon: Icons.local_fire_department,
                  currentColor: prefs.calorieColor,
                  onColorChanged: (color) async {
                    await prefs.setCalorieColor(color);
                    ref.invalidate(preferencesServiceProvider);
                  },
                ),
                const SizedBox(height: 8),
                _ColorPickerTile(
                  label: AppLocalizations.of(context)!.protein,
                  icon: Icons.egg,
                  currentColor: prefs.proteinColor,
                  onColorChanged: (color) async {
                    await prefs.setProteinColor(color);
                    ref.invalidate(preferencesServiceProvider);
                  },
                ),
                const SizedBox(height: 8),
                _ColorPickerTile(
                  label: AppLocalizations.of(context)!.carbs,
                  icon: Icons.grain,
                  currentColor: prefs.carbsColor,
                  onColorChanged: (color) async {
                    await prefs.setCarbsColor(color);
                    ref.invalidate(preferencesServiceProvider);
                  },
                ),
                const SizedBox(height: 8),
                _ColorPickerTile(
                  label: AppLocalizations.of(context)!.fat,
                  icon: Icons.water_drop,
                  currentColor: prefs.fatColor,
                  onColorChanged: (color) async {
                    await prefs.setFatColor(color);
                    ref.invalidate(preferencesServiceProvider);
                  },
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    await prefs.resetColors();
                    ref.invalidate(preferencesServiceProvider);
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(AppLocalizations.of(context)!.resetNutritionColors),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Preview Section
              _buildSectionHeader(context, 'Preview', Icons.visibility),
              const SizedBox(height: 12),
              _PreviewPanel(),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _showResetDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.resetAllColors),
        content: Text(
          AppLocalizations.of(context)!.resetColorsWarningBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.reset,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = ref.read(preferencesServiceProvider);
      await prefs.resetAllCustomColors();
      ref.invalidate(preferencesServiceProvider);
    }
  }
}

class _ColorPickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color currentColor;
  final Future<void> Function(Color) onColorChanged;

  const _ColorPickerTile({
    required this.label,
    required this.icon,
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showColorPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!, width: 2),
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
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Icon(
              Icons.edit,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showColorPicker(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedColorPicker(
        label: label,
        icon: icon,
        initialColor: currentColor,
        onColorChanged: onColorChanged,
        scope: label.toLowerCase(),
      ),
    );
  }
}

class _PreviewPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesServiceProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: prefs.customSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.preview,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Primary button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: prefs.customPrimaryColor,
                foregroundColor: prefs.customPrimaryColor.computeLuminance() > 0.5 
                    ? Colors.black 
                    : Colors.white,
              ),
              child: Text(AppLocalizations.of(context)!.primaryButton),
            ),
          ),
          const SizedBox(height: 12),
          
          // Section chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Chip(
                label: Text(AppLocalizations.of(context)!.meals),
                backgroundColor: prefs.mealsColor.withValues(alpha: 0.2),
                side: BorderSide(color: prefs.mealsColor),
              ),
              Chip(
                label: Text(AppLocalizations.of(context)!.workouts),
                backgroundColor: prefs.workoutsColor.withValues(alpha: 0.2),
                side: BorderSide(color: prefs.workoutsColor),
              ),
              Chip(
                label: Text(AppLocalizations.of(context)!.sleep),
                backgroundColor: prefs.sleepColor.withValues(alpha: 0.2),
                side: BorderSide(color: prefs.sleepColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Nutrition progress sample
          if (!prefs.useThemeColors) ...[
            _sampleProgressBar(context, 'Calories', prefs.calorieColor, 0.7),
            const SizedBox(height: 8),
            _sampleProgressBar(context, 'Protein', prefs.proteinColor, 0.85),
          ],
        ],
      ),
    );
  }

  Widget _sampleProgressBar(BuildContext context, String label, Color color, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}

