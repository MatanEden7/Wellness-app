import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shell/platform_page.dart';
import '../../../core/ios/sheets.dart';
import '../../../core/ios/swipe_row.dart';
import '../../../core/theme.dart';
import '../../../core/ui_constants.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../routing/routes.dart';
import '../../../services/language_service.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import '../../../core/ios/feedback.dart';
import '../../../core/ios/pickers.dart';

/// Saved meal templates. Structurally identical to the workout templates
/// screen -- same rows, same primary button, same actions.
class MealTemplatesPage extends ConsumerWidget {
  const MealTemplatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(currentLanguageProvider);
    final templatesStream = ref.watch(allMealTemplatesStreamProvider);

    return PlatformPage(
      chrome: PageChrome(
        title: l10n.mealTemplates,
        actions: [
          ChromeAction(
            icon: CupertinoIcons.add,
            tooltip: l10n.createMealTemplate,
            onPressed: () => context.push(Routes.mealTemplateEditor),
          ),
        ],
      ),
      slivers: [
        StreamBuilder<List<MealTemplate>>(
          stream: templatesStream,
          builder: (context, snapshot) {
            // First load only -- see the meals home screen.
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingIndicator(),
              );
            }

            final templates = snapshot.data ?? [];

            if (templates.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: l10n.noMealTemplates,
                  subtitle: l10n.createMealTemplateToReuse,
                  icon: Icons.bookmark_border,
                  actionText: l10n.createFirstMealTemplate,
                  actionIcon: Icons.add,
                  onAction: () => context.push(Routes.mealTemplateEditor),
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
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return _MealTemplateCard(
                    template: template,
                    language: language,
                    onUseNow: () => _useMealTemplate(context, ref, template),
                    onEdit: () =>
                        context.push('${Routes.mealTemplates}/${template.id}'),
                    onDelete: () => _deleteTemplate(ref, template),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _useMealTemplate(
      BuildContext context, WidgetRef ref, MealTemplate template) async {
    final l10n = AppLocalizations.of(context)!;

    final selectedDate = await showAppDatePicker(
      context: context,
      initial: AppDateUtils.today,
      first: DateTime(2020),
      last: AppDateUtils.today.add(const Duration(days: 365)),
    );

    if (selectedDate == null) return;

    try {
      // Create meal from template
      final dateInt = AppDateUtils.dateToInt(selectedDate);
      final meal = Meal.create(
        date: dateInt,
        name: template.name,
        note: template.description,
      );

      // Calculate meal items with nutrition
      final items = <MealItem>[];
      for (final templateItem in template.items) {
        final food = await ref
            .read(mealsRepositoryProvider)
            .getFoodById(templateItem.foodId);
        if (food != null) {
          items.add(MealItem.create(
            mealId: meal.id,
            foodId: templateItem.foodId,
            amount: templateItem.amount,
            food: food,
          ));
        }
      }

      final mealWithItems = meal.copyWith(items: items);
      await ref.read(mealsRepositoryProvider).createMeal(mealWithItems);

      ref.invalidate(mealsRepositoryProvider);

      if (context.mounted) {
        showAppSuccess(context, l10n.mealCreatedFromTemplate);
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        showAppError(context, '${l10n.error}: $e');
      }
    }
  }

  Future<void> _deleteTemplate(WidgetRef ref, MealTemplate template) async {
    await ref.read(mealsRepositoryProvider).deleteMealTemplate(template.id);
    ref.invalidate(mealsRepositoryProvider);
  }
}

class _MealTemplateCard extends StatelessWidget {
  final MealTemplate template;
  final AppLanguage language;
  final VoidCallback onUseNow;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  const _MealTemplateCard({
    required this.template,
    required this.language,
    required this.onUseNow,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = template.name;

    return SwipeActionRow(
      rowKey: ValueKey(template.id),
      deleteLabel: l10n.delete,
      confirmTitle: l10n.deleteTemplate,
      confirmMessage: l10n.deleteTemplateConfirmation(name),
      onDelete: onDelete,
      onEdit: onEdit,
      editLabel: l10n.edit,
      actions: [
        AppAction(
          label: l10n.useNow,
          icon: CupertinoIcons.add_circled,
          isDefault: true,
          onPressed: onUseNow,
        ),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppRowMenuButton(
                    title: name,
                    tooltip: l10n.mealTemplates,
                    actions: [
                      AppAction(
                        label: l10n.useNow,
                        icon: CupertinoIcons.add_circled,
                        isDefault: true,
                        onPressed: onUseNow,
                      ),
                      AppAction(
                        label: l10n.edit,
                        icon: CupertinoIcons.pencil,
                        onPressed: onEdit,
                      ),
                      AppAction(
                        label: l10n.delete,
                        icon: CupertinoIcons.delete,
                        isDestructive: true,
                        onPressed: () async {
                          final confirmed = await showAppConfirm(
                            context: context,
                            title: l10n.deleteTemplate,
                            message: l10n.deleteTemplateConfirmation(name),
                            confirmLabel: l10n.delete,
                          );
                          if (confirmed) await onDelete();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (template.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  template.description ?? template.description!,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.itemsCount(template.items.length),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: l10n.useNow,
                  onPressed: onUseNow,
                  icon: Icons.add_circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
