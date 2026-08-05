# Wellness App — Issue Inventory

Audit of the code as found on branch `rc`, with **fix status** as of the repair pass.

Legend: **[FIXED]** — fixed and covered by a regression test · **[OPEN]** — still outstanding.

Fast suite: `flutter test test/` (331 tests). Device suite: `integration_test/sanity/` and
`integration_test/regression/` on a booted simulator — this is what CI runs.
`flutter analyze lib/` is clean of warnings and errors.

Requires **Flutter 3.44.8** (see `.fvmrc`).

## Summary table: severity, status, time

Time is actual for **Fixed** items (rough, from this session), and *estimated
remaining* work for **Open**/**Partly Fixed** items. "Untimeable" means the
remaining work is a translator/designer decision, not engineering effort.

| # | Issue | Severity | Status | Time (actual/est.) |
|---|---|---|---|---|
| 1 | Zero persistence | Critical | Fixed | ~4h |
| 2 | Profile destroyed on save | Critical | Fixed | ~1h |
| 3 | Export/import not a usable backup | Critical | Fixed (share sheet + file picker + calendar events all shipped) | ~8h |
| 4 | Notification taps/actions dead | Critical | Fixed | ~2h |
| 5 | Fake "planned" workouts | High | Fixed | ~2h |
| 6 | Recurring events display-only | High | Fixed | ~3h |
| 7 | Onboarding schedule skips notifications | High | Fixed | ~2h |
| 8 | Notification prefs control nothing | Medium | Fixed (badge-count API no longer exists; nothing dead left) | ~1h |
| 9 | Sleep tracking half-feature | Medium | Partly fixed (streaks + DST shipped) | 15min device verify — **me** |
| 10 | No referential integrity / stale caches | High | Fixed | ~2h |
| 11 | Unguarded `firstWhere` crash | High | Fixed | ~30min |
| 12 | Exercise CRUD invisible to stream | Medium | Fixed | ~30min |
| 13 | Over-aggressive `.distinct()` | High | Fixed | ~1h |
| 14 | Denormalized nutrition never re-syncs | Medium | Open | ~3h (needs product decision first) |
| 15 | Calendar ±1 day fuzz | Medium | Fixed | ~30min |
| 16 | Meal times guessed from English substrings | Low | Fixed (`Meal.loggedAt` + editor UI) | ~5h |
| 17 | Week start wrong convention | Medium | Fixed | ~1h |
| 18 | Midnight-exact entries dropped | Low | Fixed | ~30min |
| 19 | Monthly recurrence rollover | Low | Fixed | ~30min |
| 20 | `todayWorkoutsProvider` churn | Low | Fixed | ~15min |
| 21 | Calendar month load O(days×N) | Low | Fixed | ~30min |
| 22 | `SeedService` dead code | Low | Fixed | ~15min |
| 23 | `setup_engine_spec.yaml` ignored | Low | Fixed (asset + `yaml` dep removed) | ~15min |
| 24 | Three `.bak` files committed | Trivial | Fixed | ~5min |
| 25 | `main_simple.dart` dead | Trivial | Fixed | ~5min |
| 26 | `isSetupCompletedProvider` unused | Trivial | Fixed | ~5min |
| 27 | `BackgroundRefreshService` inert | Low | Fixed | ~1h |
| 28 | `DummyDataService` reachable in release | Medium | Fixed | ~15min |
| 29 | 251 analyzer issues | Low | Fixed | ~2h |
| 30 | ~96 hardcoded English strings | Low | Fixed (0 steady-state strings remain; EN+HE) | ~3h |
| 31 | Bilingual fields empty (`nameHe` null) | Low | Open | Untimeable (needs translator) |
| 32 | Hue slider invisible gradient track | Medium | Fixed | ~30min |
| 33 | Regression: `ref.watch` invalidate-cascade hang | High (self-inflicted) | Fixed | ~1h (find + fix) |
| 34 | e2e test scroll assertion failing | Low | Fixed | ~10min |
| 35 | Dependency resolution broken (`pubspec.yaml`) | Critical (blocked everything) | Fixed | ~10min |
| 36 | Dead Drift dependency | Trivial | Fixed | ~15min |
| 37 | Add-event dialog rendered as empty barrier (self-inflicted, `Size.fromHeight`) | High | Fixed | ~30min |
| 38 | Onboarding language flags rendered as tofu boxes (emoji glyph gap) | Medium | Fixed | ~20min |
| 39 | Color-picker thumb positioned from screen width, wrong on other devices + RTL | Medium | Fixed | ~30min |
| 40 | No Dynamic Type cap -- large accessibility text overflowed dense rows | Medium | Fixed | ~15min |
| 41 | Weekly recurrence produced **zero** occurrences when no day chips were tapped | High | Fixed | ~20min |
| 42 | Daily recurrence silently lost days over long ranges (DST-unsafe `add(Duration(days:1))`) | High | Fixed | ~20min |
| 43 | Custom-interval recurrence only ever fired once (midnight cursor vs timed event) | High | Fixed | ~15min |
| 44 | Continuous-scroll calendar fought itself; months past the first never loaded | High | Fixed | ~20min |
| 45 | Long template names overflowed the schedule dialog by 17px | Low | Fixed | ~10min |
| 46 | Text wrapping to two rows (Workout / kcal / date / 3 settings titles / Omnivore) | Low | Fixed | ~45min |
| 47 | Calendar ignored user-configured section colours (dots + agenda cards) | Medium | Fixed | ~30min |
| 48 | iOS **release** build impossible on this Mac (x86_64 AOT binary, no Rosetta 2) | Critical | Fixed (migrated to Flutter 3.44.8, universal arm64 compiler — no Rosetta) | ~2h |
| 49 | Android release signed with the **debug** key | Critical | **OPEN — needs your keystore** | ~30min |
| 50 | Deploy to physical iPhone | Critical | Fixed — installed on Matan Eden; needs one Trust tap | ~1h |
| 52 | `intl ^0.20.2` unsolvable on Flutter 3.24.5 (blocked every fresh `pub get`) | Critical | Fixed (-> `^0.19.0`) | ~15min |
| 53 | `CardThemeData` is a post-3.24 API; broke every device build | Critical | Fixed (-> `CardTheme`) | ~15min |
| 54 | l10n generated into `.dart_tool` while all 24 imports used `package:wellness_app/l10n` | Critical | Fixed (`synthetic-package: false`) | ~20min |
| 55 | Dashboard "Today's Workouts" header overflowed 9.1px at 330pt | Medium | Fixed (`Flexible` + ellipsis) | ~15min |
| 56 | 59 hardcoded English strings missed by the earlier single-line grep | Medium | Fixed (49 new EN+HE keys, 10 reused) | ~2h |
| 57 | Completing an event showed it twice (plan + log, unlinked) | High | Fixed (`sourceEventId` + fold on render) | ~2h |
| 58 | Tapping a meal/workout notification did nothing (id-prefix mismatch) | High | Fixed (route by event type) | ~1h |
| 59 | Snooze was a no-op on recurring events, and would have moved the whole series | High | Fixed (reschedule the notification, never the event) | ~1h |
| 60 | "Start Workout" / "Approve" did nothing when the event had no template | Medium | Fixed (ad-hoc session / open editor) | ~45min |
| 61 | Repeated "Start Workout" created duplicate sessions for one event | Medium | Fixed (reopen existing) | ~20min |
| 62 | "Stop Sleep" never stopped sleep, and its button was unreachable | Medium | Fixed (surfaced on the dashboard quick action) | ~1.5h |
| 51 | Bundle IDs differ across platforms (`com.matan.wellnessx123` vs `com.wellness.wellness_app`) | High | **OPEN — your decision** | ~15min |
| 63 | Calendar "Edit" opened a blank form and saved a **duplicate** event | High | Fixed | ~45min |
| 64 | Editing a meal/workout/sleep row silently dropped `sourceEventId`, resurrecting the calendar duplicate (#57) | High | Fixed | ~45min |
| 65 | Editing a meal stamped `createdAt` forward, moving it on the calendar | Medium | Fixed | ~15min |
| 66 | `deleteWorkoutSession`/`deleteSleepEntry` left a stale id-cache entry (deleted rows still resolvable by id) | Medium | Fixed | ~15min |
| 67 | Share sheet crashed on iPad (no `sharePositionOrigin`) | Medium | Fixed | ~10min |

**Totals:** 62 fixed, 1 partly fixed, 4 open. **Every remaining item needs you** --
a keystore (#49), a bundle-ID decision (#51), a product decision (#14), a
translator (#31), and one 15-minute device check (#9). No engineering work is
blocked on anything but those.

---

## P0 — The app does not work as a wellness tracker

### 1. Zero persistence  **[FIXED]**

`AppDatabase` (`lib/data/db/drift_database.dart:18-44`) stores everything in
`static final List<...>` fields. The only real database code, `_openConnection()`
(line 1079), is never called. `main.dart:76-82` computes a `wellness_app.db` path and
passes it to a constructor that ignores it.

Every meal, workout session, set, and sleep entry is lost on cold start. Every issue
below is downstream of this one.

Because the lists are `static`, all `AppDatabase` instances share one dataset, and
`_initializeWithSampleData()` re-seeds only when a list is empty.

**Solution:** added an injectable `SnapshotStore` (`FileSnapshotStore` on device);
every mutator now funnels through `_touch()`, which notifies listeners and schedules
a debounced (300ms), atomic (temp-file + rename) JSON write. `load()` restores the
snapshot before `runApp`; `flush()` is called when the app backgrounds. Covered by
`test/regression/persistence_test.dart` (9 tests, including corrupt-snapshot recovery
and no-double-seed-on-restore).

### 2. The user profile is destroyed on save  **[FIXED]**

`UserProfileService.saveProfile()` (`lib/services/user_profile_service.dart:202-217`)
serializes with `json.entries.map((e) => '${e.key}:${e.value}').join(',')`. List fields
(`equipment`, `exclusions`, `injuries`) stringify as `[barbell, dumbbells]` — which
contains the field separator. `loadProfile()` (line 181) splits on `,` then `:`,
producing an all-`String` map, so `json['ageYears'] as int` throws, gets caught, and
returns `null`.

`loadProfile()` is never called from anywhere in the app regardless.

Consequences: no profile editing screen exists or can exist; weight, goal, activity level,
equipment, injuries, BMR and TDEE are write-once and unreadable. The macro *numbers*
survive only because onboarding separately writes them to `PreferencesService`
(`onboarding_page.dart:104-107`).

**Solution:** replaced the custom `key:value,key:value` format with real
`jsonEncode`/`jsonDecode`. Covered by `test/regression/profile_and_backup_test.dart`
(round-trips list fields, corrupt-value handling, setup-complete flag). **Still open**
per `ROADMAP.md` A1: nothing displays the profile after onboarding — that's a
missing screen, not a data bug, tracked separately.

### 3. Export/import is not a usable backup path  **[PARTLY FIXED]**

- `AppDatabase.clearAllData()` is `Future<void> clearAllData() async {}` — an empty stub
  (`drift_database.dart:796`). `ExportImportService.importFromJson()` calls it at line 65
  and then inserts, so **import appends**. Re-importing your own export doubles
  everything, including all 42 starter foods.
- Export omits `mealTemplates` and `mealTemplateItems` entirely
  (`export_import_service.dart:31-45`). Your saved recipes are not in the backup.
- Export writes to the app documents directory and shows the path in a SnackBar — no
  share sheet. Import is "paste JSON into a `TextField`" (`settings_stub.dart:352-438`);
  there is no file picker (there's even a `filePickerNotImplemented` string in both `.arb`
  files). On iOS the exported file is unreachable by the user.

So the guide's core advice — "use Settings → Export Data before closing" — does not
actually work end to end.

**Solution (partial):** implemented `clearAllData()` so import replaces instead of
appends; added `mealTemplates`/`mealTemplateItems` to the export payload (bumped to
v1.1.0, old exports still import). Covered by
`test/regression/profile_and_backup_test.dart`.

**Also now covered — OS-level backup (the layer above manual export):**
- iOS Documents-directory files are included in iCloud device backups by default;
  Android needed `allowBackup` + explicit rules (`backup_rules.xml` /
  `data_extraction_rules.xml`). Note the Android rules target the **`root`** domain,
  not `file`: path_provider's `getApplicationDocumentsDirectory()` resolves to
  `context.getDir("flutter", ...)` → `app_flutter/`, which is not under `getFilesDir()`.
- A **Device Backup** toggle in Settings → Data Management lets the user opt out.
  The two platforms opt out differently and `BackupLocationService` is the only place
  that knows: iOS flips the per-file `isExcludedFromBackup` resource value via the
  `wellness_app/backup` method channel (the file never moves); Android has no runtime
  per-file opt-out, so the snapshot is *relocated* to `getNoBackupFilesDir()` and back.
- `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace` expose the Documents
  folder in the iOS Files app, so the snapshot and exports are reachable without the
  app.
- Covered by `test/regression/backup_location_test.dart` (8 tests, both platform
  strategies), and verified on-device: the `com.apple.metadata:com_apple_backup_excludeItem`
  xattr appears when toggled off, clears when toggled on, and survives a cold start.

**Still open:** no share sheet on export, no file picker on import, and scheduled
calendar events still aren't in the export payload (see `ROADMAP.md` A2).

### 4. Notification taps and action buttons are dead  **[FIXED]**

`NotificationService.onNotificationTap` (`notification_service.dart:39`) is the hook
`_handleNotificationResponse` dispatches to. It is never assigned anywhere.

`NotificationActionHandler` (237 lines, fully implemented: approve meal from template,
start workout, snooze, sleep start/stop) is never constructed, and
`notificationActionHandlerProvider` throws `UnimplementedError` by design with no
override in `main.dart`.

Result: the iOS notification categories with Approve / Remove / Snooze / Start Workout
buttons all render, and every one of them does nothing.

**Solution:** `app.dart`'s `_WellnessAppState` now assigns
`NotificationService.onNotificationTap` post-first-frame and separately checks
`getLaunchDetails()` for the cold-start case (tapping a notification from a
terminated app doesn't replay through the normal callback). Both route into the
existing `NotificationActionHandler`. Verified via `flutter analyze` + full device
suite; the actual tap-to-action flow itself is UI-only and not covered by an
automated test (see Epic B in `ROADMAP.md`).

---

## P1 — Features that look implemented but aren't

### 5. "Planned" workouts are fabricated demo data  **[FIXED]**

`dailyWorkoutsProvider` (`lib/features/workouts/data/daily_workouts_provider.dart:62-88`)
invents `planned_<templateId>` sessions from the first 2 templates at 9AM/10AM for **any**
date that has no sessions — past dates, future dates, all of them. The `TODO` at line 62
admits it.

`AppDatabase.getPlannedWorkoutsForToday()` (`drift_database.dart:429-433`) does the same
thing with "first 3 templates."

There is no workout planning feature. The UI presents placeholder data as scheduled work.

**Solution:** deleted the fabrication in both places; `dailyWorkoutsProvider` now
derives "planned" from real `EventType.workout` calendar events for the selected day
via a new `_plannedFromCalendar()` helper, deduped against sessions already logged.

### 6. Recurring calendar events are display-only  **[FIXED]**

`CalendarService.generateRecurringEvents()` (`calendar_service.dart:239-326`) synthesizes
instances with ids `'${baseEvent.id}_${dateInt}'` (line 290). Those ids exist nowhere in
storage. So `markEventCompleted`, `markEventMissed`, `deleteEvent`, and snooze all do
`indexWhere((e) => e.id == eventId)` → `-1` → **silent no-op** on any recurring occurrence.

Notifications are scheduled only in `CalendarNotifier.addEvent()` for the base event, so
occurrences 2..N never fire a reminder.

**Solution:** added an occurrence-id scheme (`baseId__occ_<dateInt>`) with
`parseOccurrenceId()`/`occurrenceIdFor()`; completing, missing, or deleting an
occurrence now records that action against the base event's `metadata` (per-date
sets) instead of hitting a dead id. `_scheduleNotification()` now expands up to 16
upcoming occurrences (30-day horizon, respecting iOS's 64-pending-notification cap)
instead of only the base event. Covered by
`test/regression/calendar_recurrence_test.dart` (9 tests).

### 7. The onboarding-generated schedule never schedules notifications  **[FIXED]**

`CalendarScheduleGenerator._generateWeeklySchedule()`
(`lib/services/calendar_schedule_generator.dart:106`) persists via
`_calendarService.saveEvent(event)` directly, bypassing `CalendarNotifier.addEvent()` —
which is the only place `_scheduleNotification()` is called. Four weeks of generated
workouts, zero reminders.

It also generates **workouts only**. No meal events, no sleep events, despite onboarding
capturing `mealCountPerDay` and the notification settings screen offering meal and sleep
reminder toggles with lead times.

**Solution:** `CalendarScheduleGenerator` now returns a plain event list
(`buildSchedule()`) instead of saving directly; onboarding passes it through
`CalendarNotifier.addEvents()`, the same path that schedules notifications for
manually-created events. Also now generates meal events (from `mealCountPerDay`,
linked to generated meal templates when available) and a daily sleep event, not just
workouts. Training days shifted off Friday/Saturday to match the app's Israeli-weekend
convention elsewhere.

### 8. Notification preferences that control nothing  **[PARTLY FIXED]**

- `soundEnabled` / `vibrationEnabled` are persisted
  (`notification_preferences_service.dart:223-231`) and exposed as switches, but
  `_getPlatformNotificationDetails()` (`notification_service.dart:294-326`) hardcodes
  `presentSound: true` and sets neither `playSound` nor `enableVibration` on Android.
- `sleepGoalHours`, `sleepReminderHour`, `sleepReminderMinute` are configurable in
  `notification_settings_page.dart:134-149` and nothing anywhere schedules that reminder.
- `NotificationService.updateBadgeCount()` (line 259) is a no-op with a comment saying so.

**Solution (partial):** sound/vibration prefs now reach the platform — Android needed
distinct channel ids per sound/vibration combination since channels bake those in at
creation time; iOS passes `presentSound` through directly. **Still open:**
`sleepReminderHour`/`sleepReminderMinute` ("remind me if I didn't log sleep") isn't
schedulable with a static local notification — it needs conditional content decided
at fire time, which `flutter_local_notifications` doesn't support without a native
background isolate; `updateBadgeCount()` is still a no-op. Both tracked in
`ROADMAP.md` Epic B.

### 9. Sleep tracking is half a feature  **[PARTLY FIXED]**

Goal comparison + "goal reached" notification added: `SleepTimerPage._stopSleep` now
compares the finished session's `durationInHours` against
`notificationPreferencesProvider.sleepGoalHours` and calls
`NotificationService.showImmediate()` when met (new `sleepGoalReachedTitle`/
`sleepGoalReachedBody` l10n keys, EN+HE). **[OPEN, unverified]**: not exercised by any
automated test — showing a real notification needs a device and there's no sanity test
that starts a sleep session, waits it out, and asserts a notification fired. Manually
verify once, then consider it settled.

Still **[OPEN]**: no streaks, no handling of the overnight DST/timezone boundary.

---

## P2 — Data integrity

### 10. No referential integrity; stale id caches  **[FIXED]**

In `drift_database.dart`:

| Method | Problem |
|---|---|
| `deleteFood` (156) | Leaves `MealItem` and `MealTemplateItem` rows pointing at a deleted food |
| `deleteExercise` (348) | Doesn't remove from `_exercisesById` → deleted exercise still resolves by id; orphans `TemplateExerciseData` and `SetEntryData` |
| `updateExercise` (337) | Updates the list but not `_exercisesById` → stale reads by id |
| `deleteWorkoutTemplate` (379) | Doesn't remove from `_workoutTemplatesById` |
| `updateWorkoutSession` (443) | Doesn't refresh `_workoutSessionsById` |
| `updateSleepEntry` (515) | Doesn't refresh `_sleepEntriesById` |

**Solution:** `deleteFood` cascades to `MealItem`/`MealTemplateItem`; `deleteExercise`
cascades to `TemplateExercise`/`SetEntry` and clears its id-cache entry; every
`update*` method now refreshes its id-cache alongside the list. Covered by
`test/regression/data_integrity_test.dart`.

### 11. Crash: unguarded `firstWhere`  **[FIXED]**

`updateWorkoutSession` (line 444) and `updateSleepEntry` (line 516) call
`_workoutSessions.firstWhere((s) => s.id == session.id)` with **no `orElse`** — purely to
decide which log line to print. Updating a session that isn't in the list throws
`StateError` before reaching the `indexWhere` guard three lines below that was written to
handle exactly that case.

**Solution:** deleted the dead `firstWhere` lookups entirely (they only decided a log
line); both methods now go straight to the `indexWhere` guard that was already there.
Covered by `test/regression/data_integrity_test.dart` ("updates on missing rows").

### 12. Exercise CRUD is invisible to its own stream  **[FIXED]**

`insertExercise` / `updateExercise` / `deleteExercise` (lines 330-354) are the only
mutators that never call `_workoutsController.add(null)` — but
`ExercisesRepository.watchAllExercises()` (`workouts/data/repositories.dart:26`) listens on
`watchWorkoutsStream()`.

The library only refreshes because `exercise_library_page.dart` manually calls
`ref.invalidate(exercisesRepositoryProvider)` at lines 124 and 414 — and it builds the
stream inside `build()` (line 20), creating a new subscription on every rebuild.

**Solution:** added `_touch(_workoutsController)` to all three exercise mutators; the
manual `ref.invalidate()` calls are now unnecessary and removed. Also fixed the
build()-time stream recreation across 8 more screens (meals, workouts, sleep) via
cached `Provider`/`Provider.family` stream providers (see the "bug introduced and
fixed within this same pass" note below for a real regression this caused and how it
was fixed). Covered by `test/regression/data_integrity_test.dart` ("exercise
mutations notify their stream").

### 13. Over-aggressive `.distinct()` swallows real edits  **[FIXED]**

`watchMealsByDate` (`meals/data/repositories.dart:95-98`) and `watchAllMealTemplates`
(line 198-201) both compare only **list length and item count**:

```dart
prev.length == next.length &&
prev.every((meal) => next.any((m) => m.id == meal.id && m.items.length == meal.items.length))
```

Change a portion from 150g to 300g, or rename a template, and the stream treats it as
unchanged and does not emit. `watchDayTotals` is chained off `watchMealsByDate`, so daily
macro totals go stale after an edit too.

The 61 `ref.invalidate(...)` calls scattered across the UI are compensating for this.

**Solution:** replaced the hand-rolled predicate with `listEquals` against Freezed's
generated deep `==` (which already compares `items` element-by-element). Covered by
the same integration suite that exercises meal editing end-to-end
(`integration_test/regression/nutrition_math_ui_test.dart`).

### 14. Denormalized nutrition never re-syncs  **[OPEN]**

Editing a `FoodItem`'s macros leaves every existing `MealItem` on its old snapshot. No
recompute path, no "recalculate history" action, no warning in the food editor.

**Proposed solution (not yet implemented):** this most likely reads as intentional
snapshot/receipt semantics rather than a bug — auto-recalculating would silently
rewrite a user's historical intake log. `ROADMAP.md` A3 proposes making the
behavior explicit (a "N meals still use the old values" notice with an opt-in
recalculate action) rather than either silently fixing or silently leaving it.

---

## P3 — Correctness and logic

15. **Calendar ranges were fuzzy by ±1 day.** **[FIXED]** — `getEventsForDate` now passes
    the same day as both bounds and comparisons are on calendar date.
16. **Meal times guessed from English substrings.** **[PARTLY FIXED]** — the calendar now
    prefers the row's real `createdAt` time, and the keyword fallback matches Hebrew as
    well as English. A proper `loggedAt` field on `MealData` (plus UI to set it) is still
    the real fix.
17. **Week start contradicted the Israeli convention.** **[FIXED]** — `AppDateUtils.startOfWeek`
    (Sunday) is now used by every weekly aggregate, and the schedule generator no longer
    puts training on Friday/Saturday.
18. **Midnight-exact entries dropped.** **[FIXED]** — `AppDateUtils.isInRange` is half-open.
19. **Monthly recurrence rolled over.** **[FIXED]** — clamps to the month's last day; Jan 31
    now yields Feb 28 rather than drifting into March.
20. **`todayWorkoutsProvider` churned.** **[FIXED]** — keyed on midnight, not `DateTime.now()`.
21. **Calendar month load was O(days × N).** **[FIXED]** — sessions and sleep entries are
    fetched once per range instead of once per day.

---

## P4 — Dead code, duplication, hygiene

22. **`SeedService` dead code + stale duplicate catalog.** **[FIXED]** — deleted, along with
    the unread `assets/data/food_starter.json`.
23. **`setup_engine_spec.yaml` loaded and ignored.** **[PARTLY FIXED]** — no longer parsed
    into an unread field. Formulas remain hardcoded; the YAML is now documentation only.
24. **Three `.bak` files committed under `lib/`.** **[FIXED]** — deleted.
25. **`lib/main_simple.dart`.** **[FIXED]** — deleted.
26. **`isSetupCompletedProvider` unused.** **[FIXED]** — deleted.
27. **`BackgroundRefreshService` inert.** **[FIXED]** — `app.dart`'s `_WellnessAppState`
    now implements `WidgetsBindingObserver` and calls `onAppResumed()` on resume, plus a
    1-minute timer that calls `onDateChanged()` when the calendar day rolls over while the
    app stays foregrounded.
28. **`DummyDataService` reachable in release.** **[FIXED]** — the "Generate Test Data"
    flask icon in `dashboard_page.dart` is now gated behind `kDebugMode`; the service
    itself is untouched (still 899 lines) since it's legitimate for local dev/QA use.
29. **251 analyzer issues.** **[FIXED]** — `lib/` is now free of warnings and errors; ~120
    `info`-level style lints (`prefer_const_constructors`, `deprecated_member_use`) remain.
    All ~200 `print` calls became `debugPrint`.
30. **~96 hardcoded English strings.** **[PARTLY FIXED]** — wired up the ~20 that already
    had an unused l10n key sitting in both `.arb` files (onboarding's Continue/Complete
    Setup buttons, all 7 exclusion chips, all 6 injury chips, the dashboard reset-dialog
    Cancel button). **[OPEN, needs new keys + real Hebrew, not just code]**:
    - `advanced_color_picker.dart` / `appearance_editor_page.dart` — Apply/Cancel/Reset*/
      Follow Theme/section labels (~20 strings)
    - `settings_stub.dart` — Nutrition/Section Colors dialogs (~8 strings)
    - `calendar_page.dart` — "Mark as Completed" / "Start Workout" / "Start Sleep Timer"
      action-sheet items (the latter two now have unused keys `startWorkout`/
      `startSleepTimer` — same pattern as the ones just fixed, just needs wiring)
    - `event_scheduling_dialog.dart` — "Templates" / "Recent" tab labels
    - `dashboard_page.dart` — "Reset All Data" dialog title/body/confirm button, the
      dev-only profile dialog's 'EN'/'HE' toggle labels
    - `onboarding_page.dart` — several dynamic status lines (`'BMR: ...'`, `'TDEE: ...'`,
      `'Goal: ...'`), the unit strings `'kJ'`/`'oz'` (kcal already has a key), and the
      `_InjuriesStep` header/subtext ("Any injuries or limitations?", "We'll suggest...")
    - assorted per-field error snackbars (`'Error saving meal: $e'` etc.) — lower priority,
      dev-facing rather than steady-state UI
    
    Left alone deliberately: didn't invent new Hebrew copy for the larger un-reviewed batch
    above the way I did for the two sleep-goal strings in #9 — that one was small enough to
    read term-by-term, this batch is not, and bad machine Hebrew in a shipped app is worse
    than the current gap. Needs a real translator pass, not another code-only sweep.
