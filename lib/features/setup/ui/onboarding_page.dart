import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import 'package:wellness_app/l10n/app_localizations.dart';

import '../../../services/setup_engine_service.dart';
import '../../../services/user_profile_service.dart';
import '../../../services/preferences_service.dart';
import '../../../services/workout_template_generator.dart';
import '../../../services/meal_template_generator.dart';
import '../../../services/calendar_schedule_generator.dart';
import '../../../services/language_service.dart';
import '../../../data/db/drift_database.dart';
import '../../../features/calendar/data/calendar_service.dart';

class OnboardingPage extends HookConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentStep = useState(0);
    
    // Form state
    final sex = useState<String>('male');
    final age = useState<int>(25);
    final height = useState<int>(170);
    final weight = useState<double>(70.0);
    final goal = useState<String>('maintenance');
    final activityLevel = useState<String>('moderate');
    final trainingDays = useState<int>(3);
    final equipment = useState<Set<String>>({'none'});
    final dietType = useState<String>('omnivore');
    final mealCount = useState<String>('3');
    final exclusions = useState<Set<String>>({'none'});
    final injuries = useState<Set<String>>({'none'});
    final energyUnit = useState<String>('kcal');
    final weightUnit = useState<String>('g');
    final selectedLanguage = useState<String>('en'); // Start with English by default
    final isCompleting = useState<bool>(false); // Track setup completion state
    
    final totalSteps = 7; // Added language selection as Step 0
    
    void nextStep() {
      if (currentStep.value < totalSteps - 1) {
        currentStep.value++;
        pageController.animateToPage(
          currentStep.value,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
    
    void previousStep() {
      if (currentStep.value > 0) {
        currentStep.value--;
        pageController.animateToPage(
          currentStep.value,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
    
    Future<void> completeSetup() async {
      // Prevent multiple calls
      if (isCompleting.value) return;
      isCompleting.value = true;
      
      try {
        // Read all providers BEFORE any async operations to avoid disposal issues
        final profileService = ref.read(userProfileServiceProvider);
        final prefs = ref.read(preferencesServiceProvider);
        final database = ref.read(databaseProvider);
        
        final setupEngine = SetupEngineService();
        await setupEngine.initialize();
        
        final profile = setupEngine.createUserProfile(
          sex: sex.value,
          ageYears: age.value,
          heightCm: height.value,
          weightKg: weight.value,
          goal: goal.value,
          activityLevel: activityLevel.value,
          trainingDaysPerWeek: trainingDays.value,
          equipment: equipment.value.toList(),
          dietType: dietType.value,
          mealCountPerDay: mealCount.value,
          exclusions: exclusions.value.toList(),
          injuries: injuries.value.toList(),
          energyUnit: energyUnit.value,
          weightUnit: weightUnit.value,
        );
        
        // Save profile
        await profileService.saveProfile(profile);
        
        // Set nutrition goals in preferences
        await prefs.setCalorieGoal(profile.calorieTarget);
        await prefs.setProteinGoal(profile.proteinTargetG);
        await prefs.setCarbsGoal(profile.carbsTargetG);
        await prefs.setFatGoal(profile.fatTargetG);
        
        // Generate workout templates
        final workoutGen = WorkoutTemplateGenerator(database, profile);
        await workoutGen.generateTemplates();
        
        // Generate meal templates
        final mealGen = MealTemplateGenerator(database, profile);
        await mealGen.generateTemplates();
        
        // Generate the starting calendar schedule (workouts, meals, sleep).
        // Routed through the notifier rather than CalendarService directly,
        // because that is the only path that also schedules the reminders.
        final calendarGen = CalendarScheduleGenerator(database, profile);
        await ref
            .read(calendarStateProvider.notifier)
            .addEvents(await calendarGen.buildSchedule());

        debugPrint('[ONBOARDING] Setup completed successfully');
        
        // Navigate to dashboard
        if (context.mounted) {
          context.go('/');
        }
      } catch (e) {
        debugPrint('[ONBOARDING] ❌ Setup failed: $e');
        isCompleting.value = false;
        // Show error to user if mounted
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Setup failed: $e')),
          );
        }
      }
    }
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Setup ${currentStep.value + 1}/$totalSteps',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (currentStep.value > 0)
                        TextButton(
                          onPressed: previousStep,
                          child: Text(AppLocalizations.of(context)!.onboardingBack),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (currentStep.value + 1) / totalSteps,
                    backgroundColor: Colors.grey[300],
                  ),
                ],
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 0: Language Selection
                  _LanguageSelectionStep(
                    selectedLanguage: selectedLanguage,
                    onNext: nextStep,
                  ),
                  
                  // Step 1: Basic Info
                  _BasicInfoStep(
                    sex: sex,
                    age: age,
                    height: height,
                    weight: weight,
                    energyUnit: energyUnit,
                    weightUnit: weightUnit,
                    onNext: nextStep,
                  ),
                  
                  // Step 2: Goals
                  _GoalsStep(
                    goal: goal,
                    activityLevel: activityLevel,
                    trainingDays: trainingDays,
                    onNext: nextStep,
                  ),
                  
                  // Step 3: Equipment
                  _EquipmentStep(
                    equipment: equipment,
                    onNext: nextStep,
                  ),
                  
                  // Step 4: Diet
                  _DietStep(
                    dietType: dietType,
                    mealCount: mealCount,
                    exclusions: exclusions,
                    onNext: nextStep,
                  ),
                  
                  // Step 5: Injuries
                  _InjuriesStep(
                    injuries: injuries,
                    onNext: nextStep,
                  ),
                  
                  // Step 6: Summary & Complete
                  _SummaryStep(
                    sex: sex.value,
                    age: age.value,
                    height: height.value,
                    weight: weight.value,
                    goal: goal.value,
                    activityLevel: activityLevel.value,
                    trainingDays: trainingDays.value,
                    equipment: equipment.value.toList(),
                    dietType: dietType.value,
                    mealCount: mealCount.value,
                    isCompleting: isCompleting.value,
                    onComplete: completeSetup,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Step 0: Language Selection
class _LanguageSelectionStep extends HookConsumerWidget {
  final ValueNotifier<String> selectedLanguage;
  final VoidCallback onNext;

  const _LanguageSelectionStep({
    required this.selectedLanguage,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageService = ref.read(languageServiceProvider);
    // Watch language to rebuild when it changes
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          // Welcome text
          Text(
            l10n.onboardingWelcome,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingChooseLanguage,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 48),
          
          // Language options with flags
          _buildLanguageOption(
            context: context,
            ref: ref,
            languageCode: 'en',
            badge: 'EN',
            languageName: 'English',
            nativeName: 'English',
            isSelected: selectedLanguage.value == 'en',
            onTap: () {
              selectedLanguage.value = 'en';
              languageService.setLanguage(AppLanguage.english);
              // Force rebuild to update all text immediately
              ref.read(currentLanguageProvider.notifier).setLanguage(AppLanguage.english);
            },
          ),
          const SizedBox(height: 16),
          _buildLanguageOption(
            context: context,
            ref: ref,
            languageCode: 'he',
            badge: 'עב',
            languageName: 'Hebrew',
            nativeName: 'עברית',
            isSelected: selectedLanguage.value == 'he',
            onTap: () {
              selectedLanguage.value = 'he';
              languageService.setLanguage(AppLanguage.hebrew);
              // Force rebuild to update all text immediately
              ref.read(currentLanguageProvider.notifier).setLanguage(AppLanguage.hebrew);
            },
          ),
          
          const SizedBox(height: 48),
          
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: Text(l10n.onboardingContinue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required WidgetRef ref,
    required String languageCode,
    required String badge,
    required String languageName,
    required String nativeName,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          children: [
            // A typographic badge rather than a flag emoji. Regional-indicator
            // flags render as tofu boxes wherever the platform font lacks
            // them -- which is most Android builds, and was happening on the
            // iOS simulator too. This also avoids equating a language with a
            // single country's flag.
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Language names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languageName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nativeName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                size: 32,
              ),
          ],
        ),
      ),
    );
  }
}

// Step 1: Basic Info
class _BasicInfoStep extends StatelessWidget {
  final ValueNotifier<String> sex;
  final ValueNotifier<int> age;
  final ValueNotifier<int> height;
  final ValueNotifier<double> weight;
  final ValueNotifier<String> energyUnit;
  final ValueNotifier<String> weightUnit;
  final VoidCallback onNext;

  const _BasicInfoStep({
    required this.sex,
    required this.age,
    required this.height,
    required this.weight,
    required this.energyUnit,
    required this.weightUnit,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sex
          Text(l10n.onboardingSex, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'male', label: Text(l10n.onboardingMale, maxLines: 1)),
              ButtonSegment(value: 'female', label: Text(l10n.onboardingFemale, maxLines: 1)),
            ],
            selected: {sex.value},
            onSelectionChanged: (Set<String> newSelection) {
              sex.value = newSelection.first;
            },
          ),
          const SizedBox(height: 24),
          
          // Age
          Text(l10n.onboardingAge, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: age.value.toDouble(),
                  min: 12,
                  max: 99,
                  divisions: 87,
                  label: '${age.value} ${l10n.onboardingYears}',
                  onChanged: (value) => age.value = value.toInt(),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  '${age.value} ${l10n.onboardingYears}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Height
          Text(l10n.onboardingHeight, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: height.value.toDouble(),
                  min: 120,
                  max: 220,
                  divisions: 100,
                  label: '${height.value} cm',
                  onChanged: (value) => height.value = value.toInt(),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  '${height.value} cm',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Weight
          Text(l10n.onboardingWeight, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: weight.value,
                  min: 35,
                  max: 250,
                  divisions: 430,
                  label: '${weight.value.toStringAsFixed(1)} kg',
                  onChanged: (value) => weight.value = value,
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  '${weight.value.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Units
          Text(l10n.onboardingPreferredUnits, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.onboardingEnergy, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    SegmentedButton<String>(
                      // Half-width control: the selected-check icon left too
                      // little room and "kcal" wrapped to "kca / l".
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: 'kcal', label: Text(AppLocalizations.of(context)!.kcal, maxLines: 1)),
                        ButtonSegment(value: 'kJ', label: Text('kJ', maxLines: 1)),
                      ],
                      selected: {energyUnit.value},
                      onSelectionChanged: (Set<String> newSelection) {
                        energyUnit.value = newSelection.first;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.onboardingWeightUnit, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'g', label: Text('g', maxLines: 1)),
                        ButtonSegment(value: 'oz', label: Text('oz', maxLines: 1)),
                      ],
                      selected: {weightUnit.value},
                      onSelectionChanged: (Set<String> newSelection) {
                        weightUnit.value = newSelection.first;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: Text(AppLocalizations.of(context)!.onboardingContinue),
            ),
          ),
        ],
      ),
    );
  }
}

