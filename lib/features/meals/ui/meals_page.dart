import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ios/app_scaffold.dart';
import '../../../core/ios/date_strip.dart';
import '../../../core/ios/sheets.dart';
import '../../../core/ios/shortcuts.dart';
import '../../../core/ios/swipe_row.dart';
import '../../../core/theme.dart';
import '../../../core/ui_constants.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../routing/routes.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import 'quick_add_meal_dialog.dart';
import '../../../services/preferences_service.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import '../../../core/ios/liquid_glass_tab_bar.dart';

/// The home of the meals area: pick a day, see the day's totals, see the
/// meals, add another. The workouts home screen is deliberately the same
/// screen with different content.
class MealsPage extends HookConsumerWidget {
  const MealsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedDate = useState(AppDateUtils.today);
    final dateInt = AppDateUtils.dateToInt(selectedDate.value);
    final mealsColor = ref.watch(preferencesServiceProvider).mealsColor;

    final mealsStream = ref.watch(mealsByDateStreamProvider(dateInt));
    final dayTotalsStream = ref.watch(dayTotalsStreamProvider(dateInt));

    return AppScaffold(
      title: l10n.meals,
      backTooltip: l10n.backToDashboard,
      pinnedHeader: DateStrip(
        date: selectedDate.value,
        onChanged: (next) => selectedDate.value = next,
      ),
      actions: [
        NavBarAction(
          icon: CupertinoIcons.calendar,
          tooltip: l10n.calendar,
          onPressed: () => context.push(Routes.calendar),
        ),
        NavBarAction(
          icon: CupertinoIcons.add,
          tooltip: l10n.logMeal,
          onPressed: () => _showAddMealOptions(context, ref),
        ),
      ],
      floatingTabBar: const LiquidGlassTabBar(currentIndex: 1),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            UIConstants.screenHorizontalPadding,
            UIConstants.cardSpacing,
            UIConstants.screenHorizontalPadding,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: ShortcutRow(
              shortcuts: [
                AppShortcut(
                  icon: CupertinoIcons.square_list,
                  label: l10n.mealTemplates,
                  color: mealsColor,
                  onTap: () => context.push(Routes.mealTemplates),
                ),
                AppShortcut(
                  icon: CupertinoIcons.book,
                  label: l10n.foodCatalog,
                  color: mealsColor,
                  onTap: () => context.push(Routes.foodCatalog),
                ),
                AppShortcut(
                  icon: CupertinoIcons.slider_horizontal_3,
                  label: l10n.nutritionGoals,
                  color: mealsColor,
                  onTap: () => context.push(Routes.nutritionGoals),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            UIConstants.screenHorizontalPadding,
            UIConstants.cardSpacing,
            UIConstants.screenHorizontalPadding,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: StreamBuilder<DayTotals>(
              stream: dayTotalsStream,
              builder: (context, snapshot) {
                final totals = snapshot.data;
                if (totals == null) return const SizedBox.shrink();

                final prefs = ref.watch(preferencesServiceProvider);
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dailyTotals,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      NutritionProgressGrid(
                        calories: totals.kcal,
                        protein: totals.protein,
                        carbs: totals.carbs,
                        fat: totals.fat,
                        calorieGoal: prefs.calorieGoal,
                        proteinGoal: prefs.proteinGoal,
                        carbsGoal: prefs.carbsGoal,
                        fatGoal: prefs.fatGoal,
                        useShortLabels: false,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        StreamBuilder<List<Meal>>(
          stream: mealsStream,
          builder: (context, snapshot) {
            // First load only: on later rebuilds the list we already have is
            // still valid, and a spinner over it reads as data disappearing.
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: LoadingIndicator(),
                ),
              );
            }

            final meals = snapshot.data ?? [];

            if (meals.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyState(
                    title: '${l10n.timeTo} ${l10n.fuelUp}',
                    subtitle: '${l10n.trackYourNutritionFor.trim()} '
                        '${AppDateUtils.formatDate(selectedDate.value)}',
                    icon: Icons.restaurant,
                    actionText: l10n.logFirstMeal,
                    actionIcon: Icons.add,
                    onAction: () => _showAddMealOptions(context, ref),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                UIConstants.screenHorizontalPadding,
                UIConstants.cardSpacing,
                UIConstants.screenHorizontalPadding,
                UIConstants.sectionSpacing,
              ),
              sliver: SliverList.builder(
                itemCount: meals.length,
                itemBuilder: (context, index) {
                  final meal = meals[index];
                  return _MealCard(
                    meal: meal,
                    onTap: () => context.push('/meals/edit/${meal.id}'),
                    onDelete: () => _deleteMeal(ref, meal),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showAddMealOptions(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    await showAppActionSheet(
      context: context,
      title: l10n.logMeal,
      actions: [
        AppAction(
          label: l10n.quickAdd,
          icon: CupertinoIcons.bolt,
          isDefault: true,
          onPressed: () => showAppSheet<void>(
            context: context,
            builder: (_) => const QuickAddMealDialog(),
          ),
        ),
        AppAction(
          label: l10n.logNewMeal,
          icon: CupertinoIcons.pencil,
          onPressed: () => context.push(Routes.mealEditor),
        ),
        AppAction(
          label: l10n.useTemplate,
          icon: CupertinoIcons.square_list,
          onPressed: () => context.push(Routes.mealTemplates),
        ),
      ],
    );
  }

  Future<void> _deleteMeal(WidgetRef ref, Meal meal) async {
    await ref.read(mealsRepositoryProvider).deleteMeal(meal.id);
    // Trigger refresh to update UI immediately
    ref.invalidate(mealsRepositoryProvider);
  }
}

class _MealCard extends ConsumerWidget {
  final Meal meal;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

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

    return SwipeActionRow(
      rowKey: ValueKey(meal.id),
      deleteLabel: l10n.delete,
      confirmTitle: l10n.deleteMeal,
      confirmMessage: '${l10n.areYouSure} "${meal.name}"?',
      onDelete: onDelete,
      onEdit: onTap,
      editLabel: l10n.edit,
      actions: [
        AppAction(
          label: l10n.edit,
          icon: CupertinoIcons.pencil,
          onPressed: onTap,
        ),
      ],
      child: Padding(
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
                  const SizedBox(width: 4),
                  AppRowMenuButton(
                    title: meal.name,
                    tooltip: l10n.meals,
                    actions: [
                      AppAction(
                        label: l10n.edit,
                        icon: CupertinoIcons.pencil,
                        onPressed: onTap,
                      ),
                      AppAction(
                        label: l10n.delete,
                        icon: CupertinoIcons.delete,
                        isDestructive: true,
                        onPressed: () async {
                          final confirmed = await showAppConfirm(
                            context: context,
                            title: l10n.deleteMeal,
                            message: '${l10n.areYouSure} "${meal.name}"?',
                            confirmLabel: l10n.delete,
                          );
                          if (confirmed) await onDelete();
                        },
                      ),
                    ],
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
