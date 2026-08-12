import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../services/preferences_service.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import 'meal_editor_page.dart' show FoodSelectorDialog;
import 'package:wellness_app/l10n/app_localizations.dart';
import '../../../core/design/tokens.dart';

/// Sheet opened from the dashboard "+": name the meal, search/add foods via
/// the same [FoodSelectorDialog] the full editor uses, and save directly --
/// no page navigation, this is the actual quick-add.
class QuickAddMealDialog extends HookConsumerWidget {
  const QuickAddMealDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = useTextEditingController();
    final mealItems = useState<List<MealItem>>([]);
    final isLoading = useState(false);

    final totalKcal = mealItems.value.fold(0.0, (sum, item) => sum + item.kcal);
    final totalProtein =
        mealItems.value.fold(0.0, (sum, item) => sum + item.protein);
    final totalCarbs =
        mealItems.value.fold(0.0, (sum, item) => sum + item.carbs);
    final totalFat = mealItems.value.fold(0.0, (sum, item) => sum + item.fat);

    return AppSheet(
      title: l10n.quickAdd,
      icon: Icons.restaurant,
      iconColor: ref.watch(preferencesServiceProvider).mealsColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.mealName,
              hintText: l10n.mealNameHint,
            ),
          ),
          const SizedBox(height: 16),
          if (mealItems.value.isNotEmpty) ...[
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroColumn(
                    label: l10n.caloriesLabel,
                    value: Formatters.formatCalories(totalKcal),
                    color: Colors.orange,
                  ),
                  _MacroColumn(
                    label: l10n.protein,
                    value:
                        '${Formatters.formatMacros(totalProtein)}${l10n.grams}',
                    color: Colors.red,
                  ),
                  _MacroColumn(
                    label: l10n.carbs,
                    value:
                        '${Formatters.formatMacros(totalCarbs)}${l10n.grams}',
                    color: Colors.blue,
                  ),
                  _MacroColumn(
                    label: l10n.fat,
                    value: '${Formatters.formatMacros(totalFat)}${l10n.grams}',
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...mealItems.value.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _QuickMealItemRow(
                  item: item,
                  onDelete: () {
                    final items = List<MealItem>.from(mealItems.value)
                      ..removeAt(index);
                    mealItems.value = items;
                  },
                ),
              );
            }),
            const SizedBox(height: 4),
          ],
          AppButton(
            text: l10n.addFood,
            icon: Icons.add,
            isSecondary: true,
            onPressed: () async {
              final result = await showDialog<MealItem>(
                context: context,
                builder: (_) => const FoodSelectorDialog(),
              );
              if (result != null) {
                mealItems.value = [...mealItems.value, result];
              }
            },
          ),
          const SizedBox(height: 20),
          AppButton(
            text: l10n.save,
            isLoading: isLoading.value,
            onPressed: isLoading.value
                ? null
                : () => _save(
                      context,
                      ref,
                      nameController.text,
                      mealItems.value,
                      isLoading,
                    ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    String name,
    List<MealItem> items,
    ValueNotifier<bool> isLoading,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterMealName)),
      );
      return;
    }

    isLoading.value = true;
    try {
      final meal = Meal.create(
        date: AppDateUtils.dateToInt(AppDateUtils.today),
        name: name.trim(),
      );
      final mealWithItems = meal.copyWith(
        items: items
            .map((item) => MealItem(
                  id: item.id,
                  mealId: meal.id,
                  foodId: item.foodId,
                  amount: item.amount,
                  kcal: item.kcal,
                  protein: item.protein,
                  carbs: item.carbs,
                  fat: item.fat,
                ))
            .toList(),
      );

      await ref.read(mealsRepositoryProvider).createMeal(mealWithItems);
      ref.invalidate(mealsRepositoryProvider);

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}

class _MacroColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _QuickMealItemRow extends HookConsumerWidget {
  final MealItem item;
  final VoidCallback onDelete;

  const _QuickMealItemRow({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodStream = ref.watch(foodByIdStreamProvider(item.foodId));
    return StreamBuilder<FoodItem?>(
      stream: foodStream,
      builder: (context, snapshot) {
        return AppCard(
          padding:
              const EdgeInsets.symmetric(horizontal: Space.md, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  snapshot.data?.name ?? 'Food Item',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${Formatters.formatCalories(item.kcal)} cal',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        );
      },
    );
  }
}
