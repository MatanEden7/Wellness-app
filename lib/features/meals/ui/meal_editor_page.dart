import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shell/platform_page.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../core/validation.dart';
import '../../../services/language_service.dart';
import '../data/repositories.dart';
import '../domain/food_nutrition_math.dart';
import '../domain/models.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import '../../../core/ios/glass.dart';
import '../../../core/design/surfaces.dart';
import '../../../core/design/tokens.dart';
import '../../../core/ios/feedback.dart';
import '../../../core/ios/pickers.dart';

class MealEditorPage extends HookConsumerWidget {
  final String? mealId;

  const MealEditorPage({super.key, this.mealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = useTextEditingController();
    final noteController = useTextEditingController();
    final selectedDate = useState(AppDateUtils.today);
    final selectedTime = useState<TimeOfDay?>(null);
    final mealItems = useState<List<MealItem>>([]);
    final isLoading = useState(false);
    final isEditing = mealId != null;

    // Load existing meal if editing
    useEffect(() {
      if (isEditing) {
        _loadMeal(ref, mealId!, nameController, noteController, selectedDate,
            selectedTime, mealItems);
      }
      return null;
    }, [mealId]);

    final totalKcal = mealItems.value.fold(0.0, (sum, item) => sum + item.kcal);
    final totalProtein =
        mealItems.value.fold(0.0, (sum, item) => sum + item.protein);
    final totalCarbs =
        mealItems.value.fold(0.0, (sum, item) => sum + item.carbs);
    final totalFat = mealItems.value.fold(0.0, (sum, item) => sum + item.fat);

    // The title used to read "Add Food"/"Edit Food" -- copy-pasted from the
    // food editor, on the screen that edits a *meal*.
    return PlatformChildPage(
      chrome: PageChrome(
        title: isEditing ? l10n.editMeal : l10n.logNewMeal,
        actions: [
          ChromeAction(
            label: l10n.save,
            tooltip: l10n.save,
            isProminent: true,
            onPressed: isLoading.value
                ? null
                : () => _saveMeal(
                      context,
                      ref,
                      isEditing,
                      mealId,
                      nameController.text,
                      noteController.text,
                      selectedDate.value,
                      selectedTime.value,
                      mealItems.value,
                      isLoading,
                    ),
          ),
        ],
      ),
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
              hintText: l10n.mealNameHint,
              counterText:
                  '${nameController.text.length}/${TextLimits.mealNameMaxLength}',
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: Space.lg, vertical: Space.lg),
            ),
            style: const TextStyle(fontSize: 16),
            maxLength: TextLimits.mealNameMaxLength,
            validator: TextLimits.validateMealName,
          ),
          const SizedBox(height: 20),

