import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../routing/routes.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
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
                      onAction: () => _showAddMealOptions(context),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMealOptions(context),
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddMealOptions(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  l10n.logNewMeal,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l10n.createMealFromScratch),
                onTap: () {
                  Navigator.pop(context);
                  context.push(Routes.mealEditor);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bookmark,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                title: Text(
                  l10n.useTemplate,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l10n.chooseSavedMealTemplate),
                onTap: () {
                  Navigator.pop(context);
                  context.push(Routes.mealTemplates);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
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

class _MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MealCard({
    required this.meal,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              // Name and item count
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        meal.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (meal.items.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${meal.items.length}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Compact nutrition badges in one line
              _buildNutrientBadge(meal.totalKcal.toInt().toString(), Colors.orange),
              const SizedBox(width: 3),
              _buildNutrientBadge('${meal.totalProtein.toInt()}g', Colors.blue),
              const SizedBox(width: 3),
              _buildNutrientBadge('${meal.totalCarbs.toInt()}g', Colors.green),
              const SizedBox(width: 3),
              _buildNutrientBadge('${meal.totalFat.toInt()}g', Colors.purple),
              // Menu button
              PopupMenuButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 16),
                        const SizedBox(width: 10),
                        Text(AppLocalizations.of(context)!.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.red, size: 16),
                        const SizedBox(width: 10),
                        Text(
                          AppLocalizations.of(context)!.delete,
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
        ),
      ),
    );
  }

  Widget _buildNutrientBadge(String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}

