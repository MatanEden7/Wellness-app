import 'package:flutter/material.dart';

import '../../../shell/platform_page.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wellness_app/l10n/app_localizations.dart';

import '../../../services/preferences_service.dart';

class NutritionGoalsPage extends ConsumerStatefulWidget {
  const NutritionGoalsPage({super.key});

  @override
  ConsumerState<NutritionGoalsPage> createState() => _NutritionGoalsPageState();
}

class _NutritionGoalsPageState extends ConsumerState<NutritionGoalsPage> {
  late final TextEditingController _calorieCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesServiceProvider);
    _calorieCtrl = TextEditingController(
        text: prefs.calorieGoal?.toInt().toString() ?? '');
    _proteinCtrl = TextEditingController(
        text: prefs.proteinGoal?.toInt().toString() ?? '');
    _carbsCtrl = TextEditingController(
        text: prefs.carbsGoal?.toInt().toString() ?? '');
    _fatCtrl =
        TextEditingController(text: prefs.fatGoal?.toInt().toString() ?? '');
    for (final c in [_calorieCtrl, _proteinCtrl, _carbsCtrl, _fatCtrl]) {
      c.addListener(() => setState(() => _dirty = true));
    }
  }

  @override
  void dispose() {
    _calorieCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setCalorieGoal(
        _calorieCtrl.text.isEmpty ? null : double.tryParse(_calorieCtrl.text));
    await prefs.setProteinGoal(
        _proteinCtrl.text.isEmpty ? null : double.tryParse(_proteinCtrl.text));
    await prefs.setCarbsGoal(
        _carbsCtrl.text.isEmpty ? null : double.tryParse(_carbsCtrl.text));
    await prefs.setFatGoal(
        _fatCtrl.text.isEmpty ? null : double.tryParse(_fatCtrl.text));
    ref.invalidate(preferencesServiceProvider);
    if (mounted) {
      setState(() => _dirty = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PlatformChildPage(
      chrome: PageChrome(
        title: l10n.nutritionGoals,
        backTooltip: l10n.back,
        actions: [
          ChromeAction(
            label: l10n.save,
            tooltip: l10n.save,
            isProminent: true,
            onPressed: _dirty ? _save : null,
          ),
        ],
      ),
      child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Set your daily nutrition targets. Leave a field empty to disable that goal.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 24),
              _GoalField(
                controller: _calorieCtrl,
                label: l10n.calorieGoal,
                suffix: l10n.kcal,
                min: 800,
                max: 20000,
              ),
              const SizedBox(height: 16),
              _GoalField(
                controller: _proteinCtrl,
                label: l10n.proteinGoal,
                suffix: l10n.grams,
                min: 10,
                max: 600,
              ),
              const SizedBox(height: 16),
              _GoalField(
                controller: _carbsCtrl,
                label: l10n.carbsGoal,
                suffix: l10n.grams,
                min: 10,
                max: 600,
              ),
              const SizedBox(height: 16),
              _GoalField(
                controller: _fatCtrl,
                label: l10n.fatGoal,
                suffix: l10n.grams,
                min: 10,
                max: 600,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _dirty ? _save : null,
                child: Text(l10n.save),
              ),
            ],
          ),
      ),
    );
  }
}

class _GoalField extends StatelessWidget {
  const _GoalField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.min,
    required this.max,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.left,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        hintText: AppLocalizations.of(context)!.optional,
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return null;
        final d = double.tryParse(val);
        if (d == null || d < min || d > max) {
          return '${min.toInt()}–${max.toInt()} $suffix';
        }
        return null;
      },
    );
  }
}
