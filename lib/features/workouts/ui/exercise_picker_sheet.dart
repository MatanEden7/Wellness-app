import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../services/language_service.dart';
import '../../../services/preferences_service.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import '../domain/rest_time.dart';
import 'workout_keys.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import '../../../core/design/surfaces.dart';
import '../../../core/design/tokens.dart';

/// What the picker hands back: which exercise, and how it should be done.
class ExercisePrescription {
  final Exercise exercise;
  final int sets;
  final int? reps;
  final double? weight;

  /// Null means "no explicit rest" -- resolve it from the rep count at use
  /// time via [resolveRestSeconds], rather than freezing today's default
  /// into the template.
  final int? restSeconds;

  const ExercisePrescription({
    required this.exercise,
    required this.sets,
    this.reps,
    this.weight,
    this.restSeconds,
  });
}

/// Picks an exercise and its prescription, in two steps: choose from a
/// searchable list (tap the row to pick, the chevron to read the details
/// first), then set weight / sets / reps / rest.
///
/// Returns null if the user backs out of either step.
Future<ExercisePrescription?> showExercisePicker(BuildContext context) {
  return showAppSheet<ExercisePrescription>(
    context: context,
    builder: (_) => const _ExercisePickerSheet(),
  );
}

class _ExercisePickerSheet extends HookConsumerWidget {
  const _ExercisePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(currentLanguageProvider);
    final workoutsColor = ref.watch(preferencesServiceProvider).workoutsColor;
    final query = useState('');
    final expandedId = useState<String?>(null);

