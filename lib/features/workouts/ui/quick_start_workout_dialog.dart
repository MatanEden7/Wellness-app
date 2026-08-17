import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets.dart';
import '../../../services/preferences_service.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import '../domain/session_actions.dart';
import 'workout_keys.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

/// Sheet opened from the dashboard "+": pick a template (or start blank) and
/// jump straight into the live session -- the actual data (the session row)
/// is created here, the session page just opens to record it in.
class QuickStartWorkoutDialog extends HookConsumerWidget {
  const QuickStartWorkoutDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(preferencesServiceProvider);
    final templatesAsync = ref.watch(workoutTemplatesStreamProvider);

    return AppSheet(
      title: l10n.startWorkout,
      icon: Icons.fitness_center,
      iconColor: prefs.workoutsColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IconRowTile(
            key: WorkoutKeys.quickWorkoutTile,
            icon: Icons.flash_on,
            label: l10n.quickWorkout,
            color: prefs.workoutsColor,
            onTap: () => _start(context, ref, null),
          ),
          StreamBuilder<List<WorkoutTemplate>>(
            stream: templatesAsync,
            builder: (context, snapshot) {
              final templates = snapshot.data ?? [];
              if (templates.isEmpty) return const SizedBox.shrink();
              // A plain Column of tiles, not a Flexible/ListView: the
              // StreamBuilder sits between the Flexible and the Column, so
              // `Flexible` was reaching a non-Flex parent and throwing
              // "Incorrect use of ParentDataWidget". The whole sheet already
              // scrolls via AppSheet, so nothing here needs its own viewport.
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final template in templates)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: IconRowTile(
                        icon: Icons.fitness_center,
                        label: template.name,
                        subtitle:
                            l10n.exercisesCount(template.exercises.length),
                        color: prefs.workoutsColor,
                        onTap: () => _start(context, ref, template),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    WorkoutTemplate? template,
  ) async {
    final session = template == null
        ? await startQuickWorkoutSession(ref)
        : await startWorkoutSessionFromTemplate(ref, template);
    if (context.mounted) {
      Navigator.of(context).pop();
      context.push('/workouts/session/${session.id}');
    }
  }
}