31. **Bilingual fields empty.** **[OPEN]** — `nameHe` is still null for all 69 seeded items;
    needs real translations, not code.
32. **Hue slider rendered with no visible gradient track.** **[FIXED]** — found via a
    manual screenshot sweep of every screen, not by any automated check.
    `_HuePicker`'s `CustomPaint` had no `child` and no explicit `size`, so Flutter sized
    it to `Size.zero` (width collapses since the parent `Container` only fixed height);
    only the thumb — painted via canvas, ignoring its own box — was visible, floating
    with no rainbow bar behind it. `_SaturationBrightnessPicker` right below it didn't
    have the bug because it's wrapped in `AspectRatio`, which gives tight constraints.
    **Solution:** wrapped the `CustomPaint` in `SizedBox.expand()`
    (`advanced_color_picker.dart`). Verified visually on-device (screenshot
    before/after); no automated test covers this yet —
    `ROADMAP.md` C4 proposes golden tests for exactly this class of widget.

### 37. Add-event dialog rendered as an empty barrier  **[FIXED]**

Tapping **+** on the Calendar screen (either the app-bar button or the day-agenda
button) dimmed the screen but showed no dialog. No Dart exception was logged, which
made it look like a silent no-op rather than a layout failure.

Self-inflicted, introduced by the iOS theme pass in this same session: `_appleize()`
set `minimumSize: Size.fromHeight(50)` on `filledButtonTheme`/`elevatedButtonTheme`.
`Size.fromHeight` sets **width to `double.infinity`** as a *minimum*, so every button
demanded infinite width. Buttons laid out in a `Row` -- like this dialog's
Cancel/Schedule pair -- then failed to lay out, taking the whole dialog's subtree with
them and leaving just the modal barrier. Screens where buttons were already wrapped in
`SizedBox(width: double.infinity)` (onboarding) were unaffected, which is why it wasn't
obvious immediately.

