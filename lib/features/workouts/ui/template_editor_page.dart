import 'package:flutter/material.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/cupertino.dart';

import '../../../shell/platform_page.dart';
import '../../../core/ios/inset_list.dart';
import '../../../core/ios/swipe_row.dart';
import '../../../core/theme.dart';
import '../../../services/preferences_service.dart';
import '../../../core/widgets.dart';
import '../../../core/utils.dart';
import '../../../core/validation.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import '../domain/rest_time.dart';
import '../../../core/ios/glass.dart';
import '../../../core/design/surfaces.dart';
import '../../../core/design/tokens.dart';
import '../../../core/ios/feedback.dart';

class TemplateEditorPage extends HookConsumerWidget {
  final String? templateId;

  const TemplateEditorPage({super.key, this.templateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = useTextEditingController();
    final notesController = useTextEditingController();
    final templateExercises = useState<List<TemplateExercise>>([]);
    final customRest = useState(false);
    final isLoading = useState(false);
    final isEditing = templateId != null;

    // Load existing template if editing
    useEffect(() {
      if (isEditing) {
        _loadTemplate(ref, templateId!, nameController, notesController,
            templateExercises, customRest);
      }
      return null;
    }, [templateId]);

    return PlatformChildPage(
      chrome: PageChrome(
        title: isEditing ? l10n.editTemplate : l10n.createTemplate,
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
                      notesController.text,
                      templateExercises.value,
                      customRest.value,
                      isLoading,
                    ),
          ),
        ],
      ),
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
              counterText:
                  '${nameController.text.length}/${TextLimits.workoutTemplateNameMaxLength}',
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: Space.lg, vertical: Space.lg),
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
              counterText:
                  '${notesController.text.length}/${TextLimits.generalNoteMaxLength}',
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: Space.lg, vertical: Space.lg),
            ),
            style: const TextStyle(fontSize: 16),
            maxLines: 3,
            maxLength: TextLimits.generalNoteMaxLength,
            validator: TextLimits.validateGeneralNote,
          ),
          const SizedBox(height: 24),

          // Breaks
          //
          // One switch decides whether this template has an opinion about
          // rest at all. Off (the default) means the app derives it from
          // the rep count between every set and there is nothing to see;
          // on reveals the break rows and the button that adds them.
          InsetSection(
            footer: customRest.value
                ? l10n.customBreaksSubtitle
                : l10n.autoBreaksSubtitle,
            children: [
              InsetRow(
                title: l10n.customBreaks,
                icon: Icons.timer_outlined,
                trailing: Switch.adaptive(
                  value: customRest.value,
                  onChanged: (value) {
                    customRest.value = value;
                    // Dropping back to automatic leaves orphaned break
                    // rows in the list that nothing would render -- take
                    // them out rather than hide them.
                    if (!value) {
                      templateExercises.value = _reindexed([
                        for (final item in templateExercises.value)
                          if (!item.isRest) item,
                      ]);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Exercises Section
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.exercises,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (customRest.value) ...[
                _AddPill(
                  icon: CupertinoIcons.timer,
                  label: l10n.addBreakShort,
                  onTap: () => _addRest(context, templateExercises),
                ),
                const SizedBox(width: 8),
              ],
              _AddPill(
                icon: CupertinoIcons.add,
                label: l10n.addExerciseShort,
                onTap: () => _addExercise(context, ref, templateExercises),
              ),
            ],
          ),
          const SizedBox(height: 12),

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
              // The rows own their own drag handle: their whole surface is
              // swipeable, and a long-press drag anywhere on them would
              // fight the swipe gesture.
              buildDefaultDragHandles: false,
              itemCount: templateExercises.value.length,
              onReorder: (oldIndex, newIndex) => _reorderExercises(
                templateExercises,
                oldIndex,
                newIndex,
              ),
              itemBuilder: (context, index) {
                final item = templateExercises.value[index];
                return SwipeActionRow(
                  key: ValueKey(item.id),
                  rowKey: ValueKey('swipe-${item.id}'),
                  deleteLabel: l10n.delete,
                  editLabel: l10n.edit,
                  confirmTitle: item.isRest ? l10n.restBlock : l10n.delete,
                  confirmMessage: l10n.areYouSure,
                  onDelete: () async =>
                      _deleteExercise(templateExercises, index),
                  onEdit: () => item.isRest
                      ? _editRest(context, templateExercises, index)
                      : _editExercise(context, ref, templateExercises, index),
                  // Long press is the reorder gesture here.
                  enableLongPressMenu: false,
                  child: item.isRest
                      ? _RestRowCard(
                          rest: item,
                          index: index,
                          onTap: () =>
                              _editRest(context, templateExercises, index),
                        )
                      : _TemplateExerciseCard(
                          exercise: item,
                          index: index,
                          onTap: () => _editExercise(
                              context, ref, templateExercises, index),
                        ),
                );
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _loadTemplate(
    WidgetRef ref,
    String templateId,
    TextEditingController nameController,
    TextEditingController notesController,
    ValueNotifier<List<TemplateExercise>> templateExercises,
    ValueNotifier<bool> customRest,
  ) async {
    final template = await ref
        .read(workoutTemplatesRepositoryProvider)
        .getTemplateById(templateId);
    if (template != null) {
      nameController.text = template.name;
      notesController.text = template.notes ?? '';
      templateExercises.value = template.exercises;
      customRest.value = template.customRest;
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
    bool customRest,
    ValueNotifier<bool> isLoading,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (name.trim().isEmpty) {
      showAppError(context, l10n.pleaseEnterTemplateName);
      return;
    }

    // A template of nothing but breaks is not a workout.
    if (exercises.where((e) => !e.isRest).isEmpty) {
      showAppError(context, l10n.pleaseAddExercise);
      return;
    }

    isLoading.value = true;

    try {
      final template = isEditing
          ? WorkoutTemplate(
              id: templateId!,
              name: name.trim(),
              notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
              customRest: customRest,
              exercises: exercises,
            )
          : WorkoutTemplate.create(
              name: name.trim(),
              notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
            ).copyWith(customRest: customRest, exercises: exercises);

      if (isEditing) {
        await ref
            .read(workoutTemplatesRepositoryProvider)
            .updateTemplate(template);
      } else {
        await ref
            .read(workoutTemplatesRepositoryProvider)
            .createTemplate(template);
      }

      // Trigger refresh to update UI immediately
      ref.invalidate(workoutTemplatesRepositoryProvider);

      if (context.mounted) {
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        showAppError(context, 'Error saving template: $e');
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

  /// Appends a break at the end of the list. It is dragged into place from
  /// there, which is one gesture fewer than asking where it should go first.
  Future<void> _addRest(
    BuildContext context,
    ValueNotifier<List<TemplateExercise>> items,
  ) async {
    final seconds = await _showRestPicker(context, 120);
    if (seconds == null) return;
    items.value = _reindexed([
      ...items.value,
      TemplateExercise.rest(
        templateId: '',
        orderIndex: items.value.length,
        seconds: seconds,
      ),
    ]);
  }

  Future<void> _editRest(
    BuildContext context,
    ValueNotifier<List<TemplateExercise>> items,
    int index,
  ) async {
    final seconds =
        await _showRestPicker(context, items.value[index].restDuration);
    if (seconds == null) return;
    final next = List<TemplateExercise>.from(items.value);
    next[index] = next[index].copyWith(defaultRestSeconds: seconds);
    items.value = next;
  }

  Future<int?> _showRestPicker(BuildContext context, int initial) {
    return showAppSheet<int>(
      context: context,
      builder: (_) => _RestPickerSheet(initialSeconds: initial),
    );
  }

  Future<void> _editExercise(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<List<TemplateExercise>> templateExercises,
    int index,
  ) async {
    final currentExercise = templateExercises.value[index];
    final result =
        await _showTemplateExerciseEditor(context, ref, currentExercise);
    if (result != null) {
      final newExercises = List<TemplateExercise>.from(templateExercises.value);
      newExercises[index] = result;
      templateExercises.value = newExercises;
    }
  }

  void _deleteExercise(
      ValueNotifier<List<TemplateExercise>> templateExercises, int index) {
    final newExercises = List<TemplateExercise>.from(templateExercises.value);
    newExercises.removeAt(index);
    templateExercises.value = _reindexed(newExercises);
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
    templateExercises.value = _reindexed(newExercises);
  }

  /// `orderIndex` is what the list's order actually persists as, so it has to
  /// be rewritten after every insert, delete and drag.
  static List<TemplateExercise> _reindexed(List<TemplateExercise> items) => [
        for (var i = 0; i < items.length; i++) items[i].copyWith(orderIndex: i),
      ];

  Future<Exercise?> _showExerciseSelector(
      BuildContext context, WidgetRef ref) async {
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
      builder: (context) =>
          _TemplateExerciseEditorDialog(templateExercise: templateExercise),
    );
  }
}

/// One exercise in the template list.
///
/// Deliberately a single 56pt row rather than the two-line card with two icon
/// buttons this used to be: a template of eight exercises was 700pt of
/// scrolling, and on a phone the prescription ("3 x 10") is the only thing
/// worth showing next to the name. Editing and deleting moved onto the swipe
/// gestures, which is where an iPhone user looks for them.
class _TemplateExerciseCard extends ConsumerWidget {
  final TemplateExercise exercise;
  final int index;
  final VoidCallback onTap;

  const _TemplateExerciseCard({
    required this.exercise,
    required this.index,
    required this.onTap,
  });

  /// "3 x 10 · Bodyweight · 1:30" -- everything prescribed, nothing padded
  /// out.
  ///
  /// No prescribed weight means bodyweight, and says so: an empty space where
  /// a number should be reads as missing data, when in fact it is the answer
  /// for press-ups, planks and every band exercise in the library. [unit] is
  /// the exercise's own ('kg', 'lb', 'bodyweight'), not an assumed kg.
  String _summary(AppLocalizations l10n, String? unit) {
    final weight = exercise.defaultWeight;
    final isBodyweight = unit == 'bodyweight' || weight == null;

    return <String>[
      exercise.defaultReps == null
          ? '${exercise.defaultSets} sets'
          : '${exercise.defaultSets} x ${exercise.defaultReps}',
      if (isBodyweight)
        l10n.bodyweight
      else
        '${Formatters.formatWeight(weight)} ${unit ?? 'kg'}',
      if (exercise.defaultRestSeconds != null)
        formatRest(exercise.defaultRestSeconds!),
    ].join(' \u00b7 ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(8, 10, 14, 10),
        onTap: onTap,
        child: Row(
          children: [
            _DragHandle(index: index),
            // One lookup feeds both halves of the row: the name and the unit
            // the prescribed weight is expressed in.
            Expanded(
              child: FutureBuilder<Exercise?>(
                future: ref
                    .read(exercisesRepositoryProvider)
                    .getExerciseById(exercise.exerciseId),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          data?.name ?? '...',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _summary(l10n, data?.unit),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A standalone break between two exercises. Tinted and shorter than an
/// exercise row so the eye reads the list as work / pause / work without
/// having to read the words.
class _RestRowCard extends StatelessWidget {
  final TemplateExercise rest;
  final int index;
  final VoidCallback onTap;

  const _RestRowCard({
    required this.rest,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final tint = theme.colorScheme.primary;

    return Padding(
      // The 4pt inset matches Card's own default margin, so a break row lines
      // up with the exercise cards above and below it instead of sitting
      // 8pt wider than all of them.
      padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      child: ContentSurface.tinted(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
              child: Row(
                children: [
                  _DragHandle(index: index),
                  Icon(CupertinoIcons.timer, size: 18, color: tint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.restBlock,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: tint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatRest(rest.restDuration),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact "+ Exercise" / "+ Break" button for a section header.
///
/// Tinted pills rather than plain text buttons: two text buttons and a title
/// do not fit across 402pt, and iOS uses exactly this shape for a secondary
/// add action sitting beside a heading.
class _AddPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = Theme.of(context).colorScheme.primary;

    return ContentSurface.tinted(
      color: tint.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.md, vertical: Space.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: tint),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: tint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The grab area for reordering. Explicit, because the rows' own long-press
/// and horizontal drag are already spoken for by the swipe actions.
class _DragHandle extends StatelessWidget {
  final int index;

  const _DragHandle({required this.index});

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.sm),
        child: Icon(
          CupertinoIcons.line_horizontal_3,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

/// Picks a break length: four presets, then a minute/second wheel for
/// anything else. A break is "about two minutes", not 137 seconds, so the
/// presets are the fast path and the wheel is the escape hatch.
class _RestPickerSheet extends HookWidget {
  final int initialSeconds;

  const _RestPickerSheet({required this.initialSeconds});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final seconds = useState(initialSeconds);

    return AppSheet(
      title: l10n.restDuration,
      icon: Icons.timer_outlined,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in const [30, 60, 90, 120, 180, 300])
                ChoiceChip(
                  label: Text(formatRest(preset)),
                  selected: seconds.value == preset,
                  onSelected: (_) => seconds.value = preset,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                formatRest(seconds.value),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              Expanded(
                child: Slider(
                  value: seconds.value.toDouble().clamp(10, 600),
                  min: 10,
                  max: 600,
                  divisions: 59,
                  onChanged: (value) => seconds.value = value.round(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            text: l10n.save,
            onPressed: () => Navigator.of(context).pop(seconds.value),
            icon: Icons.check,
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
      backgroundColor: Colors.transparent,
      child: ContentSurface(
        borderRadius: BorderRadius.circular(14),
        showBorder: false,
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
                        subtitle:
                            'Create exercises in the Exercise Library first',
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
                  GlassButton(
                    minHeight: Sizes.control,
                    borderRadius: BorderRadius.circular(18),
                    padding: const EdgeInsets.symmetric(
                        horizontal: Space.md, vertical: Space.sm),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
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

class _TemplateExerciseEditorDialog extends HookConsumerWidget {
  final TemplateExercise templateExercise;

  const _TemplateExerciseEditorDialog({required this.templateExercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    // The placeholder is the rest this exercise would actually get if the
    // field is left empty -- not the word "Automatic", which tells you the
    // mechanism but not the number. It follows the rep count as you type,
    // because that is what decides it.
    final reps = useState(templateExercise.defaultReps);
    useEffect(() {
      void listener() => reps.value = int.tryParse(repsController.text);
      repsController.addListener(listener);
      return () => repsController.removeListener(listener);
    }, [repsController]);

    final fallbackRest = resolveRestSeconds(
      reps: reps.value,
      globalDefaultSeconds:
          ref.watch(preferencesServiceProvider).defaultRestTime,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ContentSurface(
        borderRadius: BorderRadius.circular(14),
        showBorder: false,
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
                  // Empty is not "unspecified", it is bodyweight -- say so.
                  hintText: l10n.bodyweight,
                  // Without this the label sits *inside* the empty field and
                  // the hint is hidden until you tap it, so the one state that
                  // needs explaining -- empty -- is the one that explains
                  // nothing. Floating it always makes "Bodyweight" the
                  // placeholder you actually see.
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: restController,
                decoration: InputDecoration(
                  labelText: l10n.defaultRestOptional,
                  hintText: '$fallbackRest',
                  helperText: l10n.restDefaultHelper(formatRest(fallbackRest)),
                  // Same reason as the weight field above.
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.lg),
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
                    text: 'Save',
                    onPressed: () {
                      final sets = int.tryParse(setsController.text) ?? 3;
                      final reps = int.tryParse(repsController.text);
                      final weight = double.tryParse(weightController.text);

                      // Empty means "follow the default", which is a real
                      // answer -- null, not zero.
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
      ),
    );
  }
}
