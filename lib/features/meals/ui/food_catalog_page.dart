import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/ios/app_scaffold.dart'; // NavBarAction used in AppFormPage.confirm
import '../../../shell/platform_page.dart';
import '../../../core/ios/controls.dart';
import '../../../core/ios/sheets.dart';
import '../../../core/ios/swipe_row.dart';
import '../../../core/theme.dart';
import '../../../core/ui_constants.dart';
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
import '../../../core/design/surfaces.dart';
import '../../../core/design/tokens.dart';
import '../../../core/ios/feedback.dart';
import '../domain/food_nutrition_math.dart';

/// Which half of the catalog is showing.
enum _CatalogScope { user, starter }

/// The food catalog -- the meals counterpart of the exercise library, and
/// built the same way: a segmented control for scope, search pinned under
/// it, a category filter bar, then the rows.
///
/// The scope used to be a Material `TabBar` welded to the app bar, which put
/// a second bar of a different shape directly under the title.
class FoodCatalogPage extends HookConsumerWidget {
  const FoodCatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scope = useState(_CatalogScope.user);

    // Browsing state, not app state: it resets when the page closes.
    final searchController = useTextEditingController();
    final search = useState('');
    useEffect(() {
      void listener() => search.value = searchController.text;
      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);
    final selectedCategory = useState<FoodCategory?>(null);

    return PlatformPage(
      chrome: PageChrome(
        title: l10n.foodCatalog,
        actions: [
          ChromeAction(
            icon: CupertinoIcons.add,
            tooltip: l10n.addFood,
            onPressed: () =>
                pushModalPage<void>(context, const FoodEditorPage()),
          ),
        ],
        pinnedHeaderHeight: 104,
        pinnedHeader: Padding(
          padding: const EdgeInsets.fromLTRB(
            UIConstants.screenHorizontalPadding,
            2,
            UIConstants.screenHorizontalPadding,
            8,
          ),
          child: Column(
            children: [
              AppSegmented<_CatalogScope>(
                value: scope.value,
                onChanged: (next) => scope.value = next,
                segments: {
                  _CatalogScope.user: l10n.yourFoods,
                  _CatalogScope.starter: l10n.starterList,
                },
              ),
              const SizedBox(height: 8),
              AppSearchField(
                controller: searchController,
                placeholder: l10n.searchFoods,
              ),
            ],
          ),
        ),
      ),
      slivers: [
        _FoodList(
          isStarter: scope.value == _CatalogScope.starter,
          search: search.value,
          selectedCategory: selectedCategory,
        ),
      ],
    );
  }
}

class _FoodList extends ConsumerWidget {
  final bool isStarter;
  final String search;
  final ValueNotifier<FoodCategory?> selectedCategory;

  const _FoodList({
    required this.isStarter,
    required this.search,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(currentLanguageProvider);

    final foodsStream = isStarter
        ? ref.watch(starterFoodsStreamProvider)
        : ref.watch(userFoodsStreamProvider);

    return StreamBuilder<List<FoodItem>>(
      stream: foodsStream,
      builder: (context, snapshot) {
        // First load only -- see the meals home screen.
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: LoadingIndicator(),
          );
        }

        final all = snapshot.data ?? [];

        // Hide what clashes with the user's diet/exclusions, unless they
        // asked to see everything. Nothing is deleted -- the banner's button
        // brings it all back, with a badge naming the reason.
        final profile = ref.watch(filterProfileProvider);
        final showAll = ref.watch(showAllContentProvider);
        final fitting = (profile == null || showAll)
            ? all
            : all.where((f) => ProfileFit.foodFits(f, profile)).toList();
        final hiddenCount = all.length - fitting.length;

        if (fitting.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              title: isStarter
                  ? l10n.noStarterFoodsAvailable
                  : l10n.buildYourFoodLibrary,
              subtitle: isStarter
                  ? l10n.starterFoodsWillAppear
                  : l10n.createCustomFoods,
              icon: Icons.restaurant_menu,
              actionText: isStarter ? null : l10n.addFirstFood,
              actionIcon: isStarter ? null : Icons.add,
              onAction: isStarter
                  ? null
                  : () => pushModalPage<void>(context, const FoodEditorPage()),
            ),
          );
        }