    return AppSheet(
      title: l10n.addExercise,
      icon: Icons.fitness_center,
      iconColor: workoutsColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: WorkoutKeys.exerciseSearchField,
            autofocus: false,
            decoration: InputDecoration(
              hintText: l10n.searchExercises,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (value) => query.value = value,
          ),
          const SizedBox(height: AppSpacing.md),
          StreamBuilder<List<Exercise>>(
            stream: ref.watch(exercisesStreamProvider),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: Space.xxxl),
                  child: LoadingIndicator(),
                );
              }

              final needle = query.value.trim().toLowerCase();
              final matches = snapshot.data!.where((exercise) {
                if (needle.isEmpty) return true;
                final muscle =
                    exercise.displayPrimaryMuscle(language)?.toLowerCase() ??
                        '';
                return exercise
                        .displayName(language)
                        .toLowerCase()
                        .contains(needle) ||
                    muscle.contains(needle);
              }).toList()
                ..sort((a, b) =>
                    a.displayName(language).compareTo(b.displayName(language)));

              if (matches.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.xxxl),
                  child: Text(
                    l10n.noExercisesFound,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                );
              }

              // A bounded, internally-scrolling list: the sheet must not grow
              // past the screen just because the catalog has 58 exercises.
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: matches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final exercise = matches[index];
                    return _ExerciseRow(
                      key: WorkoutKeys.exerciseRow(exercise.id),
                      exercise: exercise,
                      language: language,
                      color: workoutsColor,
                      isExpanded: expandedId.value == exercise.id,
                      onToggleDetails: () => expandedId.value =
                          expandedId.value == exercise.id ? null : exercise.id,
                      onSelect: () async {
                        final prescription =
                            await showAppSheet<ExercisePrescription>(
                          context: context,
                          builder: (_) =>
                              ExercisePrescriptionSheet(exercise: exercise),
                        );
                        if (prescription != null && context.mounted) {
                          Navigator.of(context).pop(prescription);
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// One tappable exercise. The whole row selects it; the chevron opens the
/// details inline so you can check what it works without losing your place
/// in the list.
class _ExerciseRow extends StatelessWidget {
  final Exercise exercise;
  final AppLanguage language;
  final Color color;
  final bool isExpanded;
  final VoidCallback onToggleDetails;
  final VoidCallback onSelect;

  const _ExerciseRow({
    super.key,
    required this.exercise,
    required this.language,
    required this.color,
    required this.isExpanded,
    required this.onToggleDetails,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final muscle = exercise.displayPrimaryMuscle(language);
    final hasDetails = muscle != null ||
        exercise.notes != null ||
        exercise.equipment.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: ContentSurface.tinted(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.md, vertical: Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.fitness_center, color: color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.displayName(language),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (muscle != null)
                            Text(
                              muscle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (hasDetails)
                      IconButton(
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                        onPressed: onToggleDetails,
                        tooltip: l10n.exerciseDetails,
                        visualDensity: VisualDensity.compact,
                      ),
                    Icon(
                      Icons.add_circle,
                      color: color,
                      size: 24,
                    ),
                  ],
                ),
                if (isExpanded && hasDetails) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (muscle != null)
                    _DetailLine(label: l10n.primaryMuscle, value: muscle),
                  if (exercise.equipment.isNotEmpty)
                    _DetailLine(
                      label: l10n.equipmentLabel,
                      value: exercise.equipment.map((e) => e.name).join(', '),
                    ),
                  if (exercise.notes != null)
                    _DetailLine(label: l10n.notes, value: exercise.notes!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Weight / sets / reps / rest for one exercise.
///
/// Also used to edit an exercise already on the workout -- pass [initial].
class ExercisePrescriptionSheet extends HookConsumerWidget {
  final Exercise exercise;
  final TemplateExercise? initial;

  const ExercisePrescriptionSheet({
    super.key,
    required this.exercise,
    this.initial,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(currentLanguageProvider);
    final prefs = ref.watch(preferencesServiceProvider);
    final workoutsColor = prefs.workoutsColor;

    final sets = useState(initial?.defaultSets ?? 3);
    final repsController = useTextEditingController(
      text: initial?.defaultReps?.toString() ?? '10',
    );
    final weightController = useTextEditingController(
      text: initial?.defaultWeight != null
          ? _trimZeros(initial!.defaultWeight!)
          : '',
    );
    // Null = follow the rep-based ladder. Kept distinct from a number so
    // "auto" survives a change of rep count instead of freezing a value.
    final restSeconds = useState<int?>(initial?.defaultRestSeconds);

    // Rebuilds the "Auto" chip's label as the rep count is typed.
    final reps = useState<int?>(initial?.defaultReps ?? 10);
    useEffect(() {
      void listener() => reps.value = int.tryParse(repsController.text);
      repsController.addListener(listener);
      return () => repsController.removeListener(listener);
    }, [repsController]);

    final autoRest = resolveRestSeconds(
      reps: reps.value,
      globalDefaultSeconds: prefs.defaultRestTime,
    );

    return AppSheet(
      title: exercise.displayName(language),
      icon: Icons.fitness_center,
      iconColor: workoutsColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '${l10n.weight} (${exercise.unit})',
                    // Empty means bodyweight, not zero -- and the label has to
                    // float for that to be readable before the field is
                    // tapped. See the template editor's weight field.
                    hintText: l10n.bodyweight,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: repsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.targetReps),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.targetSets, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _Stepper(
            value: sets.value,
            min: 1,
            max: 12,
            onChanged: (value) => sets.value = value,
            color: workoutsColor,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.restBetweenSets,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RestChip(
                label: l10n.restAutoLabel(formatRest(autoRest)),
                selected: restSeconds.value == null,
                color: workoutsColor,
                onTap: () => restSeconds.value = null,
              ),
              for (final preset in restPresets)
                _RestChip(
                  label: formatRest(preset),
                  selected: restSeconds.value == preset,
                  color: workoutsColor,
                  onTap: () => restSeconds.value = preset,
                ),
            ],
          ),
          if (restSeconds.value == null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.restAutoExplainer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: WorkoutKeys.savePrescription,
            text: initial == null ? l10n.addToWorkout : l10n.save,
            icon: initial == null ? Icons.add : null,
            onPressed: () {
              Navigator.of(context).pop(
                ExercisePrescription(
                  exercise: exercise,
                  sets: sets.value,
                  reps: int.tryParse(repsController.text),
                  weight: double.tryParse(
                    weightController.text.replaceAll(',', '.'),
                  ),
                  restSeconds: restSeconds.value,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _trimZeros(double value) {
    final asString = value.toStringAsFixed(2);
    return asString
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final Color color;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Expanded(
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _RestChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _RestChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? color : null,
      ),
    );
  }
}
