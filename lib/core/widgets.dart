import 'package:flutter/material.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'ios/glass.dart';
import 'theme.dart';
import 'utils.dart';
import '../services/preferences_service.dart';
import '../core/design/surfaces.dart';
import 'design/tokens.dart';

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
    this.color,
  });

  /// A tint for the whole button — a destructive red, or a section colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The spinner has to be legible on whichever fill this button ends up
    // with, and those differ: accent-tinted for primary, surface for
    // secondary.
    final spinnerColor =
        isSecondary ? (color ?? scheme.primary) : scheme.onPrimary;

    final leading = isLoading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
            ),
          )
        : (icon != null ? Icon(icon, size: 18) : null);

    return GlassButton(
      onPressed: isLoading ? null : onPressed,
      prominent: !isSecondary,
      tint: color,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 8)],
          Flexible(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  /// Corner radius, for the handful of cards that were deliberately rounder
  /// than the default 12.
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).cardTheme;
    final radius = borderRadius ?? BorderRadius.circular(12);
    // Was a `Card`. The margin and radius are read from / kept at the same
    // values the card theme used, so converting to glass changes the material
    // and nothing about the layout.
    return Padding(
      // `Card`'s own default when the theme sets none — every app theme does
      // set one, but a bare ThemeData (widget tests) does not, and inventing a
      // wider default there narrowed the content enough to overflow rows.
      padding: cardTheme.margin ?? const EdgeInsets.all(Space.xs),
      child: ContentSurface(
        borderRadius: radius,
        color: cardTheme.color,
        child: Material(
          // Transparent: the glass underneath is the surface. A Material with
          // a colour here would paint over it and the blur would be invisible.
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(AppSpacing.md),
              child: child,
            ),
          ),
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
                  style: (isCompact
                          ? theme.textTheme.bodySmall
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? AppSpacing.xs : AppSpacing.sm),
          Text(
            value,
            style: (isCompact
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.headlineMedium)
                ?.copyWith(
              color: color ?? theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: isCompact
                  ? theme.textTheme.bodySmall?.copyWith(fontSize: 10)
                  : theme.textTheme.bodySmall,
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
              ContentSurface.tinted(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 64,
                  height: 64,
                  child: Icon(
                    icon,
                    size: 32,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
            'color': prefs.getColorForMetric(NutritionMetric.calories,
                themeColor: themeColor),
          },
          {
            'key': 'protein',
            'label': useShortLabels ? l10n.proteinShort : l10n.protein,
            'value':
                '${Formatters.formatMacros(protein)}${useShortLabels ? l10n.grams : ' ${l10n.grams}'}',
            'color': prefs.getColorForMetric(NutritionMetric.protein,
                themeColor: themeColor),
          },
          {
            'key': 'carbs',
            'label': useShortLabels ? l10n.carbsShort : l10n.carbs,
            'value':
                '${Formatters.formatMacros(carbs)}${useShortLabels ? l10n.grams : ' ${l10n.grams}'}',
            'color': prefs.getColorForMetric(NutritionMetric.carbs,
                themeColor: themeColor),
          },
          {
            'key': 'fat',
            'label': useShortLabels ? l10n.fatShort : l10n.fat,
            'value':
                '${Formatters.formatMacros(fat)}${useShortLabels ? l10n.grams : ' ${l10n.grams}'}',
            'color': prefs.getColorForMetric(NutritionMetric.fat,
                themeColor: themeColor),
          },
        ];

        // Filter out the primary metric to avoid duplication
        final displayMetrics = allMetrics
            .where((metric) => metric['key'] != primaryMetric)
            .toList();

        // Calculate chip width for 3 chips instead of 4
        final chipWidth = (availableWidth / 3).clamp(88.0, 160.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayMetrics
                .map(
                  (metric) => _NutritionChip(
                    label: metric['label'] as String,
                    value: metric['value'] as String,
                    color: metric['color'] as Color,
                    isPrimary:
                        false, // None are primary since we excluded the primary metric
                    maxWidth: chipWidth,
                  ),
                )
                .toList(),
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
    return ContentSurface.tinted(
      color: isPrimary
          ? color.withValues(alpha: 0.2)
          : color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: isPrimary ? Border.all(color: color, width: 1.5) : null,
      child: Container(
        constraints: BoxConstraints(
          minWidth: 88,
          maxWidth: maxWidth,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
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

    return ContentSurface(
      padding: const EdgeInsets.all(Space.lg),
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.surface,
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
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
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
      return ContentSurface.tinted(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
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
        ),
      );
    }

    final progress = (current / goal!)
        .clamp(0.0, 2.0); // Allow up to 200% for visual feedback
    final percentage = (progress * 100).round();
    final isOverGoal = current > goal!;
    final progressColor = isOverGoal ? Colors.red : color;
    final textColor = isOverGoal ? Colors.red : color;

    return ContentSurface(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      borderRadius: BorderRadius.circular(8),
      color: theme.colorScheme.surface,
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
                  color: progressColor.withValues(alpha: 0.2),
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
                color: prefs.getColorForMetric(NutritionMetric.calories,
                    themeColor: themeColor),
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
                color: prefs.getColorForMetric(NutritionMetric.protein,
                    themeColor: themeColor),
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
                color: prefs.getColorForMetric(NutritionMetric.carbs,
                    themeColor: themeColor),
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
                color: prefs.getColorForMetric(NutritionMetric.fat,
                    themeColor: themeColor),
                useShortLabel: useShortLabels,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The rounded, tinted icon container used by settings-style list rows.
///
/// The main Settings list already used this treatment inline; secondary
/// screens (notification settings, and others) used a bare `Icon` on the
/// background instead, which reads as lower-contrast and inconsistent. Having
/// it as one widget means the two can't drift apart again.
///
/// Pass [color] to tint per-row (as the main Settings list does); it defaults
/// to the theme's primary.
class SettingsIconBadge extends StatelessWidget {
  const SettingsIconBadge(
    this.icon, {
    super.key,
    this.color,
    this.size = 24,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return ContentSurface.tinted(
      color: tint.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(Space.sm),
        child: Icon(icon, color: tint, size: size),
      ),
    );
  }
}

/// Opens a modal bottom sheet in the app's standard shape.
///
/// Every sheet in the app used to call `showModalBottomSheet` with its own
/// copy of the radius/background/scroll settings, which is how the meals
/// add-sheet ended up with a 20pt radius and a 0.3-alpha handle while the
/// dashboard's used 24pt and 0.2. Route sheets through here instead so the
/// corner radius is defined once.
///
/// [isScrollControlled] defaults to true because a sheet that hosts a text
/// field must be able to grow past the default 50% height when the keyboard
/// opens -- pair it with [AppSheet], which adds the `viewInsets` padding.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    // Respect additionalSafeAreaInsets (set by native nav bar on iOS) so a
    // tall sheet never renders behind the native chrome.
    useSafeArea: true,
    // Transparent: [AppSheet] paints the surface, as glass when glass is on.
    // A colour here would sit on top of the blur and hide it.
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: builder,
  );
}

/// Standard body for a sheet opened with [showAppSheet]: drag handle, an
/// optional badged title, then [child].
///
/// Handles the two things every sheet has to get right and half of them
/// previously didn't -- bottom inset for the keyboard, and staying scrollable
/// so a tall form doesn't overflow on a short screen.
class AppSheet extends StatelessWidget {
  final Widget child;

  /// Omit for a sheet that draws its own header (a plain list of choices).
  final String? title;
  final IconData? icon;
  final Color? iconColor;

  const AppSheet({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final header = title == null
        ? null
        : Row(
            children: [
              if (icon != null) ...[
                SettingsIconBadge(icon!, color: iconColor),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          );

    // No handle of our own: the theme sets `showDragHandle: true`, so the
    // sheet already draws one. Both were being painted, one above the other.
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) ...[header, const SizedBox(height: AppSpacing.md)],
        child,
      ],
    );

    return GlassSheet(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(child: content),
        ),
      ),
    );
  }
}

/// Title row above a list section, with an optional trailing action.
///
/// Was a private `_SectionHeader` duplicated in the workouts page; sleep and
/// meals need the same thing, so it lives here now.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ],
    );
  }
}

/// One figure in a [SummaryStrip].
class SummaryStat {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const SummaryStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Row of at-a-glance figures shown above a history list, so a page opens on
/// "how am I doing" rather than straight into raw rows.
class SummaryStrip extends StatelessWidget {
  final List<SummaryStat> stats;

  const SummaryStrip({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 34,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            Expanded(
              child: Column(
                children: [
                  Icon(stats[i].icon, size: 18, color: stats[i].color),
                  const SizedBox(height: 6),
                  Text(
                    stats[i].value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: stats[i].color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stats[i].label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Rounded, colored-icon row used across the quick-add sheets (dashboard "+"
/// and its meal/workout dialogs) so they all share one look instead of each
/// screen inventing its own tile style.
class IconRowTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;

  const IconRowTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ContentSurface.tinted(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: Space.md),
            child: Row(
              children: [
                ContentSurface.tinted(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    child: Icon(icon, color: color, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
