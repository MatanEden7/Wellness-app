import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../services/preferences_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WorkoutSettingsPage extends HookConsumerWidget {
  const WorkoutSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(preferencesServiceProvider);
    final theme = Theme.of(context);
    
    // Local state for reactive updates
    final restTime = useState(prefs.defaultRestTime);
    final soundEnabled = useState(prefs.restTimerSoundEnabled);
    final volume = useState(prefs.restTimerVolume);
    
    // Sync with prefs on mount
    useEffect(() {
      restTime.value = prefs.defaultRestTime;
      soundEnabled.value = prefs.restTimerSoundEnabled;
      volume.value = prefs.restTimerVolume;
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workout Settings',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rest Timer',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Default Rest Time
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Default Rest Time',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Time between sets',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Text(
                          '${restTime.value}s',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Slider(
                      value: restTime.value.toDouble(),
                      min: 30,
                      max: 300,
                      divisions: 27,
                      label: '${restTime.value}s',
                      onChanged: (value) {
                        restTime.value = value.round();
                        prefs.setDefaultRestTime(value.round());
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('30s', style: theme.textTheme.bodySmall),
                        Text('5min', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Sound Settings
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Timer Sound',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Play sound when rest timer completes',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Switch(
                          value: soundEnabled.value,
                          onChanged: (value) {
                            soundEnabled.value = value;
                            prefs.setRestTimerSoundEnabled(value);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Volume Control
              if (soundEnabled.value)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Timer Volume',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            '${(volume.value * 100).round()}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          const Icon(Icons.volume_down, size: 20),
                          Expanded(
                            child: Slider(
                              value: volume.value,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              label: '${(volume.value * 100).round()}%',
                              onChanged: (value) {
                                volume.value = value;
                                prefs.setRestTimerVolume(value);
                              },
                            ),
                          ),
                          const Icon(Icons.volume_up, size: 20),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.xl),

              // Info Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'During workouts, you can mute the timer using the volume button and add extra rest time as needed.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

