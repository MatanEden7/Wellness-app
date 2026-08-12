import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shell/platform_page.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/validation.dart';
import '../../../services/language_service.dart';
import '../data/repositories.dart';
import '../domain/food_nutrition_math.dart';
import '../domain/models.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import '../../../core/ios/glass.dart';
import '../../../core/design/surfaces.dart';
import '../../../core/design/tokens.dart';

class MealTemplateEditorPage extends HookConsumerWidget {
  final String? templateId;

  const MealTemplateEditorPage({super.key, this.templateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final templateItems = useState<List<MealTemplateItem>>([]);
    final isLoading = useState(false);
    final isEditing = templateId != null;

    // Load existing template if editing
    useEffect(() {
      if (isEditing) {
        _loadTemplate(ref, templateId!, nameController, descriptionController,
            templateItems);
      }
      return null;
    }, [templateId]);

    return PlatformChildPage(
      chrome: PageChrome(
        title: isEditing ? l10n.editMealTemplate : l10n.createMealTemplate,
        actions: [
          ChromeAction(
            label: l10n.save,
            tooltip: l10n.save,
            isProminent: true,
            onPressed: isLoading.value
                ? null
                : () => _saveTemplate(
                      context,
                      ref,
                      isEditing,
                      templateId,
                      nameController.text,
                      descriptionController.text,
                      templateItems.value,
                      isLoading,
                    ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template Name
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: l10n.templateName,
              hintText: 'e.g., High Protein Breakfast, Pre-Workout Snack',
              counterText:
                  '${nameController.text.length}/${TextLimits.mealNameMaxLength}',
            ),
            maxLength: TextLimits.mealNameMaxLength,
            validator: TextLimits.validateMealName,
          ),
          const SizedBox(height: AppSpacing.md),

          // Description
          TextFormField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: l10n.descriptionOptional,
              hintText: 'Notes about this meal template',
              counterText:
                  '${descriptionController.text.length}/${TextLimits.generalNoteMaxLength}',
            ),
            maxLines: 2,
            maxLength: TextLimits.generalNoteMaxLength,
            validator: TextLimits.validateGeneralNote,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Template Items Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.foodItems,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AppButton(
                text: l10n.add,
                onPressed: () => _addTemplateItem(context, ref, templateItems),
                isSecondary: true,
                icon: Icons.add,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Template Items List
          if (templateItems.value.isEmpty)
            EmptyState(
              title: l10n.addFoodsToTemplate,
              subtitle: l10n.selectFoodsFromYourLibrary,
              icon: Icons.restaurant,
              actionText: l10n.addFirstFood,
              actionIcon: Icons.add,
              onAction: () => _addTemplateItem(context, ref, templateItems),
            )
          else
            ...templateItems.value.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _TemplateItemCard(
                item: item,
                onEdit: () =>
                    _editTemplateItem(context, ref, templateItems, index),
                onDelete: () => _deleteTemplateItem(templateItems, index),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _loadTemplate(
    WidgetRef ref,
    String templateId,
    TextEditingController nameController,
    TextEditingController descriptionController,
    ValueNotifier<List<MealTemplateItem>> templateItems,
  ) async {
    debugPrint(
        '[TEMPLATES-UI] 📖 Loading template for editing with ID: $templateId');
    final template =
        await ref.read(mealsRepositoryProvider).getMealTemplateById(templateId);
    if (template != null) {
      debugPrint(
          '[TEMPLATES-UI] ✅ Loaded template: "${template.name}" with ${template.items.length} items');
      debugPrint('[TEMPLATES-UI] 📋 Template ID: ${template.id}');
      debugPrint(
          '[TEMPLATES-UI] 📋 Item IDs: ${template.items.map((i) => 'templateId:${i.templateId}, foodId:${i.foodId}').join(', ')}');
      nameController.text = template.name;
      descriptionController.text = template.description ?? '';
      templateItems.value = template.items;
    } else {
      debugPrint('[TEMPLATES-UI] ❌ Template not found with ID: $templateId');
    }
  }

  Future<void> _saveTemplate(
    BuildContext context,
    WidgetRef ref,
    bool isEditing,
    String? templateId,
    String name,
    String description,
    List<MealTemplateItem> items,
    ValueNotifier<bool> isLoading,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterTemplateName)),
      );
      return;
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseAddAtLeastOneFood)),
      );
      return;
    }