// Step 2: Goals
class _GoalsStep extends StatelessWidget {
  final ValueNotifier<String> goal;
  final ValueNotifier<String> activityLevel;
  final ValueNotifier<int> trainingDays;
  final VoidCallback onNext;

  const _GoalsStep({
    required this.goal,
    required this.activityLevel,
    required this.trainingDays,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.onboardingGoalsTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          
          // Goal
          Text(l10n.onboardingGoalTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.onboardingGoalFatLoss),
                selected: goal.value == 'fat_loss',
                onSelected: (_) => goal.value = 'fat_loss',
              ),
              ChoiceChip(
                label: Text(l10n.onboardingGoalMuscleBuild),
                selected: goal.value == 'muscle_gain',
                onSelected: (_) => goal.value = 'muscle_gain',
              ),
              ChoiceChip(
                label: Text(l10n.onboardingGoalMaintenance),
                selected: goal.value == 'maintenance',
                onSelected: (_) => goal.value = 'maintenance',
              ),
              ChoiceChip(
                label: Text(l10n.onboardingGoalMobilityRehab),
                selected: goal.value == 'mobility_rehab',
                onSelected: (_) => goal.value = 'mobility_rehab',
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Activity Level
          Text(l10n.onboardingActivityTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.onboardingActivitySedentary),
                selected: activityLevel.value == 'sedentary',
                onSelected: (_) => activityLevel.value = 'sedentary',
              ),
              ChoiceChip(
                label: Text(l10n.onboardingActivityLight),
                selected: activityLevel.value == 'light',
                onSelected: (_) => activityLevel.value = 'light',
              ),
              ChoiceChip(
                label: Text(l10n.onboardingActivityModerate),
                selected: activityLevel.value == 'moderate',
                onSelected: (_) => activityLevel.value = 'moderate',
              ),
              ChoiceChip(
                label: Text(l10n.onboardingActivityActive),
                selected: activityLevel.value == 'active',
                onSelected: (_) => activityLevel.value = 'active',
              ),
              ChoiceChip(
                label: Text(l10n.onboardingActivityVeryActive),
                selected: activityLevel.value == 'very_active',
                onSelected: (_) => activityLevel.value = 'very_active',
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Training Days
          Text(l10n.onboardingTrainingTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: trainingDays.value.toDouble(),
                  min: 2,
                  max: 6,
                  divisions: 4,
                  label: '${trainingDays.value} days',
                  onChanged: (value) => trainingDays.value = value.toInt(),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  '${trainingDays.value} days',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: Text(AppLocalizations.of(context)!.onboardingContinue),
            ),
          ),
        ],
      ),
    );
  }
}

