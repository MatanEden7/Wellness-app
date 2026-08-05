import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/user_profile_service.dart';
import '../../../services/setup_engine_service.dart';
import '../../../services/preferences_service.dart';
import '../../../services/content_regeneration_service.dart';
import '../../../services/profile_fit.dart';
import '../../../data/db/drift_database.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_row.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  UserProfile? _profile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _profile = ref.read(userProfileServiceProvider).loadProfile();
  }

  Future<void> _saveProfile(UserProfile updated) async {
    final previous = _profile;
    setState(() {
      _profile = updated;
      _saving = true;
    });
    try {
      await ref.read(userProfileServiceProvider).saveProfile(updated);
      // Write-through to preferences so the dashboard rings stay in sync.
      final prefs = ref.read(preferencesServiceProvider);
      await prefs.setCalorieGoal(updated.calorieTarget);
      await prefs.setProteinGoal(updated.proteinTargetG);
      await prefs.setCarbsGoal(updated.carbsTargetG);
      await prefs.setFatGoal(updated.fatTargetG);
      ref.invalidate(preferencesServiceProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }

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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update your templates?'),
        content: Text(
          'Your profile changed in a way that affects which meals and '
          'workouts suit you.\n\n'
          'Rebuilding replaces ${preview.mealTemplates} generated meal '
          'template(s) and ${preview.workoutTemplates} generated workout '
          'template(s). Anything you created or edited yourself is kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep as is'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Rebuild'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final created = await service.regenerate(profile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rebuilt $created templates')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Recomputes BMR/TDEE/targets when any input field changes and saves.
  Future<void> _recomputeAndSave(UserProfile base) async {
    final engine = SetupEngineService();
    final bmr = engine.calculateBMR(
      sex: base.sex,
      weightKg: base.weightKg,
      heightCm: base.heightCm,
      ageYears: base.ageYears,
    );
    final tdee = engine.calculateTDEE(bmr, base.activityLevel);
    final cal = engine.calculateCalorieTarget(tdee, base.goal);
    final pro = engine.calculateProteinTarget(base.weightKg, base.goal);
    final fat = engine.calculateFatTarget(base.weightKg, cal, pro);
    final carbs = engine.calculateCarbsTarget(cal, pro, fat);

    final updated = base.copyWith(
      bmr: bmr,
      tdee: tdee,
      calorieTarget: cal,
      proteinTargetG: pro,
      fatTargetG: fat,
      carbsTargetG: carbs,
    );
    await _saveProfile(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Targets updated'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<T?> _push<T>(Widget page) =>
      Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

  // ── edit helpers ──────────────────────────────────────────────────────────

  Future<void> _editSex() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<String>(_PickerPage(
      title: 'Sex',
      options: const [
        _Option('male', 'Male'),
        _Option('female', 'Female'),
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
      title: 'Age',
      suffix: 'yr',
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
      title: 'Height',
      suffix: 'cm',
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
      title: 'Weight',
      suffix: 'kg',
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
      title: 'Goal',
      options: const [
        _Option('fat_loss', 'Fat Loss'),
        _Option('muscle_gain', 'Muscle Gain'),
        _Option('maintenance', 'Maintenance'),
        _Option('mobility_rehab', 'Mobility & Rehab'),
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
      title: 'Activity Level',
      options: const [
        _Option('sedentary', 'Sedentary'),
        _Option('light', 'Light'),
        _Option('moderate', 'Moderate'),
        _Option('active', 'Active'),
        _Option('very_active', 'Very Active'),
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
      title: 'Training Days / Week',
      suffix: 'days',
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
      title: 'Calorie Target',
      suffix: 'kcal',
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
      title: 'Protein Target',
      suffix: 'g',
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
      title: 'Carbs Target',
      suffix: 'g',
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
      title: 'Fat Target',
      suffix: 'g',
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
      title: 'Diet Type',
      options: const [
        _Option('omnivore', 'Omnivore'),
        _Option('carnivore', 'Carnivore'),
        _Option('herbivore', 'Plant-based'),
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
      title: 'Meals per Day',
      options: const [
        _Option('2', '2 Meals'),
        _Option('3', '3 Meals'),
        _Option('4', '4 Meals'),
        _Option('intermittent_fasting_16_8', 'Intermittent Fasting 16:8'),
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
      title: 'Food Exclusions',
      options: const [
        _Option('none', 'None'),
        _Option('dairy', 'Dairy'),
        _Option('gluten', 'Gluten'),
        _Option('nuts', 'Nuts'),
        _Option('eggs', 'Eggs'),
        _Option('shellfish', 'Shellfish'),
        _Option('soy', 'Soy'),
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
      title: 'Injuries',
      options: const [
        _Option('none', 'None'),
        _Option('shoulder', 'Shoulder'),
        _Option('back', 'Back'),
        _Option('knee', 'Knee'),
        _Option('ankle', 'Ankle'),
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
      title: 'Equipment',
      options: const [
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

  Future<void> _editEnergyUnit() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<String>(_PickerPage(
      title: 'Energy Unit',
      options: const [
        _Option('kcal', 'kcal (Calories)'),
        _Option('kj', 'kJ (Kilojoules)'),
      ],
      current: p.energyUnit,
    ));
    if (result != null && result != p.energyUnit) {
      await _saveProfile(p.copyWith(energyUnit: result));
    }
  }

  Future<void> _editWeightUnit() async {
    final p = _profile;
    if (p == null) return;
    final result = await _push<String>(_PickerPage(
      title: 'Weight Unit',
      options: const [
        _Option('g', 'Grams (g)'),
        _Option('oz', 'Ounces (oz)'),
      ],
      current: p.weightUnit,
    ));
    if (result != null && result != p.weightUnit) {
      await _saveProfile(p.copyWith(weightUnit: result));
    }
  }

  // ── display helpers ───────────────────────────────────────────────────────

  String _goalLabel(String goal) {
    switch (goal) {
      case 'fat_loss':
        return 'Fat Loss';
      case 'muscle_gain':
        return 'Muscle Gain';
      case 'maintenance':
        return 'Maintenance';
      case 'mobility_rehab':
        return 'Mobility & Rehab';
      default:
        return goal;
    }
  }

  String _activityLabel(String level) {
    switch (level) {
      case 'sedentary':
        return 'Sedentary';
      case 'light':
        return 'Light';
      case 'moderate':
        return 'Moderate';
      case 'active':
        return 'Active';
      case 'very_active':
        return 'Very Active';
      default:
        return level;
    }
  }

  String _mealsLabel(String count) {
    switch (count) {
      case '2':
        return '2 Meals';
      case '3':
        return '3 Meals';
      case '4':
        return '4 Meals';
      case 'intermittent_fasting_16_8':
        return 'IF 16:8';
      default:
        return count;
    }
  }

  String _listLabel(List<String> items) {
    final filtered = items.where((e) => e != 'none').toList();
    if (filtered.isEmpty) return 'None';
    return filtered.map((e) => e[0].toUpperCase() + e.substring(1)).join(', ');
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = _profile;

    if (p == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
            tooltip: 'Back',
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Profile setup not completed'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/onboarding'),
                child: const Text('Complete Setup'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Header card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15),
                      child: Icon(Icons.person,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p.weightKg.toStringAsFixed(1)} kg  ·  ${p.heightCm} cm',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_goalLabel(p.goal)}  ·  ${p.ageYears} yr',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
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
              title: 'Body',
              children: [
                SettingsRow(
                  icon: Icons.wc,
                  iconColor: Colors.blue,
                  title: 'Sex',
                  value: p.sex == 'male' ? 'Male' : 'Female',
                  onTap: _editSex,
                ),
                SettingsRow(
                  icon: Icons.cake,
                  iconColor: Colors.orange,
                  title: 'Age',
                  value: '${p.ageYears} yr',
                  onTap: _editAge,
                ),
                SettingsRow(
                  icon: Icons.height,
                  iconColor: Colors.teal,
                  title: 'Height',
                  value: '${p.heightCm} cm',
                  onTap: _editHeight,
                ),
                SettingsRow(
                  icon: Icons.monitor_weight,
                  iconColor: Colors.green,
                  title: 'Weight',
                  value: '${p.weightKg.toStringAsFixed(1)} kg',
                  onTap: _editWeight,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Goal & Activity
            SettingsSection(
              title: 'Goal & Activity',
              children: [
                SettingsRow(
                  icon: Icons.flag,
                  iconColor: Colors.red,
                  title: 'Goal',
                  value: _goalLabel(p.goal),
                  onTap: _editGoal,
                ),
                SettingsRow(
                  icon: Icons.directions_run,
                  iconColor: Colors.deepOrange,
                  title: 'Activity Level',
                  value: _activityLabel(p.activityLevel),
                  onTap: _editActivityLevel,
                ),
                SettingsRow(
                  icon: Icons.event_repeat,
                  iconColor: Colors.purple,
                  title: 'Training Days / Week',
                  value: '${p.trainingDaysPerWeek}',
                  onTap: _editTrainingDays,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nutrition Targets
            SettingsSection(
              title: 'Nutrition Targets',
              children: [
                SettingsRow(
                  icon: Icons.local_fire_department,
                  iconColor: Colors.orange,
                  title: 'Calories',
                  value: '${p.calorieTarget.toInt()} kcal',
                  onTap: _editCalorieTarget,
                ),
                SettingsRow(
                  icon: Icons.egg_alt,
                  iconColor: Colors.red,
                  title: 'Protein',
                  value: '${p.proteinTargetG.toInt()} g',
                  onTap: _editProteinTarget,
                ),
                SettingsRow(
                  icon: Icons.grain,
                  iconColor: Colors.amber,
                  title: 'Carbs',
                  value: '${p.carbsTargetG.toInt()} g',
                  onTap: _editCarbsTarget,
                ),
                SettingsRow(
                  icon: Icons.water_drop,
                  iconColor: Colors.lightBlue,
                  title: 'Fat',
                  value: '${p.fatTargetG.toInt()} g',
                  onTap: _editFatTarget,
                ),
                SettingsRow(
                  icon: Icons.bolt,
                  iconColor: Colors.indigo,
                  title: 'BMR',
                  value: '${p.bmr.toInt()} kcal',
                  showChevron: false,
                ),
                SettingsRow(
                  icon: Icons.bar_chart,
                  iconColor: Colors.teal,
                  title: 'TDEE',
                  value: '${p.tdee.toInt()} kcal',
                  showChevron: false,
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.refresh, color: Colors.green, size: 19),
                  ),
                  title: const Text('Recalculate from Body & Goal'),
                  onTap: () => _recomputeAndSave(p),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Food & Diet
            SettingsSection(
              title: 'Food & Diet',
              children: [
                SettingsRow(
                  icon: Icons.restaurant,
                  iconColor: Colors.deepOrange,
                  title: 'Diet Type',
                  value: p.dietType == 'herbivore'
                      ? 'Plant-based'
                      : p.dietType[0].toUpperCase() + p.dietType.substring(1),
                  onTap: _editDietType,
                ),
                SettingsRow(
                  icon: Icons.dining,
                  iconColor: Colors.brown,
                  title: 'Meals per Day',
                  value: _mealsLabel(p.mealCountPerDay),
                  onTap: _editMealsPerDay,
                ),
                SettingsRow(
                  icon: Icons.no_food,
                  iconColor: Colors.red,
                  title: 'Food Exclusions',
                  value: _listLabel(p.exclusions),
                  onTap: _editExclusions,
                ),
                SettingsRow(
                  icon: Icons.healing,
                  iconColor: Colors.pink,
                  title: 'Injuries',
                  value: _listLabel(p.injuries),
                  onTap: _editInjuries,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Equipment
            SettingsSection(
              title: 'Equipment',
              children: [
                SettingsRow(
                  icon: Icons.fitness_center,
                  iconColor: Colors.blueGrey,
                  title: 'Available Equipment',
                  value: _listLabel(p.equipment),
                  onTap: _editEquipment,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Units
            SettingsSection(
              title: 'Units',
              children: [
                SettingsRow(
                  icon: Icons.flash_on,
                  iconColor: Colors.yellow.shade700,
                  title: 'Energy Unit',
                  value: p.energyUnit.toUpperCase(),
                  onTap: _editEnergyUnit,
                ),
                SettingsRow(
                  icon: Icons.scale,
                  iconColor: Colors.indigo,
                  title: 'Weight Unit',
                  value: p.weightUnit,
                  onTap: _editWeightUnit,
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: options.map((opt) {
            final selected = opt.value == current;
            return ListTile(
              title: Text(opt.label),
              trailing: selected
                  ? Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(opt.value),
            );
          }).toList(),
        ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_selected.toList()),
            child: Text(
              'Done',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: widget.options.map((opt) {
            final isSelected = _selected.contains(opt.value);
            return CheckboxListTile(
              title: Text(opt.label),
              value: isSelected,
              onChanged: (_) => _toggle(opt.value),
            );
          }).toList(),
        ),
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
      setState(
          () => _error = '${widget.min.toInt()}–${widget.max.toInt()}');
      return;
    }
    final result = widget.integer ? d.round() as T : d as T;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        actions: [
          TextButton(
            onPressed: _submit,
            child: Text('Save',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: widget.integer
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]'))
                      ],
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
        ),
      ),
    );
  }
}
