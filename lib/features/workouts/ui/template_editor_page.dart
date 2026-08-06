import 'package:flutter/material.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../core/validation.dart';
import '../data/repositories.dart';
import '../domain/models.dart';

class TemplateEditorPage extends HookConsumerWidget {
  final String? templateId;

  const TemplateEditorPage({super.key, this.templateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = useTextEditingController();
    final notesController = useTextEditingController();
    final templateExercises = useState<List<TemplateExercise>>([]);
    final isLoading = useState(false);
    final isEditing = templateId != null;

    // Load existing template if editing
    useEffect(() {
      if (isEditing) {
        _loadTemplate(ref, templateId!, nameController, notesController, templateExercises);
      }
      return null;
    }, [templateId]);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Template' : 'Create Template',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppButton(
              text: 'Save',
              onPressed: isLoading.value ? null : () => _saveTemplate(
                context,
                ref,
                isEditing,
                templateId,
                nameController.text,
                notesController.text,
                templateExercises.value,
                isLoading,
              ),
              isLoading: isLoading.value,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Template Name
              Text(
                l10n.templateName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.templateName,
                  hintText: 'e.g., Push Day, Full Body',
                  counterText: '${nameController.text.length}/${TextLimits.workoutTemplateNameMaxLength}',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(fontSize: 16),
                maxLength: TextLimits.workoutTemplateNameMaxLength,
                validator: TextLimits.validateWorkoutTemplateName,
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
                controller: notesController,
                decoration: InputDecoration(
                  labelText: l10n.notesOptional,
                  hintText: 'Any notes about this workout template',
                  counterText: '${notesController.text.length}/${TextLimits.generalNoteMaxLength}',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(fontSize: 16),
                maxLines: 3,
                maxLength: TextLimits.generalNoteMaxLength,
                validator: TextLimits.validateGeneralNote,
              ),
              const SizedBox(height: 24),

              // Exercises Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    l10n.exercises,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppButton(
                    text: l10n.addExerciseTooltip,
                    onPressed: () => _addExercise(context, ref, templateExercises),
                    isSecondary: true,
                    icon: Icons.add,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Exercises List
              if (templateExercises.value.isEmpty)
                const EmptyState(
                  title: 'No exercises added',
                  subtitle: 'Add exercises to build your workout template',
                  icon: Icons.fitness_center,
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: templateExercises.value.length,
                  onReorder: (oldIndex, newIndex) => _reorderExercises(
                    templateExercises,
                    oldIndex,
                    newIndex,
                  ),
                  itemBuilder: (context, index) {
                    final exercise = templateExercises.value[index];
                    return Padding(
                      key: ValueKey(exercise.id),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TemplateExerciseCard(
                        exercise: exercise,
                        index: index,
                        onEdit: () => _editExercise(context, ref, templateExercises, index),
                        onDelete: () => _deleteExercise(templateExercises, index),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadTemplate(
    WidgetRef ref,
    String templateId,
    TextEditingController nameController,
    TextEditingController notesController,
    ValueNotifier<List<TemplateExercise>> templateExercises,
  ) async {
    final template = await ref.read(workoutTemplatesRepositoryProvider).getTemplateById(templateId);
    if (template != null) {
      nameController.text = template.name;
      notesController.text = template.notes ?? '';
      templateExercises.value = template.exercises;
    }
  }

  Future<void> _saveTemplate(
    BuildContext context,
    WidgetRef ref,
    bool isEditing,
    String? templateId,
    String name,
    String? notes,
    List<TemplateExercise> exercises,
    ValueNotifier<bool> isLoading,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterTemplateName)),
      );
      return;
    }

    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseAddExercise)),
      );
      return;
    }

    isLoading.value = true;