          // Date Selector
          Text(
            AppLocalizations.of(context)!.date,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ContentSurface(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
            child: Container(
              padding: const EdgeInsets.all(Space.lg),
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
                  GlassButton(
                    minHeight: Sizes.control,
                    borderRadius: BorderRadius.circular(18),
                    padding: const EdgeInsets.symmetric(
                        horizontal: Space.md, vertical: Space.sm),
                    onPressed: () => _selectDate(context, selectedDate),
                    child: Text(l10n.change),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Time (optional) -- when set, the calendar shows this meal at
          // this exact time instead of guessing from createdAt/keywords.
          Text(
            l10n.mealTimeOptional,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ContentSurface(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
            child: Container(
              padding: const EdgeInsets.all(Space.lg),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedTime.value?.format(context) ?? l10n.notSet,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  if (selectedTime.value != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      tooltip: l10n.clear,
                      onPressed: () => selectedTime.value = null,
                    ),
                  GlassButton(
                    minHeight: Sizes.control,
                    borderRadius: BorderRadius.circular(18),
                    padding: const EdgeInsets.symmetric(
                        horizontal: Space.md, vertical: Space.sm),
                    onPressed: () => _selectTime(context, selectedTime),
                    child: Text(l10n.change),
                  ),
                ],
              ),
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
              counterText:
                  '${noteController.text.length}/${TextLimits.generalNoteMaxLength}',
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: Space.lg, vertical: Space.lg),
            ),
            style: const TextStyle(fontSize: 16),
            maxLines: 3,
            maxLength: TextLimits.generalNoteMaxLength,
            validator: TextLimits.validateGeneralNote,
          ),
          const SizedBox(height: 24),

          // Meal Totals
          Text(
            AppLocalizations.of(context)!.nutritionTotals,
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
                  value:
                      '${Formatters.formatMacros(totalProtein)}${l10n.grams}',
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
    );
  }

  Future<void> _loadMeal(
    WidgetRef ref,
    String mealId,
    TextEditingController nameController,
    TextEditingController noteController,
    ValueNotifier<DateTime> selectedDate,
    ValueNotifier<TimeOfDay?> selectedTime,
    ValueNotifier<List<MealItem>> mealItems,
  ) async {
    final meal = await ref.read(mealsRepositoryProvider).getMealById(mealId);
    if (meal != null) {
      nameController.text = meal.name;
      noteController.text = meal.note ?? '';
      selectedDate.value = AppDateUtils.intToDate(meal.date);
      selectedTime.value =
          meal.loggedAt != null ? TimeOfDay.fromDateTime(meal.loggedAt!) : null;
      mealItems.value = meal.items;
    }
  }

  Future<void> _selectDate(
      BuildContext context, ValueNotifier<DateTime> selectedDate) async {
    final date = await showAppDatePicker(
      context: context,
      initial: selectedDate.value,
      first: DateTime.now().subtract(const Duration(days: 365)),
      last: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null) {
      selectedDate.value = date;
    }
  }

  Future<void> _selectTime(
      BuildContext context, ValueNotifier<TimeOfDay?> selectedTime) async {
    final time = await showAppTimePicker(
      context: context,
      initial: selectedTime.value ?? TimeOfDay.now(),
    );
    if (time != null) {
      selectedTime.value = time;
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
    TimeOfDay? time,
    List<MealItem> items,
    ValueNotifier<bool> isLoading,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (name.trim().isEmpty) {
      showAppError(context, l10n.pleaseEnterMealName);
      return;
    }

    final loggedAt = time != null
        ? DateTime(date.year, date.month, date.day, time.hour, time.minute)
        : null;

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
              loggedAt: loggedAt,
              items: items,
            )
          : Meal.create(
              date: AppDateUtils.dateToInt(date),
              name: name.trim(),
              note: note?.trim().isEmpty == true ? null : note?.trim(),
            ).copyWith(loggedAt: loggedAt);

      // Update meal items with the correct meal ID
      final updatedItems = items
          .map((item) => MealItem(
                id: item.id,
                mealId: meal.id, // Set the correct meal ID
                foodId: item.foodId,
                amount: item.amount,
                kcal: item.kcal,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
              ))
          .toList();

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
        showAppError(context, 'Error saving meal: $e');
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
    final food =
        await ref.read(mealsRepositoryProvider).getFoodById(currentItem.foodId);
    if (food == null) return;

    final result = await _showFoodSelector(context, ref,
        food: food, currentAmount: currentItem.amount);
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
      builder: (context) => FoodSelectorDialog(
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
    final foodStream = ref.watch(foodByIdStreamProvider(item.foodId));
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
                    tooltip: AppLocalizations.of(context)!.edit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: AppLocalizations.of(context)!.delete,
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
              final displayAmount =
                  FoodNutritionMath.displayQuantity(food, item.amount);
              final displayUnit = FoodNutritionMath.displayUnitLabel(food);
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

/// Search foods and pick one with a quantity, returning a [MealItem].
/// Public so it can be reused by the dashboard's quick-add meal dialog.
class FoodSelectorDialog extends HookConsumerWidget {
  final FoodItem? selectedFood;
  final double? currentAmount;

  const FoodSelectorDialog({
    super.key,
    this.selectedFood,
    this.currentAmount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(currentLanguageProvider);
    final searchController = useTextEditingController();
    final selectedFoodState = useState<FoodItem?>(selectedFood);

    // Convert current amount to display format if editing
    final displayAmount = currentAmount != null && selectedFood != null
        ? FoodNutritionMath.displayQuantity(selectedFood!, currentAmount!)
        : 100.0;

    final amountController = useTextEditingController(
      text: displayAmount.toString(),
    );

    final allFoods = ref.watch(allFoodsStreamProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ContentSurface(
        borderRadius: BorderRadius.circular(24),
        showBorder: false,
        child: Container(
          width: 400,
          height: 600,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SettingsIconBadge(Icons.restaurant,
                      color: Colors.orange),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    AppLocalizations.of(context)!.selectFoodItem,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
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
                // AnimatedBuilder (not a plain StreamBuilder alone) so this
                // rebuilds when searchController's text changes -- see the
                // identical fix in meal_template_editor_page.dart's
                // _TemplateItemDialog for why a bare StreamBuilder here never
                // actually refilters as you type.
                child: AnimatedBuilder(
                  animation: searchController,
                  builder: (context, _) {
                    return StreamBuilder<List<FoodItem>>(
                      stream: allFoods,
                      builder: (context, snapshot) {
                        final foods = snapshot.data ?? [];
                        final filteredFoods = foods.where((food) {
                          // Matches the Hebrew name too -- see
                          // FoodItemDisplayName.matchesSearch.
                          return food.matchesSearch(searchController.text);
                        }).toList();

                        return ListView.builder(
                          itemCount: filteredFoods.length,
                          itemBuilder: (context, index) {
                            final food = filteredFoods[index];
                            final isSelected =
                                selectedFoodState.value?.id == food.id;

                            return ListTile(
                              title: Text(food.displayName(language)),
                              subtitle: Text(
                                '${food.brand ?? 'Generic'} • ${Formatters.formatCalories(food.kcalPerUnit)} cal/${food.unit}',
                              ),
                              selected: isSelected,
                              onTap: () => selectedFoodState.value = food,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              if (selectedFoodState.value != null) ...[
                const Divider(),
                Text(
                  'Amount (${FoodNutritionMath.displayUnitLabel(selectedFoodState.value!)})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: l10n.amount,
                    suffixText: FoodNutritionMath.displayUnitLabel(
                        selectedFoodState.value!),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),

                // Preview -- AnimatedBuilder (not Builder) so this rebuilds
                // when amountController's text changes; a plain Builder never
                // gets notified of the controller changing and just kept
                // showing the macros for whatever amount was set when the
                // dialog opened.
                AnimatedBuilder(
                  animation: amountController,
                  builder: (context, _) {
                    final displayAmount =
                        double.tryParse(amountController.text) ?? 0;
                    final food = selectedFoodState.value!;
                    final nutrition =
                        FoodNutritionMath.computeMacrosFromDisplay(
                            food, displayAmount);
                    final kcal = nutrition.kcal;
                    final protein = nutrition.protein;
                    final carbs = nutrition.carbs;
                    final fat = nutrition.fat;

                    return ContentSurface(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surface,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('${Formatters.formatCalories(kcal)} cal'),
                            Text('P: ${Formatters.formatMacros(protein)}g'),
                            Text('C: ${Formatters.formatMacros(carbs)}g'),
                            Text('F: ${Formatters.formatMacros(fat)}g'),
                          ],
                        ),
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
                  GlassButton(
                    minHeight: Sizes.control,
                    borderRadius: BorderRadius.circular(18),
                    padding: const EdgeInsets.symmetric(
                        horizontal: Space.md, vertical: Space.sm),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    text: 'Add',
                    onPressed: selectedFoodState.value != null
                        ? () {
                            final displayAmount =
                                double.tryParse(amountController.text) ?? 0;
                            if (displayAmount > 0) {
                              // Convert display amount back to stored amount
                              final storedAmount =
                                  FoodNutritionMath.storedQuantity(
                                selectedFoodState.value!,
                                displayAmount,
                              );
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
      ),
    );
  }
}
