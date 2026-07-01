import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../core/validation.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FoodCatalogPage extends HookConsumerWidget {
  const FoodCatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tabController = useTabController(initialLength: 2);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.foodCatalog,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: tabController,
          indicatorWeight: 3,
          tabs: [
            Tab(
              text: l10n.yourFoods,
              height: 48,
            ),
            Tab(
              text: l10n.starterList,
              height: 48,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            onPressed: () => _showAddFoodDialog(context, ref),
            tooltip: l10n.addFood,
          ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _FoodList(isStarter: false),
          _FoodList(isStarter: true),
        ],
      ),
    );
  }

  Future<void> _showAddFoodDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _AddFoodDialog(),
    );
  }
}

class _FoodList extends ConsumerWidget {
  final bool isStarter;

  const _FoodList({required this.isStarter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final foodsStream = isStarter
        ? ref.watch(mealsRepositoryProvider).watchStarterFoods()
        : ref.watch(mealsRepositoryProvider).watchUserFoods();

    return StreamBuilder<List<FoodItem>>(
      stream: foodsStream,
      builder: (context, snapshot) {
          // Only show loading on initial load (no data yet)
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const LoadingIndicator();
          }

          final foods = snapshot.data ?? [];

        if (foods.isEmpty) {
          return EmptyState(
            title: isStarter ? l10n.noStarterFoodsAvailable : l10n.buildYourFoodLibrary,
            subtitle: isStarter 
                ? l10n.starterFoodsWillAppear
                : l10n.createCustomFoods,
            icon: Icons.restaurant_menu,
            actionText: isStarter ? null : l10n.addFirstFood,
            actionIcon: isStarter ? null : Icons.add,
            onAction: isStarter ? null : () => _showAddFoodDialog(context, ref),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          itemCount: foods.length,
          itemBuilder: (context, index) {
            final food = foods[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FoodCard(
                food: food,
                onEdit: () => _showEditFoodDialog(context, ref, food),
                onDelete: isStarter ? null : () => _deleteFood(context, ref, food),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddFoodDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _AddFoodDialog(),
    );
  }

  Future<void> _showEditFoodDialog(BuildContext context, WidgetRef ref, FoodItem food) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _AddFoodDialog(food: food),
    );
  }

  Future<void> _deleteFood(BuildContext context, WidgetRef ref, FoodItem food) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
        title: Text(l10n.deleteFood),
        content: Text(l10n.deleteFoodConfirmation(food.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      );
      },
    );

    if (confirmed == true) {
      await ref.read(mealsRepositoryProvider).deleteFood(food.id);
      // Trigger refresh to update UI immediately
      ref.invalidate(mealsRepositoryProvider);
    }
  }
}

class _FoodCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _FoodCard({
    required this.food,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (food.brand != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        food.brand!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                  if (onDelete != null)
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
                    onEdit();
                  } else if (value == 'delete' && onDelete != null) {
                    onDelete!();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Per ${food.unit}:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          NutritionMetricsRow(
            calories: food.kcalPerUnit,
            protein: food.proteinPerUnit,
            carbs: food.carbsPerUnit,
            fat: food.fatPerUnit,
            useShortLabels: true,
          ),
        ],
      ),
    );
  }
}

class _AddFoodDialog extends HookConsumerWidget {
  final FoodItem? food;