    try {
      final template = isEditing
          ? WorkoutTemplate(
              id: templateId!,
              name: name.trim(),
              notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
              exercises: exercises,
            )
          : WorkoutTemplate.create(
              name: name.trim(),
              notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
            ).copyWith(exercises: exercises);

      if (isEditing) {
        await ref.read(workoutTemplatesRepositoryProvider).updateTemplate(template);
      } else {
        await ref.read(workoutTemplatesRepositoryProvider).createTemplate(template);
      }

      // Trigger refresh to update UI immediately
      ref.invalidate(workoutTemplatesRepositoryProvider);

      if (context.mounted) {
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving template: $e')),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _addExercise(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<List<TemplateExercise>> templateExercises,
  ) async {
    final result = await _showExerciseSelector(context, ref);
    if (result != null) {
      final newExercises = List<TemplateExercise>.from(templateExercises.value);
      final templateExercise = TemplateExercise.create(
        templateId: '', // Will be set when saving
        exerciseId: result.id,
        orderIndex: newExercises.length,
      );
      newExercises.add(templateExercise);
      templateExercises.value = newExercises;
    }
  }

  Future<void> _editExercise(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<List<TemplateExercise>> templateExercises,
    int index,
  ) async {
    final currentExercise = templateExercises.value[index];
    final result = await _showTemplateExerciseEditor(context, ref, currentExercise);
    if (result != null) {
      final newExercises = List<TemplateExercise>.from(templateExercises.value);
      newExercises[index] = result;
      templateExercises.value = newExercises;
    }
  }

  void _deleteExercise(ValueNotifier<List<TemplateExercise>> templateExercises, int index) {
    final newExercises = List<TemplateExercise>.from(templateExercises.value);
    newExercises.removeAt(index);
    // Update order indices
    for (int i = 0; i < newExercises.length; i++) {
      newExercises[i] = newExercises[i].copyWith(orderIndex: i);
    }
    templateExercises.value = newExercises;
  }

  void _reorderExercises(
    ValueNotifier<List<TemplateExercise>> templateExercises,
    int oldIndex,
    int newIndex,
  ) {
    if (newIndex > oldIndex) newIndex--;
    final newExercises = List<TemplateExercise>.from(templateExercises.value);
    final exercise = newExercises.removeAt(oldIndex);
    newExercises.insert(newIndex, exercise);
    
    // Update order indices
    for (int i = 0; i < newExercises.length; i++) {
      newExercises[i] = newExercises[i].copyWith(orderIndex: i);
    }
    templateExercises.value = newExercises;
  }

  Future<Exercise?> _showExerciseSelector(BuildContext context, WidgetRef ref) async {
    return showDialog<Exercise>(
      context: context,
      builder: (context) => const _ExerciseSelectorDialog(),
    );
  }

  Future<TemplateExercise?> _showTemplateExerciseEditor(
    BuildContext context,
    WidgetRef ref,
    TemplateExercise templateExercise,
  ) async {
    return showDialog<TemplateExercise>(
      context: context,
      builder: (context) => _TemplateExerciseEditorDialog(templateExercise: templateExercise),
    );
  }
}

class _TemplateExerciseCard extends ConsumerWidget {
  final TemplateExercise exercise;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateExerciseCard({
    required this.exercise,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.drag_handle, color: Colors.grey.shade400),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FutureBuilder<Exercise?>(
                  future: ref.read(exercisesRepositoryProvider).getExerciseById(exercise.exerciseId),
                  builder: (context, snapshot) {
                    final exerciseData = snapshot.data;
                    return Text(
                      exerciseData?.name ?? 'Loading...',
                      style: Theme.of(context).textTheme.titleSmall,
                    );
                  },
                ),
              ),
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
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const SizedBox(width: 32), // Offset for drag handle
              Text(
                '${exercise.defaultSets} sets',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (exercise.defaultReps != null) ...[
                const Text(' • '),
                Text(
                  '${exercise.defaultReps} reps',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (exercise.defaultWeight != null) ...[
                const Text(' • '),
                Text(
                  '${Formatters.formatWeight(exercise.defaultWeight!)} kg',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              // Rest is part of the prescription, not a detail: it is what
              // separates a heavy compound from an accessory, and it drives
              // the in-session timer. Showing sets and reps but hiding rest
              // makes the generated plan look like it has no opinion on it.
              if (exercise.defaultRestSeconds != null) ...[
                const Text(' • '),
                Text(
                  '${exercise.defaultRestSeconds}s rest',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseSelectorDialog extends ConsumerWidget {
  const _ExerciseSelectorDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final exercisesAsync = ref.watch(exercisesStreamProvider);

    return Dialog(
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.selectExercise,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            
            Expanded(
              child: StreamBuilder<List<Exercise>>(
                stream: exercisesAsync,
                builder: (context, snapshot) {
                  final exercises = snapshot.data ?? [];

                  if (exercises.isEmpty) {
                    return const EmptyState(
                      title: 'No exercises',
                      subtitle: 'Create exercises in the Exercise Library first',
                      icon: Icons.fitness_center,
                    );
                  }

                  return ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return ListTile(
                        title: Text(exercise.name),
                        subtitle: exercise.primaryMuscle != null
                            ? Text(exercise.primaryMuscle!)
                            : null,
                        onTap: () => Navigator.of(context).pop(exercise),
                      );
                    },
                  );
                },
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateExerciseEditorDialog extends HookWidget {
  final TemplateExercise templateExercise;

  const _TemplateExerciseEditorDialog({required this.templateExercise});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final setsController = useTextEditingController(
      text: templateExercise.defaultSets.toString(),
    );
    final repsController = useTextEditingController(
      text: templateExercise.defaultReps?.toString() ?? '',
    );
    final weightController = useTextEditingController(
      text: templateExercise.defaultWeight?.toString() ?? '',
    );
    final restController = useTextEditingController(
      text: templateExercise.defaultRestSeconds?.toString() ?? '',
    );

    return Dialog(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.exerciseSettings,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: setsController,
              decoration: InputDecoration(labelText: l10n.defaultSets),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: repsController,
              decoration: InputDecoration(
                labelText: l10n.defaultRepsOptional,
                hintText: 'Leave empty for variable reps',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: weightController,
              decoration: InputDecoration(
                labelText: l10n.defaultWeightOptional,
                hintText: 'Leave empty for variable weight',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: restController,
              decoration: InputDecoration(
                labelText: l10n.defaultRestOptional,
                hintText: 'Leave empty to use the rep-based default',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  text: 'Save',
                  onPressed: () {
                    final sets = int.tryParse(setsController.text) ?? 3;
                    final reps = int.tryParse(repsController.text);
                    final weight = double.tryParse(weightController.text);
                    final rest = int.tryParse(restController.text);

                    final updatedExercise = templateExercise.copyWith(
                      defaultSets: sets,
                      defaultReps: reps,
                      defaultWeight: weight,
                      defaultRestSeconds: rest,
                    );

                    Navigator.of(context).pop(updatedExercise);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