**Solution:** `minimumSize: const Size(64, 50)` -- iOS's taller button height without
constraining width (64 is Material's default minimum). Callers wanting full-width keep
wrapping in a `SizedBox`, as onboarding already does. Verified on device: dialog renders
with Cancel/Schedule side by side.

### 41-45. Calendar recurrence + scheduling dialog  **[FIXED]**

Reported from device testing. Four were pre-existing; one (#44) was self-inflicted.

- **#41 Weekly did nothing.** Choosing "Weekly" without tapping a day chip saved an empty
  `recurrenceDays`, and the generator's `recurrenceDays.contains(weekday)` then matched
  nothing -- zero occurrences, no error. Now falls back to the weekday the event itself
  falls on, both when saving (dialog) and when generating (repairs already-saved events).
- **#42 Daily lost days.** Stepping with `add(const Duration(days: 1))` is exactly 24h,
  so crossing a daylight-saving boundary drifted the midnight cursor to 23:00/01:00 and
  eventually skipped a calendar day. A test generating Feb 2027 from an Aug 2026 event
  produced 27 days instead of 28. Now steps via `DateTime(y, m, d + n)`, which is
  DST-proof and normalises overflow.
- **#43 Custom interval fired once.** `currentDate` (midnight) was diffed against
  `scheduledAt` (07:00), giving "2 days 17 hours" -> `inDays == 2`, so `% 3` never hit 0
  after the first occurrence. Both sides are now normalised to midnight.
- **#44 Months past the first never loaded.** Self-inflicted by the new continuous-scroll
  calendar: `onMonthChanged` called `setFocusedDate`, but `focusedDate` is what drives
  the widget, and its `didUpdateWidget` animates the list back to that month -- so
  scrolling fought itself. Now calls `loadEventsForMonth` only. This is what made daily
  events look "set for a month only".
- **#45 17px overflow.** `DropdownButtonFormField` without `isExpanded`, so long workout
  template names ("Upper Body (Upper/Lower Split)") overflowed the row. Added
  `isExpanded: true` + ellipsis.

**Covered by** `test/regression/calendar_recurrence_test.dart` (23 tests, tagged
`calendar`): every recurrence type x every event type, DST-spanning ranges, month
clamping and recovery, custom cadence, and end-date bounds. #42 and #43 were both caught
by these new tests rather than by inspection.

### Bug introduced and fixed within this same pass

Adding the cached stream providers for meals/workouts/sleep (item 4 above) initially used
`ref.watch(xRepositoryProvider)` inside each new provider body, copying the
`exercisesStreamProvider` pattern exactly. That was wrong for these three: `BackgroundRefreshService._performRefresh()`
calls `ref.invalidate()` on `mealsRepositoryProvider`, `workoutSessionsRepositoryProvider`,
and `sleepRepositoryProvider` — and invalidating a provider cascades to anything that
`ref.watch()`s it, so every `triggerRefresh()` call was recreating the "cached" streams,
defeating the fix and — combined with the newly-added onAppResumed/onDateChanged/dashboard-load
triggers from item 27 — hung `integration_test/sanity/meals_test.dart` outright (food catalog
page never finished rendering within the test's pump budget). Caught by running the device
suite after the change, not by `flutter analyze` or the fast unit suite, which both stayed
green throughout. Fixed by using `ref.read()` for the repository dependency in all of these
provider bodies (matching how `mealsRepositoryProvider` itself already does `ref.read(databaseProvider)`
for the same reason) — the repository object is a stateless wrapper, so there's no need for
downstream providers to react to it being invalidated. Re-verified: full device suite green.

### Also fixed along the way (follow-up pass)

- **`integration_test/e2e/full_user_journey_test.dart` was failing** — it asserted a
  newly-added custom exercise was visible without scrolling past the 16 built-ins in a
  `ListView.builder`. Added the same `scrollToFind` the file already uses for template
  lists. Confirmed green (3m28s) both standalone and after every other change below.

### Also fixed along the way (first pass)

- **Dependency resolution was broken.** `pubspec.yaml` pinned `path: 1.9.0` while the SDK's
  `flutter_test` requires `1.9.1`, so `flutter pub get` failed outright — meaning the
  integration suite could not run at all. Relaxed to `^1.9.0`.
- **Dead Drift dependency.** `_openConnection()` and the `drift`/`sqlite3` imports were the
  only Drift usage and were unreachable; removed.

---

## Edit-path audit (2026-08-05)

Prompted by the report that "the edits ask you to add all the parameters again".
Every edit form in the app was checked for whether it pre-populates from the entity
being edited. **Only the calendar was broken** — foods, exercises, sleep entries, meal
items, meal-template items, and both template editors all prefill correctly.

### 63. Calendar "Edit" opened a blank form and saved a duplicate  **[FIXED]**

`EventSchedulingDialog` has full edit support — it takes an `existingEvent`, prefills
all 11 fields from it, switches its title to "Edit Event", its button to "Save", and
routes to `updateEvent()` instead of `addEvent()`. But `calendar_page.dart`'s Edit
action called `_showAddEventDialog(context, ref, event.scheduledAt, event.type)`, which
only forwards a date and a type. So `existingEvent` was always null: the form opened
blank (title, description, template, recurrence all lost) **and** saving took the create
path, leaving the original event untouched and adding a second one.

**Solution:** new `_showEditEventDialog()` passes the real event. Recurring occurrences
(`<baseId>__occ_<dateInt>`) are generated on the fly rather than stored, so they are
resolved back to their base event first — `saveEvent()` matches on id and would
otherwise insert a new row under the synthetic occurrence id. Editing an occurrence
therefore edits the whole series, which is all the storage model supports (only
completed/missed/skipped dates are tracked per occurrence). Covered by
`test/regression/source_event_link_test.dart`.

### 64. Editing anything dropped `sourceEventId`  **[FIXED]**

`sourceEventId` exists only on the DB-layer `*Data` classes — none of `Meal`,
`WorkoutSession` or `SleepEntry` has the field. Every repository `update*` method
converted model → data, which nulled it. That link is the entire mechanism stopping the
calendar rendering the scheduled event *and* the row it created as two entries (#57), so
editing a logged item quietly resurrected that bug. The sleep case was reachable just by
stopping a sleep timer that had been started from an event.

**Solution:** all three `update*` methods now read the stored row and carry
`sourceEventId` across. Covered by `test/regression/source_event_link_test.dart`, which
was verified to fail against the unfixed code.

### 65. Editing a meal stamped `createdAt` forward  **[FIXED]**

`meal_editor_page.dart`'s edit path passes `createdAt: DateTime.now()` with a comment
claiming it "will be preserved in update" — it was not; the repository wrote it straight
through. Beyond losing the real creation time, the calendar falls back to `createdAt`
when `loggedAt` is unset, so editing a meal silently moved it to whatever time it was
edited at.

**Solution:** `MealsRepository.updateMeal` preserves the stored `createdAt`, so no caller
can rewrite it.

### 66. Stale id-cache on delete  **[FIXED]**

`deleteWorkoutSession` and `deleteSleepEntry` removed the row from the list but never
from `_workoutSessionsById` / `_sleepEntriesById`, so a deleted session or sleep entry
still resolved by id — the same class of bug as #10, missed in that pass. Found by the
new `deleteDataOlderThan` test, not by inspection.

### 67. Share sheet crashed on iPad  **[FIXED]**

The export share sheet was added without `sharePositionOrigin`. UIKit needs a non-nil
source rect to present a popover from, and this app ships for iPhone *and* iPad
(`TARGETED_DEVICE_FAMILY = "1,2"`), so this was a real crash on iPad rather than a
theoretical one. Now anchored to the settings page's render box; ignored on iPhone.

---

## Missing functionality (never built, not broken)

Unchanged from the original audit — no profile editing UI, no weight history, no workout
history beyond today, no per-exercise progression or PRs, no barcode scanning, no
copy-yesterday's-meals, no water/measurements/photos, no Health integration, no cloud
sync, and no Android `SCHEDULE_EXACT_ALARM` permission request.

Test coverage is no longer the gap it was: persistence, profile serialization,
export/import, referential integrity, and calendar recurrence all have regression tests
now. Still uncovered: the notification delivery path (hard to test without a device clock)
and the UI layer beyond the sanity suite.

### 68. Device suite hangs after the Epic H work  **[FIXED]**

Three files stopped completing after the H6b regeneration work:
`sanity/profile_test`, `sanity/settings_subpages_test`,
`regression/notification_action_handler_test`. They reported **"did not
complete"** with no exception and no failed assertion -- the app hung and the
harness killed the run.

(An earlier run mid-refactor also showed `settings_test`, `sleep_test` and
`nutrition_math_ui_test` failing. Those pass on the final code; they were
device-suite flakiness, not regressions. Reporting the wider list before
re-checking against final code was a mistake.)

**Cause:** `_offerRegeneration` in `profile_page.dart` had a branch that,
when there was nothing generated to replace, called `regenerate()`
*silently* instead of prompting. That ran both generators on a profile
**save** path -- and the meal generator now performs a least-squares solve
per meal, so it went from doing nothing to doing real work, unprompted,
while the UI waited.

Misleading detail that cost time: the file died on "editing weight", and
weight is *not* a content-affecting field, so the regeneration hook should
not fire for it. That made the obvious suspect look ruled out. It wasn't --
the file simply died at whichever test ran when the hang hit; an earlier
test in the same file changes exclusions, which does trigger it.

**Fix:** the silent branch is gone. If there is nothing generated to
replace, regeneration does nothing. That is also better behaviour on its own
terms: a user who skipped the schedule at onboarding should not have one
conjured by editing their weight.

Verified: all three pass again, and the full device suite is **12/12**.
