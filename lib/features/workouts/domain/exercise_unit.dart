import 'package:wellness_app/l10n/app_localizations.dart';

/// The label to show for an exercise's stored `unit`.
///
/// `Exercise.unit` is an **id**, not a display string: `'kg'`, `'lb'`,
/// `'bodyweight'`, `'band'`, `'min'`. The rest of the app branches on those
/// ids -- `unit == 'kg'` decides whether a prescribed weight is even
/// meaningful -- so they must stay in English in the database and be mapped
/// here at render time. That is the "never translate an id in place" rule in
/// `docs/REPO_GUIDE.md`, and it is why the unit is *not* re-languaged when the
/// content language changes: translating it would break the weight logic.
///
/// Anything unrecognised falls through unchanged, which is what a
/// user-supplied unit should do.
String exerciseUnitLabel(String? unit, AppLocalizations l10n) => switch (unit) {
      'kg' => l10n.kg,
      'lb' => l10n.unitLb,
      'bodyweight' => l10n.bodyweight,
      'band' => l10n.unitBand,
      'min' || 'minutes' => l10n.minutesShort,
      _ => unit ?? l10n.kg,
    };