// Step 3: Equipment
class _EquipmentStep extends StatelessWidget {
  final ValueNotifier<Set<String>> equipment;
  final VoidCallback onNext;

  const _EquipmentStep({
    required this.equipment,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.onboardingEquipmentTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.selectAllThatApply,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text(l10n.onboardingEquipmentNone),
                selected: equipment.value.contains('none'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(equipment.value);
                  if (selected) {
                    newSet.clear();
                    newSet.add('none');
                  } else {
                    newSet.remove('none');
                  }
                  equipment.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingEquipmentDumbbells),
                selected: equipment.value.contains('dumbbells'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(equipment.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('dumbbells');
                  } else {
                    newSet.remove('dumbbells');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  equipment.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingEquipmentBarbell),
                selected: equipment.value.contains('barbell_rack'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(equipment.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('barbell_rack');
                  } else {
                    newSet.remove('barbell_rack');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  equipment.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingEquipmentMachines),
                selected: equipment.value.contains('machines'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(equipment.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('machines');
                  } else {
                    newSet.remove('machines');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  equipment.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingEquipmentBands),
                selected: equipment.value.contains('bands'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(equipment.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('bands');
                  } else {
                    newSet.remove('bands');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  equipment.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingEquipmentKettlebells),
                selected: equipment.value.contains('kettlebells'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(equipment.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('kettlebells');
                  } else {
                    newSet.remove('kettlebells');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  equipment.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingEquipmentCable),
                selected: equipment.value.contains('cable'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(equipment.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('cable');
                  } else {
                    newSet.remove('cable');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  equipment.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingEquipmentPullup),
                selected: equipment.value.contains('pullup_bar'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(equipment.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('pullup_bar');
                  } else {
                    newSet.remove('pullup_bar');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  equipment.value = newSet;
                },
              ),
            ],
          ),
          const SizedBox(height: 48),
          
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: Text(AppLocalizations.of(context)!.onboardingContinue),
            ),
          ),
        ],
      ),
    );
  }
}

