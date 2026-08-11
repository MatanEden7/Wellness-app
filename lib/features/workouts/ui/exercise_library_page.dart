import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/ios/app_scaffold.dart';
import '../../../core/ios/controls.dart';
import '../../../core/ios/sheets.dart';
import '../../../core/ios/swipe_row.dart';
import '../../../core/theme.dart';
import '../../../core/ui_constants.dart';
import '../../../core/utils.dart';
import '../../../core/widgets.dart';
import '../../../services/language_service.dart';
import '../data/repositories.dart';
import '../../../core/tag_chips.dart';
import '../../../services/profile_filter_service.dart';
import '../../../services/profile_fit.dart';
import '../../meals/ui/food_catalog_page.dart' show MismatchBadge;
import '../domain/exercise_tags.dart';
import '../domain/models.dart';

/// The exercise library -- the workouts counterpart of the food catalog, and
/// now built the same way: search pinned under the title, a muscle-group
/// filter bar, then the rows.
///
/// It had neither search nor filtering before, which was survivable at 58
/// exercises and is not at 115. The food catalog had both; there was no
/// reason for the two to differ.
class ExerciseLibraryPage extends HookConsumerWidget {
  const ExerciseLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(currentLanguageProvider);
    final exercisesStream = ref.watch(exercisesStreamProvider);

