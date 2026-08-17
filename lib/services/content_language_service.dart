import 'package:flutter/foundation.dart';

import '../core/app_language.dart';
import '../data/db/drift_database.dart';
import '../features/calendar/data/calendar_service.dart';
import 'content_regeneration_service.dart';
import 'user_profile_service.dart';

/// What a language switch actually changed, so the caller can say so.
class ContentLanguageChange {
  const ContentLanguageChange({
    required this.catalogRows,
    required this.templates,
    required this.events,
  });

  final int catalogRows;
  final int templates;
  final int events;

  bool get isEmpty => catalogRows == 0 && templates == 0 && events == 0;
}

/// Moves **all** stored content into a new language when the user changes it.
///
/// The app resolves content language once and stores the result -- a food row
/// holds one name, not a pair, and no widget re-picks at render time. That is
/// what stops a plan renaming itself under someone mid-week, and it is why
/// `nameHe`/`displayName()` are gone.
///
/// The cost of that design, on its own, is a Hebrew UI listing "Chicken
/// Breast" for anyone who onboarded in English. This service is the answer:
/// changing the language is an explicit instruction, so it re-runs the
/// resolution across everything that already exists instead of leaving the two
/// halves disagreeing. Content still never re-languages *itself*; it only ever
/// moves when the user asks.
///
/// What is deliberately **not** touched:
///
///   * foods, exercises and templates the user created or renamed -- those are
///     their words. `AppDatabase.relanguageCatalog` detects an edit rather
///     than guessing, and `ProfileFit.isReplaceable` keeps regeneration off
///     anything hand-built.
///   * logged history. Meals, sets and sleep reference catalog rows by id, and
///     ids never move, so nothing recorded is rewritten or orphaned.
class ContentLanguageService {
  ContentLanguageService(
    this._database,
    this._profileService,
    this._calendarService,
    this._calendar,
  );

  final AppDatabase _database;
  final UserProfileService _profileService;

  /// Reading events comes from the service; writing them goes through the
  /// notifier, which is the only path that also keeps the reminders in step.
  final CalendarService _calendarService;
  final CalendarNotifier _calendar;

  /// Re-languages the catalog, the generated templates, and the calendar
  /// titles that were copied from them.
  ///
  /// Ordered on purpose: the catalog first, because the generators pick from
  /// it and would otherwise write templates full of foods in the old language;
  /// the calendar last, because it copies template names and needs the new
  /// ones to exist.
  Future<ContentLanguageChange> switchTo(AppLanguage language) async {
    final rows = await _database.relanguageCatalog(language);

    var templates = 0;
    final profile = _profileService.loadProfile();
    if (profile != null) {
      // Regeneration replaces only `TemplateOrigin.generated`, so this rebuilds
      // the plan the app generated and leaves anything the user built alone.
      templates = await ContentRegenerationService(_database)
          .regenerate(profile, language);
      // Rebuilt templates carry fresh ids, so every event onboarding pinned to
      // the old ones now points at nothing -- silent until the user taps
      // "Start Workout" on a reminder and it does nothing at all.
      await _calendar.repinDanglingTemplates();
    }

    final events = await _retitleEvents(language);

    debugPrint('[LANG] Switched content to ${language.code}: $rows rows, '
        '$templates templates, $events event titles');
    return ContentLanguageChange(
      catalogRows: rows,
      templates: templates,
      events: events,
    );
  }

  /// Retitles stored calendar events.
  ///
  /// Event titles are *copies*, not references -- the calendar shows the title
  /// it was given, so a re-languaged template does not reach the calendar on
  /// its own. Two sources, matching where the titles came from:
  ///
  ///   * an event still pinned to a template takes that template's new name,
  ///     which keeps the calendar and the plan saying the same thing;
  ///   * an event the generator labelled itself (sleep, and the meal slots it
  ///     falls back to) is translated through [_ownLabels].
  ///
  /// A title that matches neither is left alone: the user typed it.
  Future<int> _retitleEvents(AppLanguage language) async {
    final meals = {
      for (final t in await _database.getAllMealTemplates()) t.id: t.name
    };
    final workouts = {
      for (final t in await _database.getAllWorkoutTemplates()) t.id: t.name
    };

    var changed = 0;
    for (final event in await _calendarService.getEvents()) {
      final pinned = meals[event.templateId] ?? workouts[event.templateId];
      final next = pinned ?? _ownLabels(language)[event.title];
      if (next == null || next == event.title) continue;

      await _calendar.updateEvent(event.copyWith(title: next));
      changed++;
    }
    return changed;
  }

  /// The labels `CalendarScheduleGenerator` writes itself, in both languages,
  /// keyed by every spelling an existing event might already hold.
  ///
  /// Kept here rather than shared with the generator because the generator
  /// only ever needs one direction ("what do I call this?") while a switch
  /// needs the reverse lookup as well ("was this ours to rename?").
  static Map<String, String> _ownLabels(AppLanguage language) {
    const pairs = {
      'Sleep': 'שינה',
      'Breakfast': 'ארוחת בוקר',
      'Lunch': 'ארוחת צהריים',
      'Dinner': 'ארוחת ערב',
      'Snack': 'חטיף',
    };
    return {
      for (final entry in pairs.entries)
        if (language == AppLanguage.hebrew) ...{
          entry.key: entry.value,
          entry.value: entry.value,
        } else ...{
          entry.value: entry.key,
          entry.key: entry.key,
        },
    };
  }
}