    isLoading.value = true;

    try {
      debugPrint(
          '[TEMPLATES-UI] 💾 Saving template: isEditing=$isEditing, templateId=$templateId, items count=${items.length}');
      if (isEditing && templateId != null) {
        // Get the existing template to preserve createdAt
        debugPrint(
            '[TEMPLATES-UI] 📖 Loading existing template with ID: $templateId');
        final existingTemplate = await ref
            .read(mealsRepositoryProvider)
            .getMealTemplateById(templateId);

        if (existingTemplate == null) {
          debugPrint(
              '[TEMPLATES-UI] ❌ ERROR: Existing template not found with ID: $templateId');
          throw Exception('Template not found for editing');
        }

        debugPrint(
            '[TEMPLATES-UI] ✅ Found existing template: ${existingTemplate.name} (created: ${existingTemplate.createdAt})');

        // Update existing template - fix templateId in items
        final correctedItems =
            items.map((item) => item.copyWith(templateId: templateId)).toList();
        final template = MealTemplate(
          id: templateId,
          name: name.trim(),
          description: description.trim().isEmpty ? null : description.trim(),
          createdAt:
              existingTemplate.createdAt, // Preserve original creation date
          updatedAt: DateTime.now(),
          items: correctedItems,
        );
        debugPrint(
            '[TEMPLATES-UI] 🔄 Updating template ID "$templateId": ${template.name} with ${template.items.length} items');
        await ref.read(mealsRepositoryProvider).updateMealTemplate(template);
        debugPrint('[TEMPLATES-UI] ✅ Template updated successfully');
      } else {
        // Create new template
        final template = MealTemplate.create(
          name: name.trim(),
          description: description.trim().isEmpty ? null : description.trim(),
        );
        debugPrint(
            '[TEMPLATES-UI] ➕ Creating new template: ${template.name} with ID: ${template.id}');
        // Fix templateId in items to match the new template's ID
        final correctedItems = items
            .map((item) => item.copyWith(templateId: template.id))
            .toList();
        debugPrint(
            '[TEMPLATES-UI] 🔧 Corrected ${correctedItems.length} items with template ID');
        final templateWithItems = template.copyWith(items: correctedItems);
        debugPrint(
            '[TEMPLATES-UI] 📤 Sending to repository: ${templateWithItems.name} with ${templateWithItems.items.length} items');
        await ref
            .read(mealsRepositoryProvider)
            .createMealTemplate(templateWithItems);
        debugPrint('[TEMPLATES-UI] ✅ Template created successfully');
      }

      debugPrint('[TEMPLATES-UI] 🔄 Invalidating provider to refresh UI');
      ref.invalidate(mealsRepositoryProvider);

      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.mealTemplateSaved)),
        );
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

  Future<void> _addTemplateItem(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<List<MealTemplateItem>> templateItems,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _TemplateItemDialog(ref: ref),
    );

    if (result != null) {
      final foodId = result['foodId'] as String;
      final amount = result['amount'] as double;

      final newItem = MealTemplateItem.create(
        templateId: 'temp',
        foodId: foodId,
        amount: amount,
      );
      templateItems.value = [...templateItems.value, newItem];
    }
  }

  Future<void> _editTemplateItem(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<List<MealTemplateItem>> templateItems,
    int index,
  ) async {
    final item = templateItems.value[index];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _TemplateItemDialog(
        ref: ref,
        initialFoodId: item.foodId,
        initialAmount: item.amount,
      ),
    );

    if (result != null) {
      final updatedItem = item.copyWith(
        foodId: result['foodId'] as String,
        amount: result['amount'] as double,
      );
      final newList = [...templateItems.value];
      newList[index] = updatedItem;
      templateItems.value = newList;
    }
  }

  void _deleteTemplateItem(
    ValueNotifier<List<MealTemplateItem>> templateItems,
    int index,
  ) {
    final newList = [...templateItems.value];
    newList.removeAt(index);
    templateItems.value = newList;
  }
}