    // Browsing state, not app state: it resets when the page closes -- see
    // the identical reasoning in the food catalog.
    final searchController = useTextEditingController();
    final search = useState('');
    useEffect(() {
      void listener() => search.value = searchController.text;
      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);
    final selectedMuscle = useState<String?>(null);

    return AppScaffold(
      title: l10n.exerciseLibrary,
      actions: [
        NavBarAction(
          icon: CupertinoIcons.add,
          tooltip: l10n.addExerciseTooltip,
          onPressed: () => _openEditor(context),
        ),
      ],
      pinnedHeader: Padding(
        padding: const EdgeInsets.fromLTRB(
          UIConstants.screenHorizontalPadding,
          4,
          UIConstants.screenHorizontalPadding,
          8,
        ),
        child: AppSearchField(
          controller: searchController,
          placeholder: l10n.searchExercises,
        ),
      ),
      slivers: [
        StreamBuilder<List<Exercise>>(
          stream: exercisesStream,
          builder: (context, snapshot) {
            // First load only -- see the workouts home screen.
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingIndicator(),
              );
            }

            final all = snapshot.data ?? [];

            // Same contract as the food catalog: hide what the user can't do,
            // never delete it, and make the escape hatch one tap away.
            final profile = ref.watch(filterProfileProvider);
            final showAll = ref.watch(showAllContentProvider);
            final fitting = (profile == null || showAll)
                ? all
                : all
                    .where((e) => ProfileFit.exerciseFits(e, profile))
                    .toList();
            final hiddenCount = all.length - fitting.length;

            if (fitting.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: l10n.buildYourExerciseLibrary,
                  subtitle: l10n.addExercisesToCreateWorkouts,
                  icon: Icons.fitness_center,
                  actionText: l10n.addFirstExercise,
                  actionIcon: Icons.add,
                  onAction: () => _openEditor(context),
                ),
              );
            }

            // Only offer muscle groups that something in the filtered list
            // actually belongs to, so a user with a shoulder injury is not
            // shown an empty "Shoulders" pill.
            final muscles = <String>{
              for (final e in fitting)
                if (e.displayPrimaryMuscle(language) != null)
                  e.displayPrimaryMuscle(language)!,
            }.toList()
              ..sort();
            // A group that stops existing must not leave the list stuck
            // showing nothing.
            final activeMuscle = muscles.contains(selectedMuscle.value)
                ? selectedMuscle.value
                : null;

            final query = search.value.trim().toLowerCase();
            final exercises = fitting
                .where((e) =>
                    activeMuscle == null ||
                    e.displayPrimaryMuscle(language) == activeMuscle)
                .where((e) =>
                    query.isEmpty ||
                    e.name.toLowerCase().contains(query) ||
                    (e.nameHe?.toLowerCase().contains(query) ?? false) ||
                    (e.primaryMuscle?.toLowerCase().contains(query) ?? false))
                .toList();

            return SliverMainAxisGroup(
              slivers: [
                if (muscles.length > 1)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: AppFilterBar<String>(
                        options: muscles,
                        value: activeMuscle,
                        allLabel: l10n.categoryAll,
                        labelOf: (m) => m,
                        onChanged: (next) => selectedMuscle.value = next,
                      ),
                    ),
                  ),
                if (hiddenCount > 0)
                  SliverToBoxAdapter(
                    child: FilterBanner(
                      icon: Icons.filter_alt_outlined,
                      message: '$hiddenCount hidden by your profile',
                      actionLabel: 'Show all',
                      onAction: () => ref
                          .read(showAllContentProvider.notifier)
                          .state = true,
                    ),
                  ),
                if (showAll && profile != null)
                  SliverToBoxAdapter(
                    child: FilterBanner(
                      icon: Icons.visibility_outlined,
                      message: 'Showing everything',
                      actionLabel: l10n.filter,
                      onAction: () => ref
                          .read(showAllContentProvider.notifier)
                          .state = false,
                    ),
                  ),
                if (exercises.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Text(
                        l10n.noExercisesMatch,
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
                      itemCount: exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        final reason = profile == null
                            ? null
                            : fitFailureLabel(
                                ProfileFit.exerciseFit(exercise, profile));
                        return _ExerciseCard(
                          exercise: exercise,
                          language: language,
                          mismatchReason: reason,
                          onEdit: () => _openEditor(context, exercise: exercise),
                          onDelete: () => _deleteExercise(ref, exercise),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _openEditor(BuildContext context, {Exercise? exercise}) {
    return pushModalPage<void>(context, ExerciseEditorPage(exercise: exercise));
  }

  Future<void> _deleteExercise(WidgetRef ref, Exercise exercise) async {
    await ref.read(exercisesRepositoryProvider).deleteExercise(exercise.id);
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final AppLanguage language;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  /// Non-null only when shown despite not suiting the profile -- see the
  /// food catalog's equivalent.
  final String? mismatchReason;

  const _ExerciseCard({
    required this.exercise,
    required this.language,
    required this.onEdit,
    required this.onDelete,
    this.mismatchReason,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = exercise.displayName(language);

    return SwipeActionRow(
      rowKey: ValueKey(exercise.id),
      deleteLabel: l10n.delete,
      confirmTitle: l10n.deleteExercise,
      confirmMessage: l10n.deleteExerciseConfirmation(name),
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
                    tooltip: l10n.exercises,
                    actions: [
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
                            title: l10n.deleteExercise,
                            message: l10n.deleteExerciseConfirmation(name),
                            confirmLabel: l10n.delete,
                          );
                          if (confirmed) await onDelete();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (exercise.primaryMuscle != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.accessibility_new,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      exercise.displayPrimaryMuscle(language) ??
                          exercise.primaryMuscle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.scale,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${l10n.weightUnit}: ${exercise.unit}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (exercise.notes != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  exercise.notes!,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Add/edit exercise, as a full-screen modal page.
///
/// Was a `Dialog` capped at 85% height with everything scrolling inside it;
/// the form is tall enough (four fields plus two tag groups) that the Save
/// button repeatedly ended up unreachable on a phone.
class ExerciseEditorPage extends HookConsumerWidget {
  final Exercise? exercise;

  const ExerciseEditorPage({super.key, this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = useTextEditingController(text: exercise?.name ?? '');
    final muscleController =
        useTextEditingController(text: exercise?.primaryMuscle ?? '');
    final unit = useState(exercise?.unit ?? 'kg');
    final notesController =
        useTextEditingController(text: exercise?.notes ?? '');
    final isLoading = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    // See the food editor: untagged content fits every profile, so without
    // these the user's own exercises escape equipment/injury filtering.
    final equipment =
        useState<Set<Equipment>>(exercise?.equipment ?? <Equipment>{});
    final contraindicated =
        useState<Set<BodyPart>>(exercise?.contraindicatedFor ?? <BodyPart>{});

    final isEditing = exercise != null;

    return AppFormPage(
      title: isEditing ? l10n.editExercise : l10n.addExerciseTooltip,
      confirm: NavBarAction(
        label: isEditing ? l10n.update : l10n.add,
        tooltip: isEditing ? l10n.update : l10n.add,
        isProminent: true,
        onPressed: isLoading.value
            ? null
            : () => _save(
                  context,
                  ref,
                  formKey,
                  nameController.text,
                  muscleController.text,
                  unit.value,
                  notesController.text,
                  equipment.value,
                  contraindicated.value,
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
                labelText: l10n.exerciseName,
                hintText: 'e.g., Bench Press, Squats',
              ),
              maxLength: 40,
              validator: (value) =>
                  Validators.required(value, l10n.exerciseName),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: muscleController,
              decoration: InputDecoration(
                labelText: l10n.primaryMuscleOptional,
                hintText: 'e.g., Chest, Legs, Back',
              ),
              maxLength: 40,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.weightUnit, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            AppSegmented<String>(
              value: unit.value,
              onChanged: (next) => unit.value = next,
              segments: {
                'kg': l10n.kilogramsKg,
                'lb': l10n.poundsLb,
                'bodyweight': l10n.bodyweight,
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: l10n.notesOptional,
                hintText: 'Form cues, variations, etc.',
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: AppSpacing.lg),
            TagChips<Equipment>(
              title: 'Equipment needed',
              subtitle: 'Pick every option this can be done with. Leave '
                  'blank and it will be treated as always available.',
              options: Equipment.values,
              selected: equipment.value,
              labelOf: (e) => e.label,
              onChanged: (next) => equipment.value = next,
            ),
            const SizedBox(height: AppSpacing.md),
            TagChips<BodyPart>(
              title: 'Avoid with injury to',
              subtitle: 'This will be hidden for anyone reporting one of '
                  'these injuries.',
              options: BodyPart.values,
              selected: contraindicated.value,
              labelOf: (b) => b.label,
              onChanged: (next) => contraindicated.value = next,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    GlobalKey<FormState> formKey,
    String name,
    String muscle,
    String unit,
    String notes,
    Set<Equipment> equipment,
    Set<BodyPart> contraindicated,
    ValueNotifier<bool> isLoading,
  ) async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      final exerciseItem = exercise != null
          ? exercise!.copyWith(
              name: name.trim(),
              primaryMuscle: muscle.trim().isEmpty ? null : muscle.trim(),
              unit: unit,
              notes: notes.trim().isEmpty ? null : notes.trim(),
              equipment: equipment,
              contraindicatedFor: contraindicated,
            )
          : Exercise.create(
              name: name.trim(),
              primaryMuscle: muscle.trim().isEmpty ? null : muscle.trim(),
              unit: unit,
              notes: notes.trim().isEmpty ? null : notes.trim(),
            ).copyWith(
              equipment: equipment,
              contraindicatedFor: contraindicated,
            );

      if (exercise != null) {
        await ref
            .read(exercisesRepositoryProvider)
            .updateExercise(exerciseItem);
      } else {
        await ref
            .read(exercisesRepositoryProvider)
            .createExercise(exerciseItem);
      }

      // No invalidate needed: insert/update now notify the exercises stream,
      // and tearing the cached stream down here would reset the list to its
      // loading state.

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving exercise: $e')),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