// Step 4: Diet
class _DietStep extends StatelessWidget {
  final ValueNotifier<String> dietType;
  final ValueNotifier<String> mealCount;
  final ValueNotifier<Set<String>> exclusions;
  final VoidCallback onNext;

  const _DietStep({
    required this.dietType,
    required this.mealCount,
    required this.exclusions,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.onboardingDietTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          
          // Diet Type
          Text(l10n.onboardingDietTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            // Three segments across a phone width leaves ~113pt each; the
            // selected-check plus a 16-char label made "Omnivore" wrap to
            // "Omnivor / e".
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'omnivore', label: Text(l10n.onboardingDietOmnivore, maxLines: 1)),
              ButtonSegment(value: 'carnivore', label: Text(l10n.onboardingDietCarnivore, maxLines: 1)),
              ButtonSegment(value: 'herbivore', label: Text(l10n.onboardingDietHerbivore, maxLines: 1)),
            ],
            selected: {dietType.value},
            onSelectionChanged: (Set<String> newSelection) {
              dietType.value = newSelection.first;
            },
          ),
          const SizedBox(height: 24),
          
          // Meal Count
          Text(l10n.onboardingMealsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.onboardingMeals2),
                selected: mealCount.value == '2',
                onSelected: (_) => mealCount.value = '2',
              ),
              ChoiceChip(
                label: Text(l10n.onboardingMeals3),
                selected: mealCount.value == '3',
                onSelected: (_) => mealCount.value = '3',
              ),
              ChoiceChip(
                label: Text(l10n.onboardingMeals4),
                selected: mealCount.value == '4',
                onSelected: (_) => mealCount.value = '4',
              ),
              ChoiceChip(
                label: Text(l10n.onboardingMealsIF),
                selected: mealCount.value == 'intermittent_fasting_16_8',
                onSelected: (_) => mealCount.value = 'intermittent_fasting_16_8',
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Exclusions
          Text(l10n.onboardingExclusionsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text(l10n.onboardingExclusionsNone),
                selected: exclusions.value.contains('none'),
                onSelected: (selected) {
                  if (selected) {
                    exclusions.value = {'none'};
                  }
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingExclusionsDairy),
                selected: exclusions.value.contains('dairy'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(exclusions.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('dairy');
                  } else {
                    newSet.remove('dairy');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  exclusions.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingExclusionsGluten),
                selected: exclusions.value.contains('gluten'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(exclusions.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('gluten');
                  } else {
                    newSet.remove('gluten');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  exclusions.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingExclusionsNuts),
                selected: exclusions.value.contains('nuts'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(exclusions.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('nuts');
                  } else {
                    newSet.remove('nuts');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  exclusions.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingExclusionsEggs),
                selected: exclusions.value.contains('eggs'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(exclusions.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('eggs');
                  } else {
                    newSet.remove('eggs');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  exclusions.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingExclusionsShellfish),
                selected: exclusions.value.contains('shellfish'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(exclusions.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('shellfish');
                  } else {
                    newSet.remove('shellfish');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  exclusions.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingExclusionsSoy),
                selected: exclusions.value.contains('soy'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(exclusions.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('soy');
                  } else {
                    newSet.remove('soy');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  exclusions.value = newSet;
                },
              ),
            ],
          ),
          const SizedBox(height: 48),
          
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: Text(AppLocalizations.of(context)!.onboardingContinue),
            ),
          ),
        ],
      ),
    );
  }
}