class _TemplateItemCard extends ConsumerWidget {
  final MealTemplateItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(currentLanguageProvider);
    return FutureBuilder<FoodItem?>(
      future: ref.read(mealsRepositoryProvider).getFoodById(item.foodId),
      builder: (context, snapshot) {
        final food = snapshot.data;
        if (food == null) {
          return const SizedBox.shrink();
        }

        return AppCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.displayName(language),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Builder(
                      builder: (context) {
                        // Convert to display amount (grams for 100g units)
                        final displayAmount = FoodNutritionMath.displayQuantity(
                            food, item.amount);
                        final displayUnit =
                            FoodNutritionMath.displayUnitLabel(food);
                        return Text(
                          '${displayAmount.toStringAsFixed(displayAmount.truncateToDouble() == displayAmount ? 0 : 1)} $displayUnit',
                          style: Theme.of(context).textTheme.bodyMedium,
                        );
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
                tooltip: AppLocalizations.of(context)!.edit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
                tooltip: AppLocalizations.of(context)!.delete,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TemplateItemDialog extends HookConsumerWidget {
  final String? initialFoodId;
  final double? initialAmount;

  const _TemplateItemDialog({
    required this.ref,
    this.initialFoodId,
    this.initialAmount,
  });

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(currentLanguageProvider);
    final searchController = useTextEditingController();
    final amountController = useTextEditingController(text: '100');
    final selectedFoodState = useState<FoodItem?>(null);
    final allFoods = ref.watch(allFoodsStreamProvider);

    // Initialize with existing food if editing
    useEffect(() {
      if (initialFoodId != null) {
        ref
            .read(mealsRepositoryProvider)
            .getFoodById(initialFoodId!)
            .then((food) {
          if (food != null) {
            selectedFoodState.value = food;
            if (initialAmount != null) {
              final displayAmount =
                  FoodNutritionMath.displayQuantity(food, initialAmount!);
              amountController.text = displayAmount.toString();
            }
          }
        });
      }
      return null;
    }, []);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ContentSurface(
        borderRadius: BorderRadius.circular(14),
        showBorder: false,
        child: Container(
          width: 500,
          height: 600,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                initialFoodId != null ? l10n.edit : l10n.addFood,
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
                // AnimatedBuilder (not a plain StreamBuilder alone) so this
                // rebuilds when searchController's text changes -- the
                // TextFormField above has no onChanged, and without this
                // listener typing in the search box never actually
                // refiltered the list (same class of bug fixed earlier in
                // meal_editor_page.dart's _FoodSelectorDialog preview).
                child: AnimatedBuilder(
                  animation: searchController,
                  builder: (context, _) {
                    return StreamBuilder<List<FoodItem>>(
                      stream: allFoods,
                      builder: (context, snapshot) {
                        final foods = snapshot.data ?? [];
                        if (foods.isEmpty) {
                          return Center(child: Text(l10n.noFoodsAvailable));
                        }

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
                                  '${food.brand ?? 'Generic'} • ${FoodNutritionMath.displayUnitLabel(food)}'),
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
                  selectedFoodState.value!.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.amount,
                    suffixText: FoodNutritionMath.displayUnitLabel(
                        selectedFoodState.value!),
                  ),
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
                    text: l10n.save,
                    onPressed: selectedFoodState.value != null
                        ? () {
                            final displayAmount =
                                double.tryParse(amountController.text);
                            if (displayAmount == null || displayAmount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(l10n.pleaseEnterValidAmount)),
                              );
                              return;
                            }

                            // Convert display amount back to stored amount
                            final storedAmount =
                                FoodNutritionMath.storedQuantity(
                              selectedFoodState.value!,
                              displayAmount,
                            );

                            Navigator.of(context).pop({
                              'foodId': selectedFoodState.value!.id,
                              'amount': storedAmount,
                            });
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
