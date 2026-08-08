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
import 'quick_add_meal_dialog.dart';
import '../../../services/preferences_service.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

class MealsPage extends HookConsumerWidget {
  const MealsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedDate = useState(AppDateUtils.today);
    final dateInt = AppDateUtils.dateToInt(selectedDate.value);
    
    final mealsAsync = ref.watch(mealsByDateStreamProvider(dateInt));
    final dayTotalsAsync = ref.watch(dayTotalsStreamProvider(dateInt));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.meals,
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
            icon: const Icon(Icons.restaurant_menu, size: 22),
            onPressed: () => context.push(Routes.foodCatalog),
            tooltip: l10n.foodCatalogTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark, size: 22),
            onPressed: () => context.push(Routes.mealTemplates),
            tooltip: l10n.mealTemplates,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    onPressed: () {
                      selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));
                    },
            tooltip: l10n.previous,
          ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Center(
                      child: Text(
                        AppDateUtils.formatDate(selectedDate.value),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28),
                    onPressed: () {
                      final tomorrow = selectedDate.value.add(const Duration(days: 1));
                      if (tomorrow.isBefore(AppDateUtils.today.add(const Duration(days: 1)))) {
                        selectedDate.value = tomorrow;
                      }
                    },
            tooltip: l10n.next,
          ),
                  TextButton(
                    onPressed: () {
                      selectedDate.value = AppDateUtils.today;
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.today,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // Day Totals
            StreamBuilder<DayTotals>(
              stream: dayTotalsAsync,
              builder: (context, snapshot) {
                final totals = snapshot.data;
                if (totals == null) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.dailyTotals,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, child) {
                            final prefs = ref.watch(preferencesServiceProvider);
                            return NutritionProgressGrid(
                              calories: totals.kcal,
                              protein: totals.protein,
                              carbs: totals.carbs,
                              fat: totals.fat,
                              calorieGoal: prefs.calorieGoal,
                              proteinGoal: prefs.proteinGoal,
                              carbsGoal: prefs.carbsGoal,
                              fatGoal: prefs.fatGoal,
                              useShortLabels: false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Meals List
            Expanded(
              child: StreamBuilder<List<Meal>>(
                stream: mealsAsync,
                builder: (context, snapshot) {
                  // Only show loading on initial load (no data yet)
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const LoadingIndicator();
                  }

                  final meals = snapshot.data ?? [];

                  if (meals.isEmpty) {
                    return EmptyState(
                      title: '${AppLocalizations.of(context)!.timeTo} ${AppLocalizations.of(context)!.fuelUp}',
                      subtitle: '${AppLocalizations.of(context)!.trackYourNutritionFor}${AppDateUtils.formatDate(selectedDate.value)}',
                      icon: Icons.restaurant,
                      actionText: AppLocalizations.of(context)!.logFirstMeal,
                      actionIcon: Icons.add,
                      onAction: () => _showAddMealOptions(context, ref),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      final meal = meals[index];
                      return _MealCard(
                        meal: meal,
                        onTap: () => context.push('/meals/edit/${meal.id}'),
                        onDelete: () => _deleteMeal(context, ref, meal),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMealOptions(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.logMeal),
      ),
    );
  }

  Future<void> _showAddMealOptions(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final mealsColor = ref.read(preferencesServiceProvider).mealsColor;

    void replaceWith(BuildContext sheetContext, VoidCallback open) {
      Navigator.of(sheetContext).pop();
      open();
    }

    await showAppSheet<void>(
      context: context,
      builder: (sheetContext) => AppSheet(
        title: l10n.logMeal,
        icon: Icons.restaurant,
        iconColor: mealsColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick add stays on this page; the other two navigate away.
            IconRowTile(
              icon: Icons.bolt,
              label: l10n.quickAdd,
              subtitle: l10n.quickAddMealSubtitle,
              color: mealsColor,
              onTap: () => replaceWith(
                sheetContext,
                () => showAppSheet<void>(
                  context: context,
                  builder: (_) => const QuickAddMealDialog(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            IconRowTile(
              icon: Icons.edit,
              label: l10n.logNewMeal,
              subtitle: l10n.createMealFromScratch,
              color: Theme.of(sheetContext).colorScheme.primary,
              onTap: () => replaceWith(
                sheetContext,
                () => context.push(Routes.mealEditor),
              ),
            ),
            const SizedBox(height: 10),
            IconRowTile(
              icon: Icons.bookmark,
              label: l10n.useTemplate,
              subtitle: l10n.chooseSavedMealTemplate,
              color: Theme.of(sheetContext).colorScheme.secondary,
              onTap: () => replaceWith(
                sheetContext,
                () => context.push(Routes.mealTemplates),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMeal(BuildContext context, WidgetRef ref, Meal meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMeal),
        content: Text('${AppLocalizations.of(context)!.areYouSure} "${meal.name}"?'),
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
      await ref.read(mealsRepositoryProvider).deleteMeal(meal.id);
      // Trigger refresh to update UI immediately
      ref.invalidate(mealsRepositoryProvider);
    }
  }
}

class _MealCard extends ConsumerWidget {
  final Meal meal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MealCard({
    required this.meal,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final mealsColor = ref.watch(preferencesServiceProvider).mealsColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SettingsIconBadge(Icons.restaurant, color: mealsColor, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (meal.items.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          l10n.itemsCount(meal.items.length),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  Formatters.formatCalories(meal.totalKcal),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: mealsColor,
                  ),
                ),
                Text(
                  ' ${l10n.kcal}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20),
                          const SizedBox(width: 12),
                          Text(l10n.edit),
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
                            l10n.delete,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      onTap();
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
                _MacroBadge(
                  label: l10n.proteinShort,
                  grams: meal.totalProtein,
                  color: Colors.blue,
                ),
                const SizedBox(width: 6),
                _MacroBadge(
                  label: l10n.carbsShort,
                  grams: meal.totalCarbs,
                  color: Colors.green,
                ),
                const SizedBox(width: 6),
                _MacroBadge(
                  label: l10n.fatShort,
                  grams: meal.totalFat,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroBadge extends StatelessWidget {
  final String label;
  final double grams;
  final Color color;

  const _MacroBadge({
    required this.label,
    required this.grams,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label ${Formatters.formatMacros(grams)}${l10n.grams}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
      ),
    );
  }
}
