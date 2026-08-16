import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../shell/platform_page.dart';
import '../../../core/ios/inset_list.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/user_profile_service.dart';
import '../../../services/setup_engine_service.dart';
import '../../../services/preferences_service.dart';
import '../../../services/content_regeneration_service.dart';
import '../../../services/profile_fit.dart';
import '../../../data/db/drift_database.dart';
import '../../calendar/data/calendar_service.dart';
import '../../../core/ios/glass.dart';
import '../../../core/widgets.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_row.dart';
import '../../../core/design/tokens.dart';
import '../../../core/ios/feedback.dart';
import '../../../core/ios/sheets.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  UserProfile? _profile;

  /// Every label on this page went through here. ISSUES #84 estimated ~29
  /// new Hebrew strings; in the event 35 of the 55 literals already had ARB
  /// keys and only 16 were genuinely new -- the page was not untranslated so
  /// much as unwired.
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  @override
  void initState() {
    super.initState();
    _profile = ref.read(userProfileServiceProvider).loadProfile();
  }

  Future<void> _saveProfile(UserProfile updated) async {
    final previous = _profile;
    setState(() => _profile = updated);
    await ref.read(userProfileServiceProvider).saveProfile(updated);
    // Write-through to preferences so the dashboard rings stay in sync.
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setCalorieGoal(updated.calorieTarget);
    await prefs.setProteinGoal(updated.proteinTargetG);
    await prefs.setCarbsGoal(updated.carbsTargetG);
    await prefs.setFatGoal(updated.fatTargetG);
    ref.invalidate(preferencesServiceProvider);

    // Changing diet, exclusions, equipment, injuries, training days or meal
    // count changes *which content suits the user*, so the templates
    // generated from the old answers may no longer fit. Offer to rebuild --
    // never do it silently, since it discards templates they may have been
    // using all week. Target-only changes (goal, weight, activity) don't
    // qualify; see ProfileFit.contentAffectingFieldsChanged.
    if (previous != null &&
        ProfileFit.contentAffectingFieldsChanged(previous, updated)) {
      await _offerRegeneration(updated);
    }
  }

  Future<void> _offerRegeneration(UserProfile profile) async {
    final service = ContentRegenerationService(ref.read(databaseProvider));
    final preview = await service.preview();
    if (!mounted) return;

    // Nothing generated to replace -- do nothing. This used to silently call
    // regenerate(), which runs both generators (and the meal generator now
    // does a least-squares solve per meal). That put real work on a profile
    // *save* path, unprompted, and generating content the user never asked
    // for is surprising in its own right: if they skipped the schedule at
    // onboarding, a weight edit should not conjure one.
    if (preview.isEmpty) return;

    final confirmed = await showAppConfirm(
      context: context,
      title: l10n.profileRegenTitle,
      message: l10n.profileRegenBody(
          preview.mealTemplates, preview.workoutTemplates),
      confirmLabel: 'Rebuild',
      // Rebuilding is additive and reversible -- red would overstate it.
      isDestructive: false,
    );
    if (!confirmed) return;

    final created = await service.regenerate(profile);
    // Regeneration rebuilds templates under fresh ids, leaving every
    // calendar event onboarding pinned to the old ones pointing at nothing.
    // Silent until the user presses "Approve" or "Start Workout" on a
    // reminder and it does nothing at all.
    await ref.read(calendarStateProvider.notifier).repinDanglingTemplates();
    if (mounted) {
      showAppSuccess(context, 'Rebuilt $created templates');
    }
  }

  /// Recomputes BMR/TDEE/targets when any input field changes and saves.
  Future<void> _recomputeAndSave(UserProfile base) async {
    // Same solver onboarding uses -- the targets must not depend on which
    // screen recomputed them.
    final targets = SetupEngineService().calculateTargets(
      sex: base.sex,
      weightKg: base.weightKg,
      heightCm: base.heightCm,
      ageYears: base.ageYears,
      goal: base.goal,
      activityLevel: base.activityLevel,
    );

    final updated = base.copyWith(
      bmr: targets.bmr,
      tdee: targets.tdee,
      calorieTarget: targets.calories,
      proteinTargetG: targets.proteinG,
      fatTargetG: targets.fatG,
      carbsTargetG: targets.carbsG,
    );
    await _saveProfile(updated);
    if (mounted) {
      showAppSuccess(context, 'Targets updated');
    }
  }

  Future<T?> _push<T>(Widget page) =>
      Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

  // ── edit helpers ──────────────────────────────────────────────────────────

  Future<void> _editSex() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<String>(_PickerPage(
      title: l10n.onboardingSex,
      options: [
        _Option('male', l10n.onboardingMale),
        _Option('female', l10n.onboardingFemale),
      ],
      current: p.sex,
    ));
    if (result != null && result != p.sex) {
      await _recomputeAndSave(p.copyWith(sex: result));
    }
  }

  Future<void> _editAge() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<int>(_NumberPage(
      title: l10n.onboardingAge,
      suffix: l10n.onboardingYears,
      initial: p.ageYears,
      min: 13,
      max: 100,
      integer: true,
    ));
    if (result != null && result != p.ageYears) {
      await _recomputeAndSave(p.copyWith(ageYears: result));
    }
  }

  Future<void> _editHeight() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<int>(_NumberPage(
      title: l10n.onboardingHeight,
      suffix: l10n.centimetersShort,
      initial: p.heightCm,
      min: 100,
      max: 250,
      integer: true,
    ));
    if (result != null && result != p.heightCm) {
      await _recomputeAndSave(p.copyWith(heightCm: result));
    }
  }

  Future<void> _editWeight() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<double>(_NumberPage(
      title: l10n.weight,
      suffix: l10n.kg,
      initial: p.weightKg,
      min: 30,
      max: 300,
      integer: false,
    ));
    if (result != null && result != p.weightKg) {
      await _recomputeAndSave(p.copyWith(weightKg: result));
    }
  }

  Future<void> _editGoal() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<String>(_PickerPage(
      title: l10n.onboardingGoalLabel,
      options: [
        _Option('fat_loss', l10n.onboardingGoalFatLoss),
        _Option('muscle_gain', l10n.onboardingGoalMuscleBuild),
        _Option('maintenance', l10n.onboardingGoalMaintenance),
        _Option('mobility_rehab', l10n.onboardingGoalMobilityRehab),
      ],
      current: p.goal,
    ));
    if (result != null && result != p.goal) {
      await _recomputeAndSave(p.copyWith(goal: result));
    }
  }

  Future<void> _editActivityLevel() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<String>(_PickerPage(
      title: l10n.onboardingActivityLevel,
      options: [
        _Option('sedentary', l10n.onboardingActivitySedentary),
        _Option('light', l10n.light),
        _Option('moderate', l10n.onboardingActivityModerate),
        _Option('active', l10n.active),
        _Option('very_active', l10n.onboardingActivityVeryActive),
      ],
      current: p.activityLevel,
    ));
    if (result != null && result != p.activityLevel) {
      await _recomputeAndSave(p.copyWith(activityLevel: result));
    }
  }

  Future<void> _editTrainingDays() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<int>(_NumberPage(
      title: l10n.profileTrainingDaysWeek,
      suffix: l10n.onboardingDays,
      initial: p.trainingDaysPerWeek,
      min: 1,
      max: 7,
      integer: true,
    ));
    if (result != null && result != p.trainingDaysPerWeek) {
      await _saveProfile(p.copyWith(trainingDaysPerWeek: result));
    }
  }

  Future<void> _editCalorieTarget() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<double>(_NumberPage(
      title: l10n.profileCalorieTarget,
      suffix: l10n.kcal,
      initial: p.calorieTarget,
      min: 800,
      max: 20000,
      integer: false,
    ));
    if (result != null) {
      await _saveProfile(p.copyWith(calorieTarget: result));
    }
  }

  Future<void> _editProteinTarget() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<double>(_NumberPage(
      title: l10n.profileProteinTarget,
      suffix: l10n.grams,
      initial: p.proteinTargetG,
      min: 10,
      max: 600,
      integer: false,
    ));
    if (result != null) {
      await _saveProfile(p.copyWith(proteinTargetG: result));
    }
  }

  Future<void> _editCarbsTarget() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<double>(_NumberPage(
      title: l10n.profileCarbsTarget,
      suffix: l10n.grams,
      initial: p.carbsTargetG,
      min: 10,
      max: 600,
      integer: false,
    ));
    if (result != null) {
      await _saveProfile(p.copyWith(carbsTargetG: result));
    }
  }

  Future<void> _editFatTarget() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<double>(_NumberPage(
      title: l10n.profileFatTarget,
      suffix: l10n.grams,
      initial: p.fatTargetG,
      min: 10,
      max: 300,
      integer: false,
    ));
    if (result != null) {
      await _saveProfile(p.copyWith(fatTargetG: result));
    }
  }

  Future<void> _editDietType() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<String>(_PickerPage(
      title: l10n.onboardingDietType,
      options: [
        _Option('omnivore', l10n.onboardingDietOmnivore),
        _Option('carnivore', l10n.onboardingDietCarnivore),
        _Option('herbivore', l10n.onboardingDietHerbivore),
      ],
      current: p.dietType,
    ));
    if (result != null && result != p.dietType) {
      await _saveProfile(p.copyWith(dietType: result));
    }
  }

  Future<void> _editMealsPerDay() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<String>(_PickerPage(
      title: l10n.onboardingMealsPerDay,
      options: [
        _Option('2', l10n.onboardingMeals2),
        _Option('3', l10n.onboardingMeals3),
        _Option('4', l10n.onboardingMeals4),
        _Option('intermittent_fasting_16_8', l10n.onboardingMealsIF),
      ],
      current: p.mealCountPerDay,
    ));
    if (result != null && result != p.mealCountPerDay) {
      await _saveProfile(p.copyWith(mealCountPerDay: result));
    }
  }

  Future<void> _editExclusions() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<List<String>>(_MultiPickerPage(
      title: l10n.onboardingExclusions,
      options: [
        _Option('none', l10n.onboardingExclusionsNone),
        _Option('dairy', l10n.onboardingExclusionsDairy),
        _Option('gluten', l10n.onboardingExclusionsGluten),
        _Option('nuts', l10n.onboardingExclusionsNuts),
        _Option('eggs', l10n.onboardingExclusionsEggs),
        _Option('shellfish', l10n.onboardingExclusionsShellfish),
        _Option('soy', l10n.onboardingExclusionsSoy),
      ],
      current: p.exclusions,
      noneValue: 'none',
    ));
    if (result != null) {
      await _saveProfile(p.copyWith(exclusions: result));
    }
  }

  Future<void> _editInjuries() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<List<String>>(_MultiPickerPage(
      title: l10n.profileInjuries,
      options: [
        _Option('none', l10n.onboardingExclusionsNone),
        _Option('shoulder', l10n.onboardingInjuriesShoulder),
        _Option('back', l10n.onboardingInjuriesBack),
        _Option('knee', l10n.onboardingInjuriesKnee),
        _Option('ankle', l10n.onboardingInjuriesAnkle),
        _Option('elbow', 'Elbow'),
        _Option('hip', 'Hip'),
        _Option('neck', 'Neck'),
      ],
      current: p.injuries,
      noneValue: 'none',
    ));
    if (result != null) {
      await _saveProfile(p.copyWith(injuries: result));
    }
  }

  Future<void> _editEquipment() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<List<String>>(_MultiPickerPage(
      title: l10n.equipmentLabel,
      options: [
        _Option('none', 'No Equipment'),
        _Option('dumbbells', 'Dumbbells'),
        _Option('barbell_rack', 'Barbell & Rack'),
        _Option('machines', 'Machines'),
        _Option('bands', 'Resistance Bands'),
        _Option('kettlebells', 'Kettlebells'),
        _Option('cable', 'Cable Machine'),
        _Option('pullup_bar', 'Pull-up Bar'),
      ],
      current: p.equipment,
      noneValue: 'none',
    ));
    if (result != null) {
      await _saveProfile(p.copyWith(equipment: result));
    }
  }

  // ── display helpers ───────────────────────────────────────────────────────

  String _goalLabel(String goal) {
    switch (goal) {
      case 'fat_loss':
        return l10n.onboardingGoalFatLoss;
      case 'muscle_gain':
        return l10n.onboardingGoalMuscleBuild;
      case 'maintenance':
        return l10n.onboardingGoalMaintenance;
      case 'mobility_rehab':
        return l10n.onboardingGoalMobilityRehab;
      default:
        return goal;
    }
  }

  String _activityLabel(String level) {
    switch (level) {
      case 'sedentary':
        return l10n.onboardingActivitySedentary;
      case 'light':
        return l10n.light;
      case 'moderate':
        return l10n.onboardingActivityModerate;
      case 'active':
        return l10n.active;
      case 'very_active':
        return l10n.onboardingActivityVeryActive;
      default:
        return level;
    }
  }

  String _mealsLabel(String count) {
    switch (count) {
      case '2':
        return l10n.onboardingMeals2;
      case '3':
        return l10n.onboardingMeals3;
      case '4':
        return l10n.onboardingMeals4;
      case 'intermittent_fasting_16_8':
        return l10n.onboardingMealsIF;
      default:
        return count;
    }
  }

  String _dietLabel(String diet) => switch (diet) {
        'omnivore' => l10n.onboardingDietOmnivore,
        'carnivore' => l10n.onboardingDietCarnivore,
        'herbivore' => l10n.onboardingDietHerbivore,
        _ => diet,
      };

  /// Stored ids -> display labels.
  ///
  /// Was `id[0].toUpperCase() + id.substring(1)`, which renders the raw id in
  /// any language ("Dairy", "Barbell_rack") and never had a Hebrew path at
  /// all. Every one of these already has an ARB key from onboarding.
  String _itemLabel(String id) => switch (id) {
        'dairy' => l10n.onboardingExclusionsDairy,
        'gluten' => l10n.onboardingExclusionsGluten,
        'nuts' => l10n.onboardingExclusionsNuts,
        'eggs' => l10n.onboardingExclusionsEggs,
        'shellfish' => l10n.onboardingExclusionsShellfish,
        'soy' => l10n.onboardingExclusionsSoy,
        'shoulder' => l10n.onboardingInjuriesShoulder,
        'back' => l10n.onboardingInjuriesBack,
        'knee' => l10n.onboardingInjuriesKnee,
        'ankle' => l10n.onboardingInjuriesAnkle,
        'dumbbells' => l10n.onboardingEquipmentDumbbells,
        'barbell_rack' => l10n.onboardingEquipmentBarbell,
        'machines' => l10n.onboardingEquipmentMachines,
        'bands' => l10n.onboardingEquipmentBands,
        'kettlebells' => l10n.onboardingEquipmentKettlebells,
        'cable' => l10n.onboardingEquipmentCable,
        'pullup_bar' => l10n.onboardingEquipmentPullup,
        _ => id[0].toUpperCase() + id.substring(1),
      };

  String _listLabel(List<String> items) {
    final filtered = items.where((e) => e != 'none').toList();
    if (filtered.isEmpty) return l10n.onboardingExclusionsNone;
    return filtered.map(_itemLabel).join(', ');
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = _profile;

    if (p == null) {
      return PlatformPage(
        chrome: PageChrome(title: l10n.profileTitle),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.profileNotCompleted),
                  const SizedBox(height: 24),
                  GlassButton(
                    prominent: true,
                    onPressed: () => context.go('/onboarding'),
                    child: Text(l10n.onboardingComplete),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return PlatformChildPage(
      chrome: PageChrome(
        title: l10n.profileTitle,
        // Saving spinner shown inline above content instead of in the action
        // slot, since PageChrome actions are typed data, not widgets.
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header card
          AppCard(
            borderRadius: BorderRadius.circular(16),
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(Space.xl),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15),
                    child: Icon(Icons.person,
                        size: 32, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p.weightKg.toStringAsFixed(1)} ${l10n.kg}  ·  ${p.heightCm} ${l10n.centimetersShort}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_goalLabel(p.goal)}  ·  ${p.ageYears} ${l10n.onboardingYears}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Body
          SettingsSection(
            title: l10n.profileSectionBody,
            children: [
              SettingsRow(
                icon: Icons.wc,
                iconColor: Colors.blue,
                title: l10n.onboardingSex,
                value: p.sex == 'male'
                    ? l10n.onboardingMale
                    : l10n.onboardingFemale,
                onTap: _editSex,
              ),
              SettingsRow(
                icon: Icons.cake,
                iconColor: Colors.orange,
                title: l10n.onboardingAge,
                value: '${p.ageYears} ${l10n.onboardingYears}',
                onTap: _editAge,
              ),
              SettingsRow(
                icon: Icons.height,
                iconColor: Colors.teal,
                title: l10n.onboardingHeight,
                value: '${p.heightCm} ${l10n.centimetersShort}',
                onTap: _editHeight,
              ),
              SettingsRow(
                icon: Icons.monitor_weight,
                iconColor: Colors.green,
                title: l10n.weight,
                value: '${p.weightKg.toStringAsFixed(1)} ${l10n.kg}',
                onTap: _editWeight,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Goal & Activity
          SettingsSection(
            title: l10n.profileSectionGoal,
            children: [
              SettingsRow(
                icon: Icons.flag,
                iconColor: Colors.red,
                title: l10n.onboardingGoalLabel,
                value: _goalLabel(p.goal),
                onTap: _editGoal,
              ),
              SettingsRow(
                icon: Icons.directions_run,
                iconColor: Colors.deepOrange,
                title: l10n.onboardingActivityLevel,
                value: _activityLabel(p.activityLevel),
                onTap: _editActivityLevel,
              ),
              SettingsRow(
                icon: Icons.event_repeat,
                iconColor: Colors.purple,
                title: l10n.profileTrainingDaysWeek,
                value: '${p.trainingDaysPerWeek}',
                onTap: _editTrainingDays,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Nutrition Targets
          SettingsSection(
            title: l10n.profileSectionTargets,
            children: [
              SettingsRow(
                icon: Icons.local_fire_department,
                iconColor: Colors.orange,
                title: l10n.calories,
                value: '${p.calorieTarget.toInt()} ${l10n.kcal}',
                onTap: _editCalorieTarget,
              ),
              SettingsRow(
                icon: Icons.egg_alt,
                iconColor: Colors.red,
                title: l10n.protein,
                value: '${p.proteinTargetG.toInt()} ${l10n.grams}',
                onTap: _editProteinTarget,
              ),
              SettingsRow(
                icon: Icons.grain,
                iconColor: Colors.amber,
                title: l10n.carbs,
                value: '${p.carbsTargetG.toInt()} ${l10n.grams}',
                onTap: _editCarbsTarget,
              ),
              SettingsRow(
                icon: Icons.water_drop,
                iconColor: Colors.lightBlue,
                title: l10n.fat,
                value: '${p.fatTargetG.toInt()} ${l10n.grams}',
                onTap: _editFatTarget,
              ),
              SettingsRow(
                icon: Icons.bolt,
                iconColor: Colors.indigo,
                title: l10n.onboardingBMR,
                value: '${p.bmr.toInt()} ${l10n.kcal}',
                showChevron: false,
              ),
              SettingsRow(
                icon: Icons.bar_chart,
                iconColor: Colors.teal,
                title: l10n.onboardingTDEE,
                value: '${p.tdee.toInt()} ${l10n.kcal}',
                showChevron: false,
              ),
              // InsetRow, not ListTile: inside a glass SettingsSection there is
              // no Material ancestor for ListTile to resolve its ink and
              // background against, and Flutter asserts rather than degrading.
              // The settings rows were converted for this; this one was missed,
              // and it is what three profile integration tests were tripping on.
              InsetRow(
                icon: Icons.refresh,
                iconColor: Colors.green,
                title: l10n.profileRecalculate,
                onTap: () => _recomputeAndSave(p),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Food & Diet
          SettingsSection(
            title: l10n.profileSectionFood,
            children: [
              SettingsRow(
                icon: Icons.restaurant,
                iconColor: Colors.deepOrange,
                title: l10n.onboardingDietType,
                value: _dietLabel(p.dietType),
                onTap: _editDietType,
              ),
              SettingsRow(
                icon: Icons.dining,
                iconColor: Colors.brown,
                title: l10n.onboardingMealsPerDay,
                value: _mealsLabel(p.mealCountPerDay),
                onTap: _editMealsPerDay,
              ),
              SettingsRow(
                icon: Icons.no_food,
                iconColor: Colors.red,
                title: l10n.onboardingExclusions,
                value: _listLabel(p.exclusions),
                onTap: _editExclusions,
              ),
              SettingsRow(
                icon: Icons.healing,
                iconColor: Colors.pink,
                title: l10n.profileInjuries,
                value: _listLabel(p.injuries),
                onTap: _editInjuries,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Equipment
          SettingsSection(
            title: l10n.equipmentLabel,
            children: [
              SettingsRow(
                icon: Icons.fitness_center,
                iconColor: Colors.blueGrey,
                title: l10n.onboardingEquipment,
                value: _listLabel(p.equipment),
                onTap: _editEquipment,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // The Units section (energy / weight unit) used to sit here.
          // Removed with the onboarding picker: the app works in grams and
          // kcal everywhere, so offering oz/kJ was a choice that changed
          // nothing downstream. `energyUnit`/`weightUnit` stay on the
          // profile at their defaults, so the stored shape is unchanged.
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Generic picker pages ──────────────────────────────────────────────────────

class _Option {
  const _Option(this.value, this.label);
  final String value;
  final String label;
}

class _PickerPage extends StatelessWidget {
  const _PickerPage({
    required this.title,
    required this.options,
    required this.current,
  });

  final String title;
  final List<_Option> options;
  final String current;

  @override
  Widget build(BuildContext context) {
    return PlatformChildPage(
      chrome: PageChrome(title: title),
      child: InsetSection(
        children: [
          for (final opt in options)
            InsetRow(
              title: opt.label,
              onTap: () => Navigator.of(context).pop(opt.value),
              trailing: SizedBox(
                width: 20,
                child: opt.value == current
                    ? Icon(CupertinoIcons.check_mark,
                        size: 18, color: Theme.of(context).colorScheme.primary)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _MultiPickerPage extends StatefulWidget {
  const _MultiPickerPage({
    required this.title,
    required this.options,
    required this.current,
    required this.noneValue,
  });

  final String title;
  final List<_Option> options;
  final List<String> current;
  final String noneValue;

  @override
  State<_MultiPickerPage> createState() => _MultiPickerPageState();
}

class _MultiPickerPageState extends State<_MultiPickerPage> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.current);
  }

  void _toggle(String value) {
    setState(() {
      if (value == widget.noneValue) {
        _selected = {widget.noneValue};
      } else {
        _selected.remove(widget.noneValue);
        if (_selected.contains(value)) {
          _selected.remove(value);
          if (_selected.isEmpty) _selected = {widget.noneValue};
        } else {
          _selected.add(value);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PlatformChildPage(
      chrome: PageChrome(
        title: widget.title,
        actions: [
          ChromeAction(
            label: AppLocalizations.of(context)!.done,
            tooltip: AppLocalizations.of(context)!.done,
            isProminent: true,
            onPressed: () => Navigator.of(context).pop(_selected.toList()),
          ),
        ],
      ),
      child: InsetSection(
        children: [
          for (final opt in widget.options)
            InsetRow(
              title: opt.label,
              onTap: () => _toggle(opt.value),
              trailing: SizedBox(
                width: 20,
                child: _selected.contains(opt.value)
                    ? Icon(CupertinoIcons.check_mark,
                        size: 18, color: Theme.of(context).colorScheme.primary)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _NumberPage<T extends num> extends StatefulWidget {
  const _NumberPage({
    required this.title,
    required this.suffix,
    required this.initial,
    required this.min,
    required this.max,
    required this.integer,
  });

  final String title;
  final String suffix;
  final T initial;
  final double min;
  final double max;
  final bool integer;

  @override
  State<_NumberPage<T>> createState() => _NumberPageState<T>();
}

class _NumberPageState<T extends num> extends State<_NumberPage<T>> {
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.integer
          ? widget.initial.toInt().toString()
          : (widget.initial as double).toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _ctrl.text.trim();
    final d = double.tryParse(raw);
    if (d == null) {
      setState(() => _error = 'Enter a number');
      return;
    }
    if (d < widget.min || d > widget.max) {
      setState(() => _error = '${widget.min.toInt()}–${widget.max.toInt()}');
      return;
    }
    final result = widget.integer ? d.round() as T : d as T;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformChildPage(
      chrome: PageChrome(
        title: widget.title,
        actions: [
          ChromeAction(
              label: AppLocalizations.of(context)!.save,
              tooltip: AppLocalizations.of(context)!.save,
              isProminent: true,
              onPressed: _submit),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: widget.integer
                ? [FilteringTextInputFormatter.digitsOnly]
                : [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            autofocus: true,
            decoration: InputDecoration(
              suffixText: widget.suffix,
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.min.toInt()}–${widget.max.toInt()} ${widget.suffix}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }
}
