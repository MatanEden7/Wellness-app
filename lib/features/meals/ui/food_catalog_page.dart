import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../core/validation.dart';
import '../../../services/language_service.dart';
import '../data/repositories.dart';
import '../../../core/tag_chips.dart';
import '../../../services/profile_filter_service.dart';
import '../../../services/profile_fit.dart';
import '../domain/food_category.dart';
import '../domain/food_tags.dart';
import '../domain/models.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

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
        children: const [
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
      builder: (context) => const _AddFoodDialog(),
    );
  }
}

class _FoodList extends HookConsumerWidget {
  final bool isStarter;

  const _FoodList({required this.isStarter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(currentLanguageProvider);
    // Browsing state, not app state: it should reset when the page closes.
    final searchController = useTextEditingController();
    final search = useState('');
    useEffect(() {
      void listener() => search.value = searchController.text;
      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);
    final selectedCategory = useState<FoodCategory?>(null);

    final foodsStream = isStarter
        ? ref.watch(starterFoodsStreamProvider)
        : ref.watch(userFoodsStreamProvider);

    return StreamBuilder<List<FoodItem>>(
      stream: foodsStream,
      builder: (context, snapshot) {
        // Only show loading on initial load (no data yet)
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const LoadingIndicator();
        }

        final all = snapshot.data ?? [];

        // Hide what clashes with the user's diet/exclusions, unless they
        // asked to see everything. Nothing is deleted -- the toggle in the
        // app bar brings it all back, with a badge naming the reason.
        final profile = ref.watch(filterProfileProvider);
        final showAll = ref.watch(showAllContentProvider);
        final fitting = (profile == null || showAll)
            ? all
            : all.where((f) => ProfileFit.foodFits(f, profile)).toList();
        final hiddenCount = all.length - fitting.length;

        // Which categories to offer as chips: only those that actually have
        // something in them after the diet filter, so a vegan is not shown an
        // empty "Fast Food" tab.
        final present = <FoodCategory>{for (final f in fitting) f.category};
        final categories = [
          for (final c in FoodCategoryLabel.displayOrder)
            if (present.contains(c)) c,
        ];
        // A category that stops existing (the last item in it was deleted, or
        // the diet filter was turned back on) must not leave the list stuck
        // showing nothing.
        final activeCategory = present.contains(selectedCategory.value)
            ? selectedCategory.value
            : null;

        final foods = fitting
            .where((f) => activeCategory == null || f.category == activeCategory)
            .where((f) => f.matchesSearch(search.value))
            .toList();

        if (fitting.isEmpty) {
          return EmptyState(
            title: isStarter
                ? l10n.noStarterFoodsAvailable
                : l10n.buildYourFoodLibrary,
            subtitle: isStarter
                ? l10n.starterFoodsWillAppear
                : l10n.createCustomFoods,
            icon: Icons.restaurant_menu,
            actionText: isStarter ? null : l10n.addFirstFood,
            actionIcon: isStarter ? null : Icons.add,
            onAction: isStarter ? null : () => _showAddFoodDialog(context, ref),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchFoods,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: search.value.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: l10n.cancel,
                          onPressed: searchController.clear,
                        ),
                ),
              ),
            ),
            if (categories.length > 1)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final category in [null, ...categories])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category == null
                              ? l10n.categoryAll
                              : category.label(language)),
                          selected: activeCategory == category,
                          onSelected: (_) =>
                              selectedCategory.value = category,
                        ),
                      ),
                  ],
                ),
              ),
            if (hiddenCount > 0)
              _HiddenBanner(
                count: hiddenCount,
                onShowAll: () =>
                    ref.read(showAllContentProvider.notifier).state = true,
              ),
            if (showAll && profile != null)
              _ShowingAllBanner(
                onFilter: () =>
                    ref.read(showAllContentProvider.notifier).state = false,
              ),
            if (foods.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.noFoodsAvailable,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              )
            else
              Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                itemCount: foods.length,
                itemBuilder: (context, index) {
                  final food = foods[index];
                  final reason = profile == null
                      ? null
                      : fitFailureLabel(ProfileFit.foodFit(food, profile));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FoodCard(
                      food: food,
                      language: language,
                      mismatchReason: reason,
                      onEdit: () => _showEditFoodDialog(context, ref, food),
                      onDelete: isStarter
                          ? null
                          : () => _deleteFood(context, ref, food),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddFoodDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _AddFoodDialog(),
    );
  }

  Future<void> _showEditFoodDialog(
      BuildContext context, WidgetRef ref, FoodItem food) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _AddFoodDialog(food: food),
    );
  }

  Future<void> _deleteFood(
      BuildContext context, WidgetRef ref, FoodItem food) async {
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
  final AppLanguage language;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  /// Non-null only when this row is being shown despite not suiting the
  /// profile -- i.e. the user turned "show all" on. Names the clash.
  final String? mismatchReason;

  const _FoodCard({
    required this.food,
    required this.language,
    required this.onEdit,
    this.mismatchReason,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mismatchReason != null) ...[
            MismatchBadge(mismatchReason!),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.displayName(language),
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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
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
    // Seeded foods ship tagged; anything the user adds starts untagged,
    // which ProfileFit reads as "fits everyone". Letting them label it here
    // is what keeps their own catalog filterable.
    final tags = useState<Set<FoodTag>>(food?.tags ?? <FoodTag>{});

    final isEditing = food != null;

    // The fields scroll; the title and the action row never do.
    //
    // This used to be a bare Column with no scroll view at all. On a 402x874
    // phone the content is ~840pt tall inside a ~682pt dialog, so it
    // overflowed by 159 and pushed the Add button off the bottom of the
    // screen -- with nothing to scroll, adding or editing a custom food was
    // simply impossible on a real device. Flexible (not Expanded) keeps the
    // dialog only as tall as it needs to be on roomier screens.
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
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

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: l10n.foodName,
                            counterText:
                                '${nameController.text.length}/${TextLimits.foodNameMaxLength}',
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
                          validator: (value) =>
                              Validators.required(value, l10n.unit),
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
                                decoration: InputDecoration(
                                    labelText: l10n.caloriesLabel),
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    Validators.nonNegativeNumber(
                                        value, l10n.caloriesLabel),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextFormField(
                                controller: proteinController,
                                decoration: InputDecoration(
                                    labelText: l10n.proteinGrams),
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    Validators.nonNegativeNumber(
                                        value, 'Protein'),
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
                                decoration:
                                    InputDecoration(labelText: l10n.carbsGrams),
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    Validators.nonNegativeNumber(
                                        value, 'Carbs'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextFormField(
                                controller: fatController,
                                decoration:
                                    InputDecoration(labelText: l10n.fatGrams),
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    Validators.nonNegativeNumber(value, 'Fat'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        TagChips<FoodTag>(
                          title: 'Contains',
                          subtitle:
                              'Used to hide this food when it clashes with your '
                              'diet or exclusions. Leave blank if it contains none.',
                          options: FoodTagLabel.allergens,
                          selected: tags.value,
                          labelOf: (t) => t.label,
                          onChanged: (next) => tags.value = {
                            ...next,
                            // Preserve the animal-origin tags the other group owns.
                            ...tags.value
                                .where(FoodTagLabel.animalOrigin.contains),
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TagChips<FoodTag>(
                          title: 'Animal origin',
                          subtitle: 'Used for plant-based diets.',
                          options: FoodTagLabel.animalOrigin,
                          selected: tags.value,
                          labelOf: (t) => t.label,
                          onChanged: (next) => tags.value = {
                            ...next,
                            ...tags.value
                                .where(FoodTagLabel.allergens.contains),
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading.value
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      text: isEditing ? l10n.update : l10n.add,
                      onPressed: isLoading.value
                          ? null
                          : () => _saveFood(
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
                                tags.value,
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
    Set<FoodTag> tags,
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
              tags: tags,
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
            ).copyWith(tags: tags);

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

/// Shown above a filtered list when items were hidden, with a one-tap
/// escape hatch. Counting them is the point: silently showing a shorter
/// list looks like missing data, which is what makes hiding feel broken.
class _HiddenBanner extends StatelessWidget {
  const _HiddenBanner({required this.count, required this.onShowAll});

  final int count;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Row(
        children: [
          Icon(Icons.filter_alt_outlined,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count hidden by your profile',
              style: theme.textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onShowAll, child: const Text('Show all')),
        ],
      ),
    );
  }
}

class _ShowingAllBanner extends StatelessWidget {
  const _ShowingAllBanner({required this.onFilter});

  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Row(
        children: [
          Icon(Icons.visibility_outlined,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Showing everything', style: theme.textTheme.bodySmall),
          ),
          TextButton(onPressed: onFilter, child: const Text('Filter')),
        ],
      ),
    );
  }
}

/// The "why is this here" badge on a revealed, non-fitting row.
class MismatchBadge extends StatelessWidget {
  const MismatchBadge(this.reason, {super.key});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        reason,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onErrorContainer),
      ),
    );
  }
}
