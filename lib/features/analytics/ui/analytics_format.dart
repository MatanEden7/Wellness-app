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

  /// Compact number: 2140 -> "2.1k". Keeps the axis readable at 11pt.
  static String compact(double value) {
    if (value.abs() >= 10000) return '${(value / 1000).toStringAsFixed(0)}k';
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    if (value.abs() >= 100) return value.toStringAsFixed(0);
    return value.toStringAsFixed(value.abs() < 10 ? 1 : 0);
  }

  static String kcal(double? value) =>
      value == null ? '--' : '${value.round()}';

  static String grams(double? value) =>
      value == null ? '--' : '${value.round()}g';

  static String kg(double? value) =>
      value == null ? '--' : '${value.toStringAsFixed(1)} kg';

  static String hours(double? value) {
    if (value == null) return '--';
    final whole = value.floor();
    final minutes = ((value - whole) * 60).round();
    return minutes == 0 ? '${whole}h' : '${whole}h ${minutes}m';
  }

  static String percent(double fraction) => '${(fraction * 100).round()}%';

  /// Exercise name in the active language, falling back to English.
  static String exerciseName(ExerciseRef? ref, AppLanguage language) {
    if (ref == null) return '--';
    final he = ref.nameHe;
    return language == AppLanguage.hebrew && he != null && he.trim().isNotEmpty
        ? he
        : ref.name;
  }

  /// Muscle name in the active language.
  ///
  /// Untagged exercises are grouped under a translated "Other" rather than the
  /// raw sentinel, which would otherwise surface the string `other` verbatim
  /// in a Hebrew UI.
  static String muscleName(
    String muscle,
    AppLocalizations l10n, {
    ExerciseRef? sample,
    AppLanguage language = AppLanguage.english,
  }) {
    if (muscle == 'other') return l10n.analyticsOtherMuscle;

    final he = sample?.primaryMuscleHe;
    if (language == AppLanguage.hebrew && he != null && he.trim().isNotEmpty) {
      return he;
    }
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
      : AnalyticsFormat.exerciseName(exercises[insight.subjectId], language);
  final v = insight.values;

  return switch (insight.kind) {
    InsightKind.plateau => l10n.insightPlateau(
        subject,
        AnalyticsFormat.kg(v['weight']),
        '${v['sessions']?.round()}',
      ),
    InsightKind.personalBest => l10n.insightPersonalBest(
        subject,
        AnalyticsFormat.kg(v['e1rm']),
      ),
    InsightKind.proteinShortfall => l10n.insightProteinShortfall(
        AnalyticsFormat.grams(v['actual']),
        AnalyticsFormat.grams(v['goal']),
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
        AnalyticsFormat.hours(v['goal']),
      ),
    InsightKind.consistencyWin =>
      l10n.insightConsistencyWin('${v['days']?.round()}'),
    InsightKind.neglectedMuscle => l10n.insightNeglectedMuscle(
        '${v['sets']?.round()}',
        AnalyticsFormat.muscleName(insight.subjectId ?? 'other', l10n,
            language: language),
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
