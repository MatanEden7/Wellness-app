import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/validation.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        _loadTemplate(ref, templateId!, nameController, descriptionController, templateItems);
      }
      return null;
    }, [templateId]);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editMealTemplate : l10n.createMealTemplate),
        actions: [
          AppButton(
            text: l10n.save,
            onPressed: isLoading.value ? null : () => _saveTemplate(
              context,
              ref,
              isEditing,
              templateId,
              nameController.text,
              descriptionController.text,
              templateItems.value,
              isLoading,
            ),
            isLoading: isLoading.value,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template Name
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.templateName,
                hintText: 'e.g., High Protein Breakfast, Pre-Workout Snack',
                counterText: '${nameController.text.length}/${TextLimits.mealNameMaxLength}',
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
                counterText: '${descriptionController.text.length}/${TextLimits.generalNoteMaxLength}',
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
                  onEdit: () => _editTemplateItem(context, ref, templateItems, index),
                  onDelete: () => _deleteTemplateItem(templateItems, index),
                );
              }),
          ],
        ),
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
    print('[TEMPLATES-UI] 📖 Loading template for editing with ID: $templateId');
    final template = await ref.read(mealsRepositoryProvider).getMealTemplateById(templateId);
    if (template != null) {
      print('[TEMPLATES-UI] ✅ Loaded template: "${template.name}" with ${template.items.length} items');
      print('[TEMPLATES-UI] 📋 Template ID: ${template.id}');
      print('[TEMPLATES-UI] 📋 Item IDs: ${template.items.map((i) => 'templateId:${i.templateId}, foodId:${i.foodId}').join(', ')}');
      nameController.text = template.name;
      descriptionController.text = template.description ?? '';
      templateItems.value = template.items;
    } else {
      print('[TEMPLATES-UI] ❌ Template not found with ID: $templateId');
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
      print('[TEMPLATES-UI] 💾 Saving template: isEditing=$isEditing, templateId=$templateId, items count=${items.length}');
      if (isEditing && templateId != null) {
        // Get the existing template to preserve createdAt
        print('[TEMPLATES-UI] 📖 Loading existing template with ID: $templateId');
        final existingTemplate = await ref.read(mealsRepositoryProvider).getMealTemplateById(templateId);
        
        if (existingTemplate == null) {
          print('[TEMPLATES-UI] ❌ ERROR: Existing template not found with ID: $templateId');
          throw Exception('Template not found for editing');
        }
        
        print('[TEMPLATES-UI] ✅ Found existing template: ${existingTemplate.name} (created: ${existingTemplate.createdAt})');
        
        // Update existing template - fix templateId in items
        final correctedItems = items.map((item) => item.copyWith(templateId: templateId)).toList();
        final template = MealTemplate(
          id: templateId,
          name: name.trim(),
          description: description.trim().isEmpty ? null : description.trim(),
          createdAt: existingTemplate.createdAt, // Preserve original creation date
          updatedAt: DateTime.now(),
          items: correctedItems,
        );
        print('[TEMPLATES-UI] 🔄 Updating template ID "$templateId": ${template.name} with ${template.items.length} items');
        await ref.read(mealsRepositoryProvider).updateMealTemplate(template);
        print('[TEMPLATES-UI] ✅ Template updated successfully');
      } else {
        // Create new template
        final template = MealTemplate.create(
          name: name.trim(),
          description: description.trim().isEmpty ? null : description.trim(),
        );
        print('[TEMPLATES-UI] ➕ Creating new template: ${template.name} with ID: ${template.id}');
        // Fix templateId in items to match the new template's ID
        final correctedItems = items.map((item) => item.copyWith(templateId: template.id)).toList();
        print('[TEMPLATES-UI] 🔧 Corrected ${correctedItems.length} items with template ID');
        final templateWithItems = template.copyWith(items: correctedItems);
        print('[TEMPLATES-UI] 📤 Sending to repository: ${templateWithItems.name} with ${templateWithItems.items.length} items');
        await ref.read(mealsRepositoryProvider).createMealTemplate(templateWithItems);
        print('[TEMPLATES-UI] ✅ Template created successfully');
      }

      print('[TEMPLATES-UI] 🔄 Invalidating provider to refresh UI');
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
                      food.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Builder(
                      builder: (context) {
                        // Convert to display amount (grams for 100g units)
                        final displayAmount = food.unit.toLowerCase().contains('100')
                            ? item.amount * 100
                            : item.amount;
                        final displayUnit = food.unit.toLowerCase().contains('100')
                            ? 'g'
                            : food.unit;
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
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
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
    final amountController = useTextEditingController(text: '100');
    final selectedFoodState = useState<FoodItem?>(null);
    final allFoods = ref.watch(mealsRepositoryProvider).watchAllFoods();

    // Initialize with existing food if editing
    useEffect(() {
      if (initialFoodId != null) {
        ref.read(mealsRepositoryProvider).getFoodById(initialFoodId!).then((food) {
          if (food != null) {
            selectedFoodState.value = food;
            if (initialAmount != null) {
              final displayAmount = _toDisplayAmount(initialAmount!, food.unit);
              amountController.text = displayAmount.toString();
            }
          }
        });
      }
      return null;
    }, []);

    return Dialog(
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
              child: StreamBuilder<List<FoodItem>>(
                stream: allFoods,
                builder: (context, snapshot) {
                  final foods = snapshot.data ?? [];
                  if (foods.isEmpty) {
                    return Center(child: Text(l10n.noFoodsAvailable));
                  }

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
                        subtitle: Text('${food.brand ?? 'Generic'} • ${_getDisplayUnit(food.unit)}'),
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
                '${selectedFoodState.value!.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  suffixText: _getDisplayUnit(selectedFoodState.value!.unit),
                ),
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
                  text: l10n.save,
                  onPressed: selectedFoodState.value != null
                      ? () {
                          final displayAmount = double.tryParse(amountController.text);
                          if (displayAmount == null || displayAmount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.pleaseEnterValidAmount)),
                            );
                            return;
                          }

                          // Convert display amount back to stored amount
                          final storedAmount = _toStoredAmount(displayAmount, selectedFoodState.value!.unit);

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
    );
  }
}