// Step 5: Injuries
class _InjuriesStep extends StatelessWidget {
  final ValueNotifier<Set<String>> injuries;
  final VoidCallback onNext;

  const _InjuriesStep({
    required this.injuries,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.onboardingInjuriesTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.onboardingInjuriesHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text(l10n.onboardingInjuriesNone),
                selected: injuries.value.contains('none'),
                onSelected: (selected) {
                  if (selected) {
                    injuries.value = {'none'};
                  }
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingInjuriesShoulder),
                selected: injuries.value.contains('shoulder'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(injuries.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('shoulder');
                  } else {
                    newSet.remove('shoulder');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  injuries.value = newSet;
                },
              ),
              FilterChip(
                label: Text(AppLocalizations.of(context)!.back),
                selected: injuries.value.contains('back'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(injuries.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('back');
                  } else {
                    newSet.remove('back');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  injuries.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingInjuriesKnee),
                selected: injuries.value.contains('knee'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(injuries.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('knee');
                  } else {
                    newSet.remove('knee');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  injuries.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingInjuriesAnkle),
                selected: injuries.value.contains('ankle'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(injuries.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('ankle');
                  } else {
                    newSet.remove('ankle');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  injuries.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingInjuriesElbow),
                selected: injuries.value.contains('elbow'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(injuries.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('elbow');
                  } else {
                    newSet.remove('elbow');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  injuries.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingInjuriesHip),
                selected: injuries.value.contains('hip'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(injuries.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('hip');
                  } else {
                    newSet.remove('hip');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  injuries.value = newSet;
                },
              ),
              FilterChip(
                label: Text(l10n.onboardingInjuriesNeck),
                selected: injuries.value.contains('neck'),
                onSelected: (selected) {
                  final newSet = Set<String>.from(injuries.value);
                  newSet.remove('none');
                  if (selected) {
                    newSet.add('neck');
                  } else {
                    newSet.remove('neck');
                  }
                  if (newSet.isEmpty) newSet.add('none');
                  injuries.value = newSet;
                },
              ),
            ],
          ),
          const SizedBox(height: 48),
          
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: Text(AppLocalizations.of(context)!.onboardingContinue),
            ),
          ),
        ],
      ),
    );
  }
}