        // Which categories to offer: only those that actually have something
        // in them after the diet filter, so a vegan is not shown an empty
        // "Fast Food" pill.
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
            .where(
                (f) => activeCategory == null || f.category == activeCategory)
            .where((f) => f.matchesSearch(search))
            .toList();

        return SliverMainAxisGroup(
          slivers: [
            if (categories.length > 1)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: AppFilterBar<FoodCategory>(
                    options: categories,
                    value: activeCategory,
                    allLabel: l10n.categoryAll,
                    labelOf: (c) => c.label(language),
                    onChanged: (next) => selectedCategory.value = next,
                  ),
                ),
              ),
            if (hiddenCount > 0)
              SliverToBoxAdapter(
                child: FilterBanner(
                  icon: Icons.filter_alt_outlined,
                  message: l10n.hiddenByProfile(hiddenCount),
                  actionLabel: l10n.showAllContent,
                  onAction: () =>
                      ref.read(showAllContentProvider.notifier).state = true,
                ),
              ),
            if (showAll && profile != null)
              SliverToBoxAdapter(
                child: FilterBanner(
                  icon: Icons.visibility_outlined,
                  message:
                      AppLocalizations.of(context)!.filterShowingEverything,
                  actionLabel: l10n.filter,
                  onAction: () =>
                      ref.read(showAllContentProvider.notifier).state = false,
                ),
              ),
            if (foods.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(Space.xxxl),
                  child: Text(
                    l10n.noFoodsAvailable,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  UIConstants.screenHorizontalPadding,
                  UIConstants.cardSpacing,
                  UIConstants.screenHorizontalPadding,
                  UIConstants.sectionSpacing,
                ),
                sliver: SliverList.builder(
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    final reason = profile == null
                        ? null
                        : fitFailureLabel(
                            ProfileFit.foodFit(food, profile), language);
                    return _FoodCard(
                      food: food,
                      language: language,
                      mismatchReason: reason,
                      onEdit: () => pushModalPage<void>(
                        context,
                        FoodEditorPage(food: food),
                      ),
                      onDelete: isStarter ? null : () => _deleteFood(ref, food),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFood(WidgetRef ref, FoodItem food) async {
    await ref.read(mealsRepositoryProvider).deleteFood(food.id);
    // Trigger refresh to update UI immediately
    ref.invalidate(mealsRepositoryProvider);
  }
}

class _FoodCard extends StatelessWidget {
  final FoodItem food;
  final AppLanguage language;
  final VoidCallback onEdit;

  /// Null for starter-catalog rows, which cannot be deleted.
  final Future<void> Function()? onDelete;

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
    final theme = Theme.of(context);
    final name = food.name;

    return SwipeActionRow(
      rowKey: ValueKey(food.id),
      deleteLabel: l10n.delete,
      confirmTitle: l10n.deleteFood,
      confirmMessage: l10n.deleteFoodConfirmation(name),
      onDelete: onDelete,
      onEdit: onEdit,
      editLabel: l10n.edit,
      actions: [
        AppAction(
          label: l10n.edit,
          icon: CupertinoIcons.pencil,
          onPressed: onEdit,
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          onTap: onEdit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mismatchReason != null) ...[
                MismatchBadge(mismatchReason!),
                const SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
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
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  AppRowMenuButton(
                    title: name,
                    tooltip: l10n.foodCatalog,
                    actions: [
                      AppAction(
                        label: l10n.edit,
                        icon: CupertinoIcons.pencil,
                        onPressed: onEdit,
                      ),
                      if (onDelete != null)
                        AppAction(
                          label: l10n.delete,
                          icon: CupertinoIcons.delete,
                          isDestructive: true,
                          onPressed: () async {
                            final confirmed = await showAppConfirm(
                              context: context,
                              title: l10n.deleteFood,
                              message: l10n.deleteFoodConfirmation(name),
                              confirmLabel: l10n.delete,
                            );
                            if (confirmed) await onDelete!();
                          },
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.perUnit(
                    FoodNutritionMath.localizedUnit(language, food.unit)),
                style: theme.textTheme.bodySmall,
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
        ),
      ),
    );
  }
}

/// Add/edit food, as a full-screen modal page.
///
/// Was a centred `Dialog` capped at 85% of the screen: on a 402x874 phone its
/// content was ~840pt tall, so the Add button ended up off the bottom of the
/// screen with nothing to scroll. A modal page has the whole screen.
class FoodEditorPage extends HookConsumerWidget {
  final FoodItem? food;

  const FoodEditorPage({super.key, this.food});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(currentLanguageProvider);
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

    return AppFormPage(
      title: isEditing ? l10n.editFood : l10n.addFood,
      confirm: NavBarAction(
        label: isEditing ? l10n.update : l10n.add,
        tooltip: isEditing ? l10n.update : l10n.add,
        isProminent: true,
        onPressed: isLoading.value
            ? null
            : () => _saveFood(
                  context,
                  ref,
                  formKey,
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
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.foodName,
                counterText:
                    '${nameController.text.length}/${TextLimits.foodNameMaxLength}',
              ),
              maxLength: TextLimits.foodNameMaxLength,
              validator: (v) => TextLimits.validateFoodName(v, l10n),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: brandController,
              decoration: InputDecoration(
                labelText: l10n.brandOptional,
                hintText: AppLocalizations.of(context)!.foodBrandHint,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: unitController,
              decoration: InputDecoration(
                labelText: l10n.unit,
                hintText: AppLocalizations.of(context)!.foodUnitHint,
              ),
              validator: (value) => Validators.required(value, l10n.unit, l10n),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context)!.nutritionPerUnit(
                  unitController.text.isEmpty
                      ? AppLocalizations.of(context)!.unitDefault
                      : unitController.text),
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
                    validator: (value) => Validators.nonNegativeNumber(
                        value, l10n.caloriesLabel, l10n),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: proteinController,
                    decoration: InputDecoration(labelText: l10n.proteinGrams),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        Validators.nonNegativeNumber(value, l10n.protein, l10n),
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
                    validator: (value) =>
                        Validators.nonNegativeNumber(value, l10n.carbs, l10n),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: fatController,
                    decoration: InputDecoration(labelText: l10n.fatGrams),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        Validators.nonNegativeNumber(value, l10n.fat, l10n),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TagChips<FoodTag>(
              title: AppLocalizations.of(context)!.foodTagsContains,
              subtitle: AppLocalizations.of(context)!.foodTagsContainsHelp,
              options: FoodTagLabel.allergens,
              selected: tags.value,
              labelOf: (t) => t.label(language),
              onChanged: (next) => tags.value = {
                ...next,
                // Preserve the animal-origin tags the other group owns.
                ...tags.value.where(FoodTagLabel.animalOrigin.contains),
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TagChips<FoodTag>(
              title: AppLocalizations.of(context)!.foodTagsAnimalOrigin,
              subtitle: AppLocalizations.of(context)!.foodTagsAnimalOriginHelp,
              options: FoodTagLabel.animalOrigin,
              selected: tags.value,
              labelOf: (t) => t.label(language),
              onChanged: (next) => tags.value = {
                ...next,
                ...tags.value.where(FoodTagLabel.allergens.contains),
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveFood(
    BuildContext context,
    WidgetRef ref,
    GlobalKey<FormState> formKey,
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
      final foodItem = food != null
          ? food!.copyWith(
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

      if (food != null) {
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
        showAppError(
            context, AppLocalizations.of(context)!.errorSavingFood('$e'));
      }
    } finally {
      isLoading.value = false;
    }
  }
}

/// The "why is this here" badge on a revealed, non-fitting row.
class MismatchBadge extends StatelessWidget {
  const MismatchBadge(this.reason, {super.key});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ContentSurface.tinted(
      color: theme.colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.sm, vertical: Space.xxs),
        child: Text(
          reason,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}
