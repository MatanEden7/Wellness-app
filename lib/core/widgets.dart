import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'theme.dart';
import 'utils.dart';
import '../services/preferences_service.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isSecondary) {
      return TextButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
        label: Text(text),
      );
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
      label: Text(text),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final bool isCompact;

  const StatTile({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppCard(
      padding: isCompact 
        ? const EdgeInsets.all(AppSpacing.sm)
        : const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: isCompact ? 16 : 20,
                  color: color ?? theme.colorScheme.primary,
                ),
                SizedBox(width: isCompact ? AppSpacing.xs : AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: (isCompact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? AppSpacing.xs : AppSpacing.sm),
          Text(
            value,
            style: (isCompact ? theme.textTheme.headlineSmall : theme.textTheme.headlineMedium)?.copyWith(
              color: color ?? theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: isCompact ? theme.textTheme.bodySmall?.copyWith(fontSize: 10) : theme.textTheme.bodySmall,
              maxLines: isCompact ? 1 : null,
              overflow: isCompact ? TextOverflow.ellipsis : null,
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.actionText,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (actionText != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  text: actionText!,
                  onPressed: onAction,
                  icon: actionIcon ?? Icons.add,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// Unified nutrition metrics widget that handles all 4 macros with overflow protection
class NutritionMetricsRow extends ConsumerWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? primaryMetric; // Which metric to highlight
  final bool useShortLabels;
  final bool showAllMetrics;

  const NutritionMetricsRow({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.primaryMetric,
    this.useShortLabels = true,
    this.showAllMetrics = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(preferencesServiceProvider);
    final themeColor = Theme.of(context).colorScheme.primary;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 32; // Account for padding
        
        // Create list of all metrics
        final allMetrics = [
          {
            'key': 'calories',
            'label': useShortLabels ? l10n.caloriesShort : l10n.calories,
            'value': '${Formatters.formatCalories(calories)} ${l10n.kcal}',
            'color': prefs.getColorForMetric(NutritionMetric.calories, themeColor: themeColor),
          },
          {
            'key': 'protein',
            'label': useShortLabels ? l10n.proteinShort : l10n.protein,
            'value': '${Formatters.formatMacros(protein)}${useShortLabels ? l10n.grams : ' ${l10n.grams}'}',
            'color': prefs.getColorForMetric(NutritionMetric.protein, themeColor: themeColor),
          },
          {
            'key': 'carbs',
            'label': useShortLabels ? l10n.carbsShort : l10n.carbs,
            'value': '${Formatters.formatMacros(carbs)}${useShortLabels ? l10n.grams : ' ${l10n.grams}'}',
            'color': prefs.getColorForMetric(NutritionMetric.carbs, themeColor: themeColor),
          },
          {
            'key': 'fat',
            'label': useShortLabels ? l10n.fatShort : l10n.fat,
            'value': '${Formatters.formatMacros(fat)}${useShortLabels ? l10n.grams : ' ${l10n.grams}'}',
            'color': prefs.getColorForMetric(NutritionMetric.fat, themeColor: themeColor),
          },
        ];
        
        // Filter out the primary metric to avoid duplication
        final displayMetrics = allMetrics.where((metric) => metric['key'] != primaryMetric).toList();
        
        // Calculate chip width for 3 chips instead of 4
        final chipWidth = (availableWidth / 3).clamp(88.0, 160.0);
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayMetrics.map((metric) => 
              _NutritionChip(
                label: metric['label'] as String,
                value: metric['value'] as String,
                color: metric['color'] as Color,
                isPrimary: false, // None are primary since we excluded the primary metric
                maxWidth: chipWidth,
              ),
            ).toList(),
          ),
        );
      },
    );
  }
}

class _NutritionChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isPrimary;
  final double maxWidth;

  const _NutritionChip({
    required this.label,
    required this.value,
    required this.color,
    this.isPrimary = false,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: 88,
        maxWidth: maxWidth,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isPrimary 
            ? color.withOpacity(0.2)
            : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: isPrimary 
            ? Border.all(color: color, width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Primary metric card with overflow protection
class PrimaryMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color? color;

  const PrimaryMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: cardColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: cardColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: cardColor,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Nutrition progress bar widget that shows progress towards goals
class NutritionProgressBar extends StatelessWidget {
  final String label;
  final double current;
  final double? goal;
  final String unit;
  final Color color;
  final bool useShortLabel;

  const NutritionProgressBar({
    super.key,
    required this.label,
    required this.current,
    this.goal,
    required this.unit,
    required this.color,
    this.useShortLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (goal == null || goal! <= 0) {
      // No goal set - show simple current value
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label on its own line
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.visible, // Allow full text to show
            ),
            const SizedBox(height: 4),
            // Value on second line, right-aligned
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${Formatters.formatMacros(current)}$unit',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final progress = (current / goal!).clamp(0.0, 2.0); // Allow up to 200% for visual feedback
    final percentage = (progress * 100).round();
    final isOverGoal = current > goal!;
    final progressColor = isOverGoal ? Colors.red : color;
    final textColor = isOverGoal ? Colors.red : color;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with label and values
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label on its own line to ensure full visibility
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.visible, // Allow full text to show
              ),
              const SizedBox(height: 4),
              // Values on second line
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${Formatters.formatMacros(current)} / ${Formatters.formatMacros(goal!)}$unit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Progress bar
          Stack(
            children: [
              // Background
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Progress fill
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Percentage text
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$percentage%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that shows all 4 nutrition progress bars in a grid
class NutritionProgressGrid extends ConsumerWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? calorieGoal;
  final double? proteinGoal;
  final double? carbsGoal;
  final double? fatGoal;
  final bool useShortLabels;

  const NutritionProgressGrid({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.calorieGoal,
    this.proteinGoal,
    this.carbsGoal,
    this.fatGoal,
    this.useShortLabels = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(preferencesServiceProvider);
    final themeColor = Theme.of(context).colorScheme.primary;
    
    return Column(
      children: [
        // Calories and Protein row
        Row(
          children: [
            Expanded(
              child: NutritionProgressBar(
                label: useShortLabels ? l10n.caloriesShort : l10n.calories,
                current: calories,
                goal: calorieGoal,
                unit: ' ${l10n.kcal}',
                color: prefs.getColorForMetric(NutritionMetric.calories, themeColor: themeColor),
                useShortLabel: useShortLabels,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NutritionProgressBar(
                label: useShortLabels ? l10n.proteinShort : l10n.protein,
                current: protein,
                goal: proteinGoal,
                unit: useShortLabels ? l10n.grams : ' ${l10n.grams}',
                color: prefs.getColorForMetric(NutritionMetric.protein, themeColor: themeColor),
                useShortLabel: useShortLabels,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Carbs and Fat row
        Row(
          children: [
            Expanded(
              child: NutritionProgressBar(
                label: useShortLabels ? l10n.carbsShort : l10n.carbs,
                current: carbs,
                goal: carbsGoal,
                unit: useShortLabels ? l10n.grams : ' ${l10n.grams}',
                color: prefs.getColorForMetric(NutritionMetric.carbs, themeColor: themeColor),
                useShortLabel: useShortLabels,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NutritionProgressBar(
                label: useShortLabels ? l10n.fatShort : l10n.fat,
                current: fat,
                goal: fatGoal,
                unit: useShortLabels ? l10n.grams : ' ${l10n.grams}',
                color: prefs.getColorForMetric(NutritionMetric.fat, themeColor: themeColor),
                useShortLabel: useShortLabels,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
