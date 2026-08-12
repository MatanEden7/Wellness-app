import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/ios/glass.dart';
import '../../data/body_weight_repository.dart';

/// Quick weigh-in entry.
///
/// Pre-filled with the last recorded weight, because the realistic edit is
/// "81.4 -> 81.2" and retyping the whole number every morning is how a log
/// stops being kept.
Future<void> showLogWeightSheet(BuildContext context, WidgetRef ref) async {
  final repository = ref.read(bodyWeightRepositoryProvider);
  final latest = await repository.latest();
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (context) => GlassSheet(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: _LogWeightForm(
          initialKg: latest?.kg,
          onSubmit: (kg) => repository.log(kg),
        ),
      ),
    ),
  );
}

class _LogWeightForm extends StatefulWidget {
  final double? initialKg;
  final Future<void> Function(double kg) onSubmit;

  const _LogWeightForm({required this.initialKg, required this.onSubmit});

  @override
  State<_LogWeightForm> createState() => _LogWeightFormState();
}

class _LogWeightFormState extends State<_LogWeightForm> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialKg?.toStringAsFixed(1) ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final kg = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    // A fat-fingered 8.14 or 814 would wreck the axis on every chart that
    // shares this data, so it is rejected here rather than filtered later.
    if (kg == null || kg < 20 || kg > 400) {
      setState(() =>
          _error = AppLocalizations.of(context)!.analyticsWeightSheetError);
      return;
    }
    await widget.onSubmit(kg);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.analyticsWeightSheetTitle,
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          l10n.analyticsWeightSheetSubtitle,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            suffixText: 'kg',
            errorText: _error,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: GlassButton(
            prominent: true,
            onPressed: _submit,
            child: Text(l10n.save),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
