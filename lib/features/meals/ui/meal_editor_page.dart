import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../core/validation.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MealEditorPage extends HookConsumerWidget {
  final String? mealId;

  const MealEditorPage({super.key, this.mealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = useTextEditingController();
    final noteController = useTextEditingController();
    final selectedDate = useState(AppDateUtils.today);
    final mealItems = useState<List<MealItem>>([]);
    final isLoading = useState(false);
    final isEditing = mealId != null;

    // Load existing meal if editing
    useEffect(() {
      if (isEditing) {
        _loadMeal(ref, mealId!, nameController, noteController, selectedDate, mealItems);
      }
      return null;
    }, [mealId]);

    final totalKcal = mealItems.value.fold(0.0, (sum, item) => sum + item.kcal);
    final totalProtein = mealItems.value.fold(0.0, (sum, item) => sum + item.protein);
    final totalCarbs = mealItems.value.fold(0.0, (sum, item) => sum + item.carbs);
    final totalFat = mealItems.value.fold(0.0, (sum, item) => sum + item.fat);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? l10n.editFood : l10n.addFood,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppButton(
              text: l10n.save,
              onPressed: isLoading.value ? null : () => _saveMeal(
                context,
                ref,
                isEditing,
                mealId,
                nameController.text,
                noteController.text,
                selectedDate.value,
                mealItems.value,
                isLoading,
              ),
              isLoading: isLoading.value,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal Name
              Text(
                l10n.mealName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.mealName,
                  hintText: 'e.g., Breakfast, Lunch, Dinner',
                  counterText: '${nameController.text.length}/${TextLimits.mealNameMaxLength}',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(fontSize: 16),
                maxLength: TextLimits.mealNameMaxLength,
                validator: TextLimits.validateMealName,
              ),
              const SizedBox(height: 20),

              // Date Selector
              Text(
                'Date',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppDateUtils.formatDate(selectedDate.value),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _selectDate(context, selectedDate),
                      child: Text(l10n.change),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Notes
              Text(
                l10n.notesOptional,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: l10n.notesOptional,
                  hintText: 'Any additional notes about this meal',
                  counterText: '${noteController.text.length}/${TextLimits.generalNoteMaxLength}',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(fontSize: 16),
                maxLines: 3,
                maxLength: TextLimits.generalNoteMaxLength,
                validator: TextLimits.validateGeneralNote,
              ),
              const SizedBox(height: 24),

              // Meal Totals
              Text(
                'Nutrition Totals',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
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
                      value: '${Formatters.formatMacros(totalProtein)}${l10n.grams}',
                      color: Colors.red,
                    ),
                    _MacroColumn(
                      label: l10n.carbs,
                      value: '${Formatters.formatMacros(totalCarbs)}${l10n.grams}',
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
              const SizedBox(height: 32),

              // Meal Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    l10n.addFood,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppButton(
                    text: l10n.add,
                    onPressed: () => _addMealItem(context, ref, mealItems),
                    isSecondary: true,
                    icon: Icons.add,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Meal Items List
              if (mealItems.value.isEmpty)
                EmptyState(
                  title: l10n.buildYourFoodLibrary,
                  subtitle: l10n.createCustomFoods,
                  icon: Icons.restaurant,
                  actionText: l10n.addFirstFood,
                  actionIcon: Icons.add,
                  onAction: () => _addMealItem(context, ref, mealItems),
                )
              else
                ...mealItems.value.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MealItemCard(
                      item: item,
                      onEdit: () => _editMealItem(context, ref, mealItems, index),
                      onDelete: () => _deleteMealItem(mealItems, index),
                    ),
                  );
                }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadMeal(
    WidgetRef ref,
    String mealId,
    TextEditingController nameController,
    TextEditingController noteController,
    ValueNotifier<DateTime> selectedDate,
    ValueNotifier<List<MealItem>> mealItems,
  ) async {
    final meal = await ref.read(mealsRepositoryProvider).getMealById(mealId);
    if (meal != null) {
      nameController.text = meal.name;
      noteController.text = meal.note ?? '';
      selectedDate.value = AppDateUtils.intToDate(meal.date);
      mealItems.value = meal.items;
    }
  }

  Future<void> _selectDate(BuildContext context, ValueNotifier<DateTime> selectedDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null) {
      selectedDate.value = date;
    }
  }

  Future<void> _saveMeal(
    BuildContext context,
    WidgetRef ref,
    bool isEditing,
    String? mealId,
    String name,
    String? note,
    DateTime date,
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
      final meal = isEditing
          ? Meal(
              id: mealId!,
              date: AppDateUtils.dateToInt(date),
              name: name.trim(),
              note: note?.trim().isEmpty == true ? null : note?.trim(),
              createdAt: DateTime.now(), // Will be preserved in update
              updatedAt: DateTime.now(),
              items: items,
            )
          : Meal.create(
              date: AppDateUtils.dateToInt(date),
              name: name.trim(),
              note: note?.trim().isEmpty == true ? null : note?.trim(),
            );

      // Update meal items with the correct meal ID
      final updatedItems = items.map((item) => MealItem(
        id: item.id,
        mealId: meal.id, // Set the correct meal ID
        foodId: item.foodId,
        amount: item.amount,
        kcal: item.kcal,
        protein: item.protein,
        carbs: item.carbs,
        fat: item.fat,
      )).toList();

      final finalMeal = meal.copyWith(items: updatedItems);

      if (isEditing) {
        await ref.read(mealsRepositoryProvider).updateMeal(finalMeal);
      } else {
        await ref.read(mealsRepositoryProvider).createMeal(finalMeal);
      }

      // Trigger refresh to update UI immediately
      ref.invalidate(mealsRepositoryProvider);

      if (context.mounted) {
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving meal: $e')),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _addMealItem(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<List<MealItem>> mealItems,
  ) async {
    final result = await _showFoodSelector(context, ref);
    if (result != null) {
      final newItems = List<MealItem>.from(mealItems.value);
      newItems.add(result);
      mealItems.value = newItems;
    }
  }

  Future<void> _editMealItem(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<List<MealItem>> mealItems,
    int index,
  ) async {
    final currentItem = mealItems.value[index];
    final food = await ref.read(mealsRepositoryProvider).getFoodById(currentItem.foodId);
    if (food == null) return;

    final result = await _showFoodSelector(context, ref, food: food, currentAmount: currentItem.amount);
    if (result != null) {
      final newItems = List<MealItem>.from(mealItems.value);
      newItems[index] = result;
      mealItems.value = newItems;
    }
  }

  void _deleteMealItem(ValueNotifier<List<MealItem>> mealItems, int index) {
    final newItems = List<MealItem>.from(mealItems.value);
    newItems.removeAt(index);
    mealItems.value = newItems;
  }

  Future<MealItem?> _showFoodSelector(
    BuildContext context,
    WidgetRef ref, {
    FoodItem? food,
    double? currentAmount,
  }) async {
    return showDialog<MealItem>(
      context: context,
      builder: (context) => _FoodSelectorDialog(
        selectedFood: food,
        currentAmount: currentAmount,
      ),
    );
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MealItemCard extends HookConsumerWidget {
  final MealItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MealItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodStream = ref.watch(mealsRepositoryProvider).watchFoodById(item.foodId);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: StreamBuilder<FoodItem?>(
                  stream: foodStream,
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data?.name ?? 'Food Item',
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    );
                  },
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
          StreamBuilder<FoodItem?>(
            stream: foodStream,
            builder: (context, snapshot) {
              final food = snapshot.data;
              if (food == null) {
                return Text(
                  'Amount: ${Formatters.formatNumber(item.amount)}',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }
              // Convert to display amount (grams for 100g units)
              final displayAmount = food.unit.toLowerCase().contains('100')
                  ? item.amount * 100
                  : item.amount;
              final displayUnit = food.unit.toLowerCase().contains('100')
                  ? 'g'
                  : food.unit;
              return Text(
                'Amount: ${Formatters.formatNumber(displayAmount)} $displayUnit',
                style: Theme.of(context).textTheme.bodySmall,
              );
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('${Formatters.formatCalories(item.kcal)} cal'),
              Text('P: ${Formatters.formatMacros(item.protein)}g'),
              Text('C: ${Formatters.formatMacros(item.carbs)}g'),
              Text('F: ${Formatters.formatMacros(item.fat)}g'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoodSelectorDialog extends HookConsumerWidget {
  final FoodItem? selectedFood;
  final double? currentAmount;

  const _FoodSelectorDialog({
    this.selectedFood,
    this.currentAmount,
  });

  // Helper to convert stored amount to display amount (grams)
  double _toDisplayAmount(double amount, String unit) {
    if (unit.toLowerCase().contains('100')) {
      return amount * 100; // Convert from 100g units to grams
    }
    return amount;
  }

  // Helper to convert display amount (grams) to stored amount
  double _toStoredAmount(double displayAmount, String unit) {
    if (unit.toLowerCase().contains('100')) {
      return displayAmount / 100; // Convert from grams to 100g units
    }
    return displayAmount;
  }

  // Helper to get display unit label
  String _getDisplayUnit(String unit) {
    if (unit.toLowerCase().contains('100')) {
      return 'g'; // Show as 'g' instead of '100g'
    }
    return unit;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final searchController = useTextEditingController();
    final selectedFoodState = useState<FoodItem?>(this.selectedFood);
    
    // Convert current amount to display format if editing
    final displayAmount = currentAmount != null && this.selectedFood != null
        ? _toDisplayAmount(currentAmount!, this.selectedFood!.unit)
        : 100.0;
    
    final amountController = useTextEditingController(
      text: displayAmount.toString(),
    );
    
    final allFoods = ref.watch(mealsRepositoryProvider).watchAllFoods();

    return Dialog(
      child: Container(
        width: 400,
        height: 600,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Food Item',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Search
            TextFormField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: l10n.searchFoods,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Food List
            Expanded(
              child: StreamBuilder<List<FoodItem>>(
                stream: allFoods,
                builder: (context, snapshot) {
                  final foods = snapshot.data ?? [];
                  final filteredFoods = foods.where((food) {
                    final query = searchController.text.toLowerCase();
                    return food.name.toLowerCase().contains(query) ||
                           (food.brand?.toLowerCase().contains(query) ?? false);
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredFoods.length,
                    itemBuilder: (context, index) {
                      final food = filteredFoods[index];
                      final isSelected = selectedFoodState.value?.id == food.id;
                      
                      return ListTile(
                        title: Text(food.name),
                        subtitle: Text(
                          '${food.brand ?? 'Generic'} • ${Formatters.formatCalories(food.kcalPerUnit)} cal/${food.unit}',
                        ),
                        selected: isSelected,
                        onTap: () => selectedFoodState.value = food,
                      );
                    },
                  );
                },
              ),
            ),

            if (selectedFoodState.value != null) ...[
              const Divider(),
              Text(
                'Amount (${_getDisplayUnit(selectedFoodState.value!.unit)})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  suffixText: _getDisplayUnit(selectedFoodState.value!.unit),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Preview
              Builder(
                builder: (context) {
                  final displayAmount = double.tryParse(amountController.text) ?? 0;
                  final food = selectedFoodState.value!;
                  // Convert display amount to stored amount for calculation
                  final storedAmount = _toStoredAmount(displayAmount, food.unit);
                  final kcal = food.kcalPerUnit * storedAmount;
                  final protein = food.proteinPerUnit * storedAmount;
                  final carbs = food.carbsPerUnit * storedAmount;
                  final fat = food.fatPerUnit * storedAmount;

                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('${Formatters.formatCalories(kcal)} cal'),
                        Text('P: ${Formatters.formatMacros(protein)}g'),
                        Text('C: ${Formatters.formatMacros(carbs)}g'),
                        Text('F: ${Formatters.formatMacros(fat)}g'),
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  text: 'Add',
                  onPressed: selectedFoodState.value != null
                      ? () {
                          final displayAmount = double.tryParse(amountController.text) ?? 0;
                          if (displayAmount > 0) {
                            // Convert display amount back to stored amount
                            final storedAmount = _toStoredAmount(displayAmount, selectedFoodState.value!.unit);
                            final mealItem = MealItem.create(
                              mealId: '', // Will be set by parent
                              foodId: selectedFoodState.value!.id,
                              amount: storedAmount,
                              food: selectedFoodState.value!,
                            );
                            Navigator.of(context).pop(mealItem);
                          }
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