  const _AddFoodDialog({this.food});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = useTextEditingController(text: food?.name ?? '');
    final brandController = useTextEditingController(text: food?.brand ?? '');
    final unitController = useTextEditingController(text: food?.unit ?? 'g');
    final kcalController = useTextEditingController(
      text: food?.kcalPerUnit.toString() ?? '',
    );
    final proteinController = useTextEditingController(
      text: food?.proteinPerUnit.toString() ?? '',
    );
    final carbsController = useTextEditingController(
      text: food?.carbsPerUnit.toString() ?? '',
    );
    final fatController = useTextEditingController(
      text: food?.fatPerUnit.toString() ?? '',
    );
    final isLoading = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final isEditing = food != null;

    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? l10n.editFood : l10n.addFood,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Name
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.foodName,
                  counterText: '${nameController.text.length}/${TextLimits.foodNameMaxLength}',
                ),
                maxLength: TextLimits.foodNameMaxLength,
                validator: TextLimits.validateFoodName,
              ),
              const SizedBox(height: AppSpacing.md),

              // Brand
              TextFormField(
                controller: brandController,
                decoration: InputDecoration(
                  labelText: l10n.brandOptional,
                  hintText: 'e.g., Generic, Organic, etc.',
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Unit
              TextFormField(
                controller: unitController,
                decoration: InputDecoration(
                  labelText: l10n.unit,
                  hintText: 'g, ml, piece, cup, etc.',
                ),
                validator: (value) => Validators.required(value, l10n.unit),
              ),
              const SizedBox(height: AppSpacing.md),

              // Nutrition per unit
              Text(
                'Nutrition per ${unitController.text.isEmpty ? l10n.unitDefault : unitController.text}:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: kcalController,
                      decoration: InputDecoration(labelText: l10n.caloriesLabel),
                      keyboardType: TextInputType.number,
                      validator: (value) => Validators.nonNegativeNumber(value, l10n.caloriesLabel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: proteinController,
                      decoration: InputDecoration(labelText: l10n.proteinGrams),
                      keyboardType: TextInputType.number,
                      validator: (value) => Validators.nonNegativeNumber(value, 'Protein'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: carbsController,
                      decoration: InputDecoration(labelText: l10n.carbsGrams),
                      keyboardType: TextInputType.number,
                      validator: (value) => Validators.nonNegativeNumber(value, 'Carbs'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: fatController,
                      decoration: InputDecoration(labelText: l10n.fatGrams),
                      keyboardType: TextInputType.number,
                      validator: (value) => Validators.nonNegativeNumber(value, 'Fat'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isLoading.value ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    text: isEditing ? l10n.update : l10n.add,
                    onPressed: isLoading.value ? null : () => _saveFood(
                      context,
                      ref,
                      formKey,
                      isEditing,
                      food,
                      nameController.text,
                      brandController.text,
                      unitController.text,
                      kcalController.text,
                      proteinController.text,
                      carbsController.text,
                      fatController.text,
                      isLoading,
                    ),
                    isLoading: isLoading.value,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveFood(
    BuildContext context,
    WidgetRef ref,
    GlobalKey<FormState> formKey,
    bool isEditing,
    FoodItem? existingFood,
    String name,
    String brand,
    String unit,
    String kcal,
    String protein,
    String carbs,
    String fat,
    ValueNotifier<bool> isLoading,
  ) async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      final foodItem = isEditing
          ? existingFood!.copyWith(
              name: name.trim(),
              brand: brand.trim().isEmpty ? null : brand.trim(),
              unit: unit.trim(),
              kcalPerUnit: double.parse(kcal),
              proteinPerUnit: double.parse(protein),
              carbsPerUnit: double.parse(carbs),
              fatPerUnit: double.parse(fat),
              updatedAt: DateTime.now(),
            )
          : FoodItem.create(
              name: name.trim(),
              brand: brand.trim().isEmpty ? null : brand.trim(),
              unit: unit.trim(),
              kcalPerUnit: double.parse(kcal),
              proteinPerUnit: double.parse(protein),
              carbsPerUnit: double.parse(carbs),
              fatPerUnit: double.parse(fat),
            );

      if (isEditing) {
        await ref.read(mealsRepositoryProvider).updateFood(foodItem);
      } else {
        await ref.read(mealsRepositoryProvider).createFood(foodItem);
      }

      // Trigger refresh to update UI immediately
      ref.invalidate(mealsRepositoryProvider);

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving food: $e')),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
