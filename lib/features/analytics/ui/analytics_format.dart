import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/language_service.dart';
import '../domain/analytics_input.dart';
import '../domain/analytics_range.dart';
import '../domain/insights.dart';

/// Formatting shared by every analytics card.
///
/// Kept in one place so the seven cards agree on how a number looks. Charts
/// print at most 4 y labels and 5 x labels regardless of range, so these have
/// to stay short -- "2.1k" not "2,140 kcal".
///
/// Numbers only. Every sentence the screen speaks lives in the ARB files and
/// is assembled below, which is what makes translating this screen a change to
/// two `.arb` files rather than a hunt through seven widgets.
class AnalyticsFormat {
  const AnalyticsFormat._();

  /// Short axis label for a bucket start, sized to the bucket.
  static String axisDate(DateTime t, AnalyticsBucket bucket) {
    return switch (bucket) {
      AnalyticsBucket.day => DateFormat('d/M').format(t),
      AnalyticsBucket.week => DateFormat('d/M').format(t),
      AnalyticsBucket.month => DateFormat('MMM').format(t),
    };
  }

  /// Full date for the scrub readout, where there is room for it.
  static String scrubDate(
      DateTime t, AnalyticsBucket bucket, AppLocalizations l10n) {
    return switch (bucket) {
      AnalyticsBucket.day => DateFormat('EEE d MMM').format(t),
      AnalyticsBucket.week =>
        l10n.analyticsWeekOf(DateFormat('d MMM').format(t)),
      AnalyticsBucket.month => DateFormat('MMMM yyyy').format(t),
    };
  }

  /// A plain number: 2340 -> "2340".
  ///
  /// Deliberately *not* abbreviated. This used to render "2.3k", which is a
  /// worse label on two counts: the reader has to expand it to know what they
  /// lifted, and the decimal point is ambiguous in a locale that groups
  /// numbers differently. Four or five digits fit the axis at 11pt.
  ///
  /// Only values under 10 keep a decimal, where the fraction is the
  /// information -- 7.5 hours of sleep is not 8.
  static String compact(double value) {
    if (value.abs() >= 10) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  static String kcal(double? value) =>
      value == null ? '--' : '${value.round()}';

  /// Unit-suffixed values.
  ///
  /// These take the localisations because the suffix is chrome: 'g'/'kg'/'h'
  /// read as English inside a Hebrew chart, and there is nothing about the
  /// number that decides them. The value itself stays Western digits, which is
  /// what Hebrew uses.
  static String grams(double? value, AppLocalizations l10n) =>
      value == null ? '--' : '${value.round()}${l10n.grams}';

  static String kg(double? value, AppLocalizations l10n) =>
      value == null ? '--' : '${value.toStringAsFixed(1)} ${l10n.kg}';

  static String hours(double? value, AppLocalizations l10n) {
    if (value == null) return '--';
    final whole = value.floor();
    final minutes = ((value - whole) * 60).round();
    // Spaced: "0 שע׳ 5 דק׳" rather than "0שע׳ 5דק׳". Two number-unit pairs
    // run together are hard to parse in either script, and worse in RTL where
    // the digits reorder around the letters.
    return minutes == 0
        ? '$whole ${l10n.hoursShort}'
        : '$whole ${l10n.hoursShort} $minutes ${l10n.minutesShortM}';
  }

  static String percent(double fraction) => '${(fraction * 100).round()}%';

  /// The exercise's name, or a dash when the chart has no exercise for the id.
  ///
  /// No language argument: the row carries one name, written when the library
  /// was seeded, so there is nothing to choose between here.
  static String exerciseName(ExerciseRef? ref) => ref?.name ?? '--';

  /// Muscle name in the active language.
  ///
  /// Untagged exercises are grouped under a translated "Other" rather than the
  /// raw sentinel, which would otherwise surface the string `other` verbatim
  /// in a Hebrew UI.
  static String muscleName(String muscle, AppLocalizations l10n) {
    if (muscle == 'other') return l10n.analyticsOtherMuscle;
    // Already in the content language -- it is the row's own stored
    // `primaryMuscle`. Capitalisation is a no-op in Hebrew.
    return muscle[0].toUpperCase() + muscle.substring(1);
  }
}

/// Turns an [Insight] into the sentence shown on the card.
///
/// The rules produce an [InsightKind] and a map of numbers, never a sentence,
/// so this switch is the single place wording lives -- and translating all
/// eight rules is translating eight ARB keys, with no rule touched.
String insightText(
  Insight insight,
  Map<String, ExerciseRef> exercises,
  AppLanguage language,
  AppLocalizations l10n,
) {
  final subject = insight.subjectId == null
      ? ''
      : AnalyticsFormat.exerciseName(exercises[insight.subjectId]);
  final v = insight.values;

  return switch (insight.kind) {
    InsightKind.plateau => l10n.insightPlateau(
        subject,
        AnalyticsFormat.kg(v['weight'], l10n),
        '${v['sessions']?.round()}',
      ),
    InsightKind.personalBest => l10n.insightPersonalBest(
        subject,
        AnalyticsFormat.kg(v['e1rm'], l10n),
      ),
    InsightKind.proteinShortfall => l10n.insightProteinShortfall(
        AnalyticsFormat.grams(v['actual'], l10n),
        AnalyticsFormat.grams(v['goal'], l10n),
      ),
    InsightKind.calorieDrift => (v['direction'] ?? 0) >= 0
        ? l10n.insightCalorieDriftHigh(
            AnalyticsFormat.kcal(v['actual']),
            AnalyticsFormat.kcal(v['goal']),
          )
        : l10n.insightCalorieDriftLow(
            AnalyticsFormat.kcal(v['actual']),
            AnalyticsFormat.kcal(v['goal']),
          ),
    InsightKind.volumeDrop =>
      l10n.insightVolumeDrop(AnalyticsFormat.percent(v['drop'] ?? 0)),
    InsightKind.sleepDebt => l10n.insightSleepDebt(
        '${v['nights']?.round()}',
        AnalyticsFormat.hours(v['goal'], l10n),
      ),
    InsightKind.consistencyWin =>
      l10n.insightConsistencyWin('${v['days']?.round()}'),
    InsightKind.neglectedMuscle => l10n.insightNeglectedMuscle(
        '${v['sets']?.round()}',
        AnalyticsFormat.muscleName(insight.subjectId ?? 'other', l10n),
      ),
  };
}

IconData insightIcon(InsightKind kind) => switch (kind) {
      InsightKind.plateau => Icons.trending_flat,
      InsightKind.personalBest => Icons.emoji_events_outlined,
      InsightKind.proteinShortfall => Icons.egg_outlined,
      InsightKind.calorieDrift => Icons.local_fire_department_outlined,
      InsightKind.volumeDrop => Icons.trending_down,
      InsightKind.sleepDebt => Icons.bedtime_outlined,
      InsightKind.consistencyWin => Icons.local_fire_department,
      InsightKind.neglectedMuscle => Icons.accessibility_new,
    };