// Step 6: Summary
class _SummaryStep extends HookConsumerWidget {
  final String sex;
  final int age;
  final int height;
  final double weight;
  final String goal;
  final String activityLevel;
  final int trainingDays;
  final List<String> equipment;
  final String dietType;
  final String mealCount;
  final bool isCompleting;
  final VoidCallback onComplete;

  const _SummaryStep({
    required this.sex,
    required this.age,
    required this.height,
    required this.weight,
    required this.goal,
    required this.activityLevel,
    required this.trainingDays,
    required this.equipment,
    required this.dietType,
    required this.mealCount,
    required this.isCompleting,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupEngine = useMemoized(() => SetupEngineService());
    final isInitialized = useState(false);
    final profileSnapshot = useState<UserProfile?>(null);

    useEffect(() {
      setupEngine.initialize().then((_) {
        isInitialized.value = true;
        profileSnapshot.value = setupEngine.createUserProfile(
          sex: sex,
          ageYears: age,
          heightCm: height,
          weightKg: weight,
          goal: goal,
          activityLevel: activityLevel,
          trainingDaysPerWeek: trainingDays,
          equipment: equipment,
          dietType: dietType,
          mealCountPerDay: mealCount,
          exclusions: [],
          injuries: [],
        );
      });
      return null;
    }, []);

    if (!isInitialized.value || profileSnapshot.value == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = profileSnapshot.value!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.onboardingSummaryTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.onboardingSummarySubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          
          // Targets Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.dailyTargets,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TargetRow(
                    label: 'Calories',
                    value: '${profile.calorieTarget.toStringAsFixed(0)} kcal',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  _TargetRow(
                    label: 'Protein',
                    value: '${profile.proteinTargetG.toStringAsFixed(0)}g',
                    color: Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _TargetRow(
                    label: 'Carbs',
                    value: '${profile.carbsTargetG.toStringAsFixed(0)}g',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _TargetRow(
                    label: 'Fat',
                    value: '${profile.fatTargetG.toStringAsFixed(0)}g',
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Metabolic Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.metabolicInfo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('BMR: ${profile.bmr.toStringAsFixed(0)} kcal'),
                  Text('TDEE: ${profile.tdee.toStringAsFixed(0)} kcal'),
                  Text('Goal: ${_formatGoal(goal)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
          
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isCompleting ? null : onComplete,
              child: isCompleting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(AppLocalizations.of(context)!.onboardingComplete),
            ),
          ),
        ],
      ),
    );
  }

  String _formatGoal(String goal) {
    switch (goal) {
      case 'fat_loss':
        return 'Fat Loss';
      case 'muscle_gain':
        return 'Muscle Gain';
      case 'maintenance':
        return 'Maintenance';
      case 'mobility_rehab':
        return 'Mobility/Rehab';
      default:
        return goal;
    }
  }
}

class _TargetRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TargetRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

