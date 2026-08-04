import 'package:flutter/material.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../services/language_service.dart';
import '../data/repositories.dart';
import '../domain/models.dart';

class ExerciseLibraryPage extends HookConsumerWidget {
  const ExerciseLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(currentLanguageProvider);
    final exercisesAsync = ref.watch(exercisesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.exerciseLibrary,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            onPressed: () => _showAddExerciseDialog(context, ref),
            tooltip: l10n.addExerciseTooltip,
          ),
        ],
      ),
      body: StreamBuilder<List<Exercise>>(
        stream: exercisesAsync,
        builder: (context, snapshot) {
          // Only show loading on initial load (no data yet)
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const LoadingIndicator();
          }

          final exercises = snapshot.data ?? [];

          if (exercises.isEmpty) {
            return EmptyState(
              title: l10n.buildYourExerciseLibrary,
              subtitle: l10n.addExercisesToCreateWorkouts,
              icon: Icons.fitness_center,
              actionText: l10n.addFirstExercise,
              actionIcon: Icons.add,
              onAction: () => _showAddExerciseDialog(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ExerciseCard(
                  exercise: exercise,
                  language: language,
                  onEdit: () => _showEditExerciseDialog(context, ref, exercise),
                  onDelete: () => _deleteExercise(context, ref, exercise),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExerciseDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.addExerciseTooltip),
        elevation: 4,
      ),
    );
  }

  Future<void> _showAddExerciseDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => const _AddExerciseDialog(),
    );
  }

  Future<void> _showEditExerciseDialog(BuildContext context, WidgetRef ref, Exercise exercise) async {
    await showDialog(
      context: context,
      builder: (context) => _AddExerciseDialog(exercise: exercise),
    );
  }

  Future<void> _deleteExercise(BuildContext context, WidgetRef ref, Exercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
        title: Text(l10n.deleteExercise),
        content: Text(l10n.deleteExerciseConfirmation(exercise.name)),
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
      await ref.read(exercisesRepositoryProvider).deleteExercise(exercise.id);
    }
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final AppLanguage language;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseCard({
    required this.exercise,
    required this.language,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                  exercise.displayName(language),
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
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                itemBuilder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return [
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
                        Text(
                          l10n.delete,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ];
                },
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
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
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  exercise.displayPrimaryMuscle(language) ?? exercise.primaryMuscle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Weight unit: ${exercise.unit}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (exercise.notes != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              exercise.notes!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _AddExerciseDialog extends HookConsumerWidget {
  final Exercise? exercise;

  const _AddExerciseDialog({this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = useTextEditingController(text: exercise?.name ?? '');
    final muscleController = useTextEditingController(text: exercise?.primaryMuscle ?? '');
    final unitController = useTextEditingController(text: exercise?.unit ?? 'kg');
    final notesController = useTextEditingController(text: exercise?.notes ?? '');
    final isLoading = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final isEditing = exercise != null;

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
                isEditing ? 'Edit Exercise' : l10n.addExerciseTooltip,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Name
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.exerciseName,
                  hintText: 'e.g., Bench Press, Squats',
                ),
                maxLength: 40,
                validator: (value) => Validators.required(value, 'Exercise name'),
              ),
              const SizedBox(height: AppSpacing.md),

              // Primary Muscle
              TextFormField(
                controller: muscleController,
                decoration: InputDecoration(
                  labelText: l10n.primaryMuscleOptional,
                  hintText: 'e.g., Chest, Legs, Back',
                ),
                maxLength: 40,
              ),
              const SizedBox(height: AppSpacing.md),

              // Unit
              DropdownButtonFormField<String>(
                value: unitController.text.isEmpty ? 'kg' : unitController.text,
                decoration: InputDecoration(labelText: l10n.weightUnit),
                items: [
                  DropdownMenuItem(value: 'kg', child: Text(l10n.kilogramsKg)),
                  DropdownMenuItem(value: 'lb', child: Text(l10n.poundsLb)),
                  DropdownMenuItem(value: 'bodyweight', child: Text(l10n.bodyweight)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    unitController.text = value;
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Notes
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
                    onPressed: isLoading.value ? null : () => _saveExercise(
                      context,
                      ref,
                      formKey,
                      isEditing,
                      exercise,
                      nameController.text,
                      muscleController.text,
                      unitController.text,
                      notesController.text,
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

  Future<void> _saveExercise(
    BuildContext context,
    WidgetRef ref,
    GlobalKey<FormState> formKey,
    bool isEditing,
    Exercise? existingExercise,
    String name,
    String muscle,
    String unit,
    String notes,
    ValueNotifier<bool> isLoading,
  ) async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      final exerciseItem = isEditing
          ? existingExercise!.copyWith(
              name: name.trim(),
              primaryMuscle: muscle.trim().isEmpty ? null : muscle.trim(),
              unit: unit,
              notes: notes.trim().isEmpty ? null : notes.trim(),
            )
          : Exercise.create(
              name: name.trim(),
              primaryMuscle: muscle.trim().isEmpty ? null : muscle.trim(),
              unit: unit,
              notes: notes.trim().isEmpty ? null : notes.trim(),
            );

      if (isEditing) {
        await ref.read(exercisesRepositoryProvider).updateExercise(exerciseItem);
      } else {
        await ref.read(exercisesRepositoryProvider).createExercise(exerciseItem);
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
