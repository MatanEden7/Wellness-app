import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../routing/routes.dart';
import '../../../services/language_service.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

class MealTemplatesPage extends ConsumerWidget {
  const MealTemplatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(currentLanguageProvider);
    final templatesAsync = ref.watch(allMealTemplatesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.mealTemplates,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: () => context.pop(),
          tooltip: l10n.backToDashboard,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            onPressed: () => context.push(Routes.mealTemplateEditor),
            tooltip: l10n.createMealTemplate,
          ),
        ],
      ),
      body: StreamBuilder<List<MealTemplate>>(
        stream: templatesAsync,
        builder: (context, snapshot) {
          // Only log on state changes or when we have data
          if (snapshot.connectionState != ConnectionState.waiting) {
            debugPrint('[TEMPLATES-UI] 📺 Stream update: hasData=${snapshot.hasData}, templates=${snapshot.data?.length ?? 0}');
          }
          
          // Only show loading on initial load (no data yet)
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const LoadingIndicator();
          }

          final templates = snapshot.data ?? [];

          if (templates.isEmpty) {
            return EmptyState(
              title: l10n.noMealTemplates,
              subtitle: l10n.createMealTemplateToReuse,
              icon: Icons.bookmark_border,
              actionText: l10n.createFirstMealTemplate,
              actionIcon: Icons.add,
              onAction: () => context.push(Routes.mealTemplateEditor),
            );
          }

          return ListView.builder(
            // Extra bottom padding so the last card's buttons aren't
            // obscured by the floating "Create" FAB.
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MealTemplateCard(
                  template: template,
                  language: language,
                  onUseNow: () => _useMealTemplate(context, ref, template),
                  onEdit: () => context.push('/meals/templates/${template.id}'),
                  onDelete: () => _deleteTemplate(context, ref, template),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.mealTemplateEditor),
        icon: const Icon(Icons.add),
        label: Text(l10n.createMealTemplate),
        elevation: 4,
      ),
    );
  }

  Future<void> _useMealTemplate(BuildContext context, WidgetRef ref, MealTemplate template) async {
    final l10n = AppLocalizations.of(context)!;
    
    // Show date picker
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: AppDateUtils.today,
      firstDate: DateTime(2020),
      lastDate: AppDateUtils.today.add(const Duration(days: 365)),
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
        final food = await ref.read(mealsRepositoryProvider).getFoodById(templateItem.foodId);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.mealCreatedFromTemplate)),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Future<void> _deleteTemplate(BuildContext context, WidgetRef ref, MealTemplate template) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTemplate),
        content: Text('${l10n.areYouSure} "${template.name}"?'),
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
      ),
    );

    if (confirmed == true) {
      await ref.read(mealsRepositoryProvider).deleteMealTemplate(template.id);
      ref.invalidate(mealsRepositoryProvider);
    }
  }
}

class _MealTemplateCard extends StatelessWidget {
  final MealTemplate template;
  final AppLanguage language;
  final VoidCallback onUseNow;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  template.displayName(language),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'use',
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.useNow),
                      ],
                    ),
                  ),
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
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'use':
                      onUseNow();
                      break;
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
              ),
            ],
          ),
          if (template.description != null) ...[
            const SizedBox(height: 8),
            Text(
              template.displayDescription(language) ?? template.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 14,
              ),
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
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${template.items.length} item${template.items.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall,
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
    );
  }
}

