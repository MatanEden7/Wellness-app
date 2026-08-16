# Wellness App — Issue Inventory

Audit of the code as found on branch `rc`, with **fix status** as of the repair pass.

Legend: **[FIXED]** — fixed and covered by a regression test · **[OPEN]** — still outstanding.

Fast suite: `flutter test test/` (606 tests). Device suite: `integration_test/sanity/` and
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
| 68 | Device suite hung after the Epic H work (silent regeneration on profile save) | High | Fixed | ~2h |
| 70 | Generated workouts were a placeholder: 3x10, no weight, no rest, identical for every goal | High | Fixed | ~6h |
| 71 | The user profile and all settings were in no backup at all | High | Fixed | ~2h |
| 69 | Notification audit: snooze/remove unreachable, rest timer killed all buttons, no sound, prefs never re-applied | Critical | Fixed | ~3h |
| 72 | Analytics screen is English-only | Medium | Fixed (EN+HE; Hebrew wording needs a translator pass — see #31) | ~2h |
| 73 | Analytics charts are invisible to VoiceOver | Medium | Fixed | ~1h |
| 74 | A workout scheduled in a scrolled-to month saved but never appeared | High | Fixed | ~1h |
| 75 | Scheduling a workout for *now* shows it twice (plan + unlinked session) | Medium | Fixed | ~1h |
| 76 | Every multi-placeholder ARB string passed its arguments in the wrong order | High | Fixed | ~30min |
| 77 | Add/edit food and exercise dialogs overflowed; their save button was off-screen and untappable | High | Fixed | ~45min |
| 78 | Daily nutrition targets incoherent: fat never targeted, flat kcal adjustment with no safety floor, protein off scale weight, macros not reconciled | High | Fixed | ~2h |
| 79 | Food catalog unvalidated, English-only, and structurally unable to reach existing installs | Medium | Fixed (fast-food values now verified against the Israeli menu) | ~3h |
| 80 | Generated meal plans undershot carbs by up to 37% and calories by 14%: serving caps pinned every starch, fat absorbed the gap | High | Fixed | ~1h |
| 81 | Catalog had no category axis and missing basics; macro audit was vacuous for per-ml foods | Medium | Fixed | ~3h |
| 82 | Rehab pools too small to fill a physio session; no bodyweight hamstring/shoulder/biceps work; dead getRehabExercises; exercises never reached existing installs | High | Fixed | ~3h |
| 83 | Fast-food macros were US figures on an Israeli menu | Medium | Fixed | ~1h |
| 84 | The whole Profile page renders English in Hebrew mode | Medium | **Open** — needs ~29 new Hebrew strings — **me** | ~2h |
| 85 | Meal editor titled itself "Add Food"/"Edit Food" | Low | Fixed | ~5min |
| 86 | Settings' "Workout Templates" row opened Workout Settings | Low | Fixed | ~5min |
| 87 | Meals and Workouts home screens rendered completely blank on device | Critical | Fixed | ~1h |
| 88 | Every CupertinoIcons glyph in the app rendered as a tofu box | High | Fixed | ~10min |
| 89 | Five horizontal overflows on settings/editor screens | Medium | Fixed | ~30min |
| 90 | Settings' "Global Timeframe" changes nothing on the dashboard | High | Fixed | ~1h |
| 91 | Settings' "Workout Metric" changes nothing on the dashboard | Medium | Fixed | ~1h |
| 92 | Liquid Glass never rendered: standalone bars stay in their transparent scroll-edge state | High | Fixed | ~1h |
| 93 | The last row of every screen sat under the native tab bar | High | Fixed | ~30min |
| 94 | The native tab bar never followed router navigation | Medium | Fixed | ~30min |
| 95 | Nav bar and tab bar floated over onboarding, and over pushed detail pages | High | Fixed | ~45min |
| 96 | Native tab labels were hardcoded English in a bilingual app | Medium | Fixed | ~30min |
| 97 | A hidden bar still reserved its inset, leaving a blank strip | Low | Fixed | ~15min |
| 98 | `PlatformChildPage`/`PlatformNavPage` ignored the app theme's background | Medium | Fixed | ~10min |
| 99 | Bridge calls fail asynchronously; the `try/catch` around them caught nothing | Medium | Fixed | ~20min |
| 100 | Deferred chrome sync leaked a listener per popped route, and pushed stale chrome | Low | Fixed | ~20min |
| 101 | Analytics screen is a red error page: one `GlobalKey` used twice in a child list | Critical | Fixed | ~1h |
| 102 | Onboarding still renders English in Hebrew mode (units, BMR/TDEE/Goal lines) | Medium | Fixed | ~2h |
| 103 | Onboarding never created the plan: setup marked complete before the generators ran | Critical | Fixed | ~1h |
| 104 | `ListTile` inside glass surfaces asserts on every build (6 screens) | High | Fixed | ~1h |
| 105 | Analytics `OverflowBox` bounded width but not height → infinite-size assert in a sliver | High | Fixed | ~20min |
| 106 | Device suite unrunnable since the native chrome landed (21/23 sanity failures) | High | Fixed | ~3h |
| 107 | Generated plan, templates and catalog rendered English in Hebrew mode | High | Fixed | ~3h |
| 108 | RTL: number+unit strings reversed, and nav chevrons pointed the wrong way | Medium | Fixed | ~1h |

**Totals:** 91 fixed, 1 partly fixed, 4 open. Every remaining item needs you --
a keystore (#49), a bundle-ID decision (#51), a product decision (#14), and one
15-minute device check (#9).

#31's translator scope shrank sharply. Across #84, #102 and #107 the recurring
finding was that the ARB keys **already existed and were simply not wired**: 35
of the 55 literals on the Profile page had keys, and all 28 of its picker option
labels did. What was genuinely missing came to ~60 new strings, not the
translator pass the earlier entries implied. The Hebrew added for those is
mine and still wants a native-speaker review, but it is a review, not a
translation project.

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
now. Notification routing, preference re-application and the beep asset gained coverage in
the #69 pass. Still uncovered: real OS notification *delivery* (needs a device clock and an
attended session) and the UI layer beyond the sanity suite.

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

### 69. Notification audit: interaction and sound  **[FIXED]**

A full pass over the notification path — `main.dart` init, `app.dart` wiring,
`CalendarNotifier` scheduling, the OS hop, `NotificationService`,
`NotificationActionHandler` — after #4/#58/#59 had already fixed dispatch.
Those earlier fixes were correct; the defects below sat *underneath* them, in
the layer that decides whether the handler is reached at all.

**a. Snooze (all three) and meal "Remove" could never run.** iOS picks the
destination isolate for an action from one thing only: whether the action
carries `DarwinNotificationActionOption.foreground`
(`FlutterLocalNotificationsPlugin.m:1303-1326`). It does *not* consider
whether the app is running. Those four actions were declared without it, so
every press went to the background isolate, whose handler is a lone
`debugPrint` — no ProviderContainer, no database, no navigator. The branches
in `NotificationActionHandler` for them were unreachable in production, even
with the app open in the foreground. Fixed by declaring all four `foreground`.

**b. One rest-timer notification killed every notification button for the
session.** `lib/core/notifications.dart` was a second, near-duplicate
`NotificationService` exporting a *second* provider with the same name, and
`workout_session_page.dart` imported that one. It ran its own `initialize()`
— and `FlutterLocalNotificationsPlugin` is a singleton (`factory ... =>
_instance`), so that re-initialized the real plugin with no
`onDidReceiveNotificationResponse`, nulling the tap handler
(`platform_flutter_local_notifications.dart:635`). Categories survived (the
native side only replaces them when `count > 0`), so the buttons kept
rendering and silently did nothing. Fixed by deleting the duplicate file and
moving `showRestTimerNotification` onto the real service.

**c. The rest timer played no sound at all.** `_playTimerBeep` constructed an
`AudioPlayer`, set its volume, and never gave it a source — the body was three
haptic buzzes and a comment reading "in production, you'd want to add an
actual beep sound file to assets". There was no `assets/` directory and no
`assets:` block in `pubspec.yaml`. So the "Rest timer sound" switch and the
volume slider in workout settings controlled nothing audible. Fixed with a
generated `assets/audio/rest_timer_beep.wav` (two 880 Hz beeps + a 1320 Hz
resolve, 5 ms fades so it doesn't click), declared in `pubspec.yaml`; haptics
kept as the fallback when audio fails.

**d. No preference change reached notifications already in the OS queue.**
Sound, vibration, lead time, quiet hours and the three category switches were
read only at the moment an event was written. Turning sound off still left
every pending reminder chiming; turning meals off still fired meal reminders —
until the event happened to be edited. Fixed with
`CalendarNotifier.rescheduleAllNotifications()`, invoked from every
schedule-affecting setter via `NotificationPreferencesNotifier
.onScheduleAffectingChange` (a callback, so the notifier keeps no calendar
dependency and the provider graph stays acyclic).

**e. Nothing ever re-synced the queue.** The old
`NotificationService.rescheduleAll()` had no callers, and bypassed
preferences entirely — calling it would have reinstated notifications the user
had turned off. Deleted. The new path now also runs on app start (re-anchoring
the 30-day recurrence horizon after a reboot or a timezone change) and on
language change (title/body text is baked in at schedule time, so pending
reminders kept the old language forever).

**f. The sleep goal-reached alert showed the wrong buttons.**
`showImmediate()` attached the category matching the event type
unconditionally, putting "Start Sleep" and "Snooze 30m" on the alert
announcing that the sleep had just *finished*. The category is now opt-in per
call, and this call passes none.

**g. The rest-timer notification was the app's only un-localized user-facing
string** (`'Rest Complete!'` / `'Time to continue with …'`) and hardcoded
`playSound: true`, ignoring the notification preferences. New
`restTimerCompleteTitle`/`restTimerCompleteBody` keys in both ARBs; sound and
vibration now come from prefs.

Verified as already working, for the record: cold-start launch handling,
tap-to-open routing by event type, the four foreground actions, recurrence
expansion under iOS's 64-pending cap, quiet hours at schedule time, iOS
foreground presentation (the plugin registers via `addApplicationDelegate:`
and `FlutterAppDelegate` forwards the delegate callbacks), and the Android
manifest's permissions and boot receiver.

New coverage: `test/regression/notification_delivery_test.dart` (9 tests) —
asserts every declared action is foreground, that the declared action ids
match exactly what the handler dispatches on, that each event type maps to a
real category, that the rest-timer id cannot collide with an event id, that
every schedule-affecting setter resyncs and the two that affect nothing do
not, and that the beep asset exists, is real RIFF/WAVE audio, and is declared
in `pubspec.yaml`. Fast suite is **360 green**; `flutter analyze lib/` clean.

Not covered, unchanged from before: real OS delivery, which needs an attended
device session.

### 70. Generated workouts were a placeholder, not a program  **[FIXED]**

Every generated template was `3 sets x 10 reps, no weight, no rest` --
identical for every goal, every experience level and every person.
`_write()` hardcoded `sets: 3, reps: 10`, `defaultWeight` was never set, and
the source carried a comment stating that goal deliberately did not influence
template selection. It looked like a plan and contained no programming.

**What replaced it.** A pure `WorkoutProgramming` module (no I/O, 25 unit
tests) supplying four things:

- **Scheme by goal** -- `muscle_gain` 4x8, `fat_loss` 3x14, `maintenance`
  3x10, `mobility_rehab` 2x12, with rest split by *mechanic*: compounds rest
  120-150s, accessories 45-75s. One rest value per session is wrong in both
  directions -- three minutes on cable curls wastes a third of the session,
  sixty on squats degrades every set after.
- **Exercise count derived from a time budget**, not fixed. 45-minute target,
  60-minute ceiling, warm-up ramps counted. This is the piece that makes the
  rest of it honest: a fixed six exercises is ~45 minutes at 3x10 and ~75 at
  4x8 once real compound rest exists.
- **Starting weight** from bodyweight-relative strength standards, adjusted
  for sex, experience and age, converted to the rep range via Epley and
  rounded to 2.5kg.
- **Volume landmarks** -- 10/14/18 weekly sets per muscle for muscle gain by
  experience.

**Two safety properties, asserted as such.** A load is prescribed only for
`kg`-based exercises, so bodyweight/band/timed work never receives one; and
every missing or unrecognised tag resolves to `LoadClass.none`, which
prescribes nothing. A tagging mistake can therefore make a program *worse*,
never dangerous. Sex is a real term rather than a nicety -- female upper-body
standards run ~60-65% of male at equal bodyweight, and ignoring it would
over-prescribe for half of all users.

**Selection was rebuilt too**, because `primaryMuscle` alone cannot program a
session: Bench Press and Dumbbell Fly are both "Chest" and are not
interchangeable. Exercises gained `movementPattern`, `mechanic` and
`loadClass` (all 58 tagged). Compounds are chosen by *pattern*, isolation by
*muscle* -- a curl and a lateral raise are both `MovementPattern.isolation`
and only the muscle says which belongs on a pull day.

Three quality bugs were found by printing an actual plan and reading it as a
coach would, with the test suite green at the time:

1. Bench Press *and* Push-ups in one session (also Squats + Bodyweight Squat,
   Deadlift + RDL) -- depth-first selection doubling up within a pattern.
2. Zero isolation work anywhere; the arms were unreachable.
3. Push-ups prescribed to someone who owns a barbell, when the progression
   rule on the template says "add 2.5kg".

**Backward compatibility.** `_applySnapshot` *replaces* the exercise list
rather than merging, so an upgrading user would have kept 58 untagged
exercises forever and generated empty sessions in silence. A field-level
backfill fills only nulls (never overwriting an edit) and walks the restored
list rather than the seed (so a deleted exercise stays deleted).

Also fixed here: the schedule capped at 5 training days, so asking for 6
silently gave 5; the onboarding slider capped at 6; and generated templates
never filled `nameHe`, so Hebrew users got an English plan.

New coverage: `workout_programming_test` (25), `generated_program_quality_test`
(16), `exercise_metadata_test` (10), `rest_prescription_test` (7),
`training_experience_test` (6), `programming_end_to_end_test` (3). Each
behaviour was verified by reverting it and confirming the tests fail.

### 71. The profile and every setting were in no backup at all  **[FIXED]**

`exportToJson` carried the twelve database collections and the calendar.
It did not carry the user profile or any preference. Restoring a backup on a
new phone brought back every meal and workout and dropped the goal, calorie
and macro targets, equipment and injuries that give them meaning -- and every
setting. A regeneration afterwards would build against a default profile the
user never entered.

Fixed by adding `profile` and `preferences` sections. Preferences are captured
by **walking the store** rather than from a list of known keys: a
hand-maintained list would rebuild exactly the drift problem the export key
set already had -- add a setting, forget the list, lose it silently. A test
asserts an arbitrary unknown key round-trips, which is what makes that
property real.

Values carry a type tag, because JSON cannot distinguish a whole double from
an int: `sleepGoalHours` is a double, and restoring `8.0` as `8` makes
`getDouble` return null and the setting silently revert to its default.

Both sections are absent from every backup written before this, and import
tolerates that -- leaving whatever is on the device alone rather than clearing
a profile the payload cannot replace.

### 72. The analytics screen is English-only  **[FIXED]**

Every string on `/analytics` is written inline in English rather than through
`AppLocalizations` — card titles, stat labels, the eight insight sentences.
Hebrew users get an English screen inside an otherwise RTL app.

The structure is right, which is why this is an hour of code and not a rewrite:
the insight *rules* emit `InsightKind` plus a map of numbers, never a sentence,
so all the wording lives in one function (`insightText` in
`lib/features/analytics/ui/analytics_format.dart`) plus the card labels. The
Hebrew itself needs a translator — see #31.

Fixed: 77 new keys in both ARB files, and not one English literal left in
`lib/features/analytics/ui/`. The screen-reader sentences went with them, so a
Hebrew user gets a Hebrew chart description too.

The **Hebrew wording is mine, not a translator's** -- it is wired and coherent,
but #31 should still cover it on the real translation pass.

One deliberate non-change: the chart time axis stays left-to-right in both
languages, matching the app's existing "numbers stay LTR" convention. Mirroring
it for Hebrew is defensible but doubles the painter test matrix on a screen that
is almost entirely numeric.

### 73. Analytics charts are invisible to VoiceOver  **[FIXED]**

A `CustomPainter` exposes nothing to the accessibility tree, so all four chart
primitives in `lib/features/analytics/ui/charts/` are silent. Every other
screen in the app is at least navigable.

Fixed with `ChartSemantics` + `describeSeries` / `describeGoalScore`. Each chart
is wrapped in a `Semantics` node whose label carries what a sighted user reads
off the shape: what is measured, over what bucket, how many periods have data,
the average and range, the direction, and the goal.

The scrub gesture is a horizontal drag, which VoiceOver intercepts for
navigation and never delivers -- so rather than bolting on a second interaction,
the label carries the summary outright. Nobody reads 30 individual bars either.

Direction is called a trend only when the net drift covers at least half the
series' own spread. That ratio, not an absolute cutoff, is what separates
calories bouncing 1950..2100 and ending 25 lower (noise) from body weight
walking 85.0 down to 82.5 (real) -- any fixed threshold gets one of them wrong.

### 74. A workout scheduled in a scrolled-to month saved but never appeared  **[FIXED]**

Reported as "I scheduled a workout and I can't see it in the calendar yet".

The service layer was never at fault -- `getEventsForDateRange` returns a newly
saved workout for any range containing it, verified for plain, recurring,
last-day-of-month and same-day cases. What the user sees is
`CalendarState.days`, filled one month at a time by `loadEventsForMonth`.

`CalendarNotifier.refresh()` reloaded exactly one month: `state.focusedDate`.
But `onMonthChanged` in `calendar_page.dart` deliberately does **not** call
`setFocusedDate` -- doing so re-animates the scroll list, which was #44. So
`focusedDate` stays on whichever month the page opened at, however far the user
scrolls. Schedule anything into a month you scrolled to, and it was written to
storage correctly and simply never rendered. It appeared "later", once that
month was paged in again -- hence "yet".

Two call sites already worked around this by hand, calling
`loadEventsForMonth(event.scheduledAt)` after completing and after deleting.
The add path had no such workaround, which is why adding was the visible
failure.

Fixed by tracking the months actually paged in (`_loadedMonths`, capped at 12)
and refreshing all of them, plus an `including:` month for the event being
acted on -- so scheduling into a month never yet visited also works. The two
hand-rolled reloads in `calendar_page.dart` were removed as redundant.

Covered by `calendar_visibility_after_add_test.dart`, which fails on three
cases before the fix. It asserts against `CalendarState.days` rather than the
service, because the service was already correct and a service-level test would
have stayed green through the entire bug.

### 75. Scheduling a workout for *now* shows it twice  **[FIXED]**

Found while reproducing #74, on the same flow. Distinct bug, not a regression
of the fix.

`event_scheduling_dialog.dart` treats anything within 5 minutes of now as
"immediate" and calls `_createDataFromTemplate`, which writes a real
`WorkoutSession` (or meal, or sleep entry). That happens **before** the
`ScheduledEvent` is constructed, so the session cannot carry `sourceEventId` --
the link the calendar folds on. The agenda then renders both the plan and the
log: exactly the #57 symptom, reintroduced through a different path.

Reproduced at the service level: one saved event plus one unlinked session for
the same day yields two rows.

Fixed with ordering plus plumbing. The event is now built first and the data
second, with `sourceEventId: event.id`; `metadata.dataId` is merged onto the
event afterwards rather than replacing the map, so a recurring event's
completed / missed / skipped occurrence dates survive an edit.

The plumbing was the real work: `MealsRepository.createMeal`,
`WorkoutSessionsRepository.createSession` and `SleepRepository.createEntry` all
dropped `sourceEventId`, because it exists only on the `*Data` row and the
create paths never took it as a parameter. (`updateMeal` / `updateSession` /
`updateEntry` already read it off the existing row and pass it back -- see #64.)
All three now accept it.

`_createDataFromTemplate` takes it as a **required** named argument, which is
what makes the ordering un-reversible: the event has to exist before that
function can be called at all.

Covered by `scheduled_now_link_test.dart`, which goes through the repositories
rather than the database -- inserting `*Data` rows directly, as
`calendar_duplication_test` does, cannot catch a create path that never sets the
field.

### 76. Every multi-placeholder ARB string passed its arguments in the wrong order  **[FIXED]**

Found by the #73 tests the moment they ran against real generated strings.

`flutter gen-l10n` orders a message's parameters **alphabetically by
placeholder name** when no `@key` metadata declares them. None of the ~700
existing keys had metadata, and it had never mattered because no existing
message had two placeholders whose names happened to sort against their
position.

Every multi-placeholder key added for #72 did. `"Average {average}, from {min}
to {max}"` generated `(average, max, min)`, so a screen reader announced
"from 2.4k to 1.8k" -- the range inverted. `"{observed} of {total} {period}"`
generated `(observed, period, total)` and read "4 of days 4". Seven keys were
affected in total, all of them silently: the strings compiled, the app ran, and
the output was simply wrong.

Fixed by declaring `@key.placeholders` explicitly, in intended order, for all
33 parameterised analytics keys -- including the single-placeholder ones, so
adding a second placeholder later cannot silently re-order the first.

Worth knowing when adding any future ARB message with more than one
placeholder: **declare the metadata, or check the generated signature.** Nothing
warns you.

### 77. The add/edit food and exercise dialogs could not be submitted on a phone  **[FIXED]**

Found by running the full integration suite, not by reading the code.

Both dialogs were `Dialog > Container(width: 400) > Form > Column` with **no
scroll view anywhere**. On a 402x874 phone the content is ~840pt tall inside a
~682pt dialog: it overflowed by 159pt, and the action row was pushed to y=926 --
past the bottom of the render tree. There was nothing to scroll, so the Add /
Update button was not merely awkward to reach, it was **unreachable**. Adding or
editing a custom food or exercise was impossible on a real device.

The exercise dialog was worse: it carries three tag groups (equipment,
contraindications, rehab) on top of the same fields.

Fixed by giving each dialog a `maxHeight` of 85% of the screen and putting only
the fields inside a `SingleChildScrollView`, wrapped in `Flexible` so the dialog
still shrinks to content on a roomy screen. The title and the action row stay
pinned, which is the point -- the bug was that the button could scroll away.

**Why no test caught it:** `integration_test/e2e/` is not run by CI, and the one
test that exercises this path had been silently passing over it. `tester.tap()`
does *not* fail when its target is off-screen -- it dispatches a hit test at the
widget's real coordinates, misses, prints a `warnIfMissed` **warning**, and
carries on. The run then died several steps later at an unrelated finder, which
is what made this look like test rot rather than an app bug.

`tapVisible()` in `integration_test/support/app_launcher.dart` now wraps
`ensureVisible` + `tap`, and every onboarding/form button goes through it. Worth
knowing generally: **a `warnIfMissed` warning in an integration run is a failure,
not a warning.**

### 78. The daily nutrition targets were not a coherent plan  **[FIXED]**

Reported as "the nutrition numbers look fishy". The per-food math was fine --
`FoodNutritionMath` is the single source of truth for display/stored quantity
and macro multiplication, and the seeded catalog's per-100g values check out
against the 4/4/9 identity. The fault was entirely in `SetupEngineService`,
which produces the *targets* those numbers are measured against.

Four defects, all in the same ~40 lines:

1. **Fat was never actually targeted.** `calculateFatTarget(weightKg,
   calorieTarget, proteinG)` returned `weightKg * 0.6` and used neither of its
   other two parameters -- an unfinished function whose comment even said "can
   be higher based on remaining calories" and then never was. Fat came out at
   13-16% of intake against a 20-35% norm, and because carbs were computed as
   "whatever is left", every calorie fat did not claim became carbohydrate. An
   80 kg maintenance profile: 48 g fat, ~370 g carbs.
2. **A flat calorie adjustment.** `-400` / `+250` regardless of body size. The
   same 400 kcal is a 13% cut for a 3000 kcal athlete and a 30% cut for a
   1350 kcal sedentary user. With no floor, a 50 kg / 158 cm / 45 y sedentary
   woman choosing fat loss was prescribed **922 kcal/day**.
3. **Protein scaled off scale weight.** 2.2 g/kg of *total* body weight gives a
   120 kg user 264 g/day -- over half their calorie target, and more than their
   lean mass needs.
4. **The four numbers were free to disagree.** `calculateCarbsTarget` clamped
   to 0 when protein and fat overran the budget, so the stored target set could
   claim 1800 kcal while its own macros summed to 1350. Nothing reconciled it,
   and `MealTemplateGenerator` then sized every generated meal against those
   inconsistent numbers.

Fixed by replacing the four independent calculators with a single
`calculateTargets()` that solves them together: deficit/surplus as a fraction of
TDEE (20%/10%, absolutely capped, floored at 1200/1500 kcal by sex), protein
against adjusted body weight above BMI 27.5 and capped at 40% of intake, fat as
a 25-30% share of calories floored at the 0.6 g/kg essential minimum, carbs as
the remainder -- and when protein plus fat still overrun, fat is walked back to
its floor and protein after it, rather than the carbs clamping silently.
Everything is rounded to numbers a person can act on, with carbs absorbing the
rounding so `4P + 4C + 9F` still reconstructs the calorie target.

`getMacroPercentages` was deleted: dead code, never called, and it documented
splits (fat 25-35%) the engine did not produce.

Onboarding and the Profile page had each open-coded the same four-call sequence,
so the formulas had two homes and could drift; both now call `calculateTargets`.

Covered by a sweep over all 72 profile shapes the onboarding form can produce
(sex x goal x activity x three body types), each asserting the set reconciles,
clears the safety floor, and sits in a defensible macro range.

### 79. The food catalog was small, English-only, and could not grow for existing users  **[FIXED]**

Asked for as "make sure all the food types have the correct amounts and add
more". The audit came first, and it split into three separate problems.

**The amounts were, in fact, right.** All 53 existing foods check out against
the 4/4/9 energy identity once fibre is accounted for. The entries that look
wrong at a glance -- broccoli 34 kcal against an Atwater 43, spinach 23 against
30 -- are correct as USDA publishes them: catalog "carbs" is *total*
carbohydrate including fibre, which yields ~2 kcal/g, and USDA uses
food-specific energy factors rather than the general 4/4/9. Nothing was changed
on that basis.

**There was no way to check.** Nothing enforced that a food's numbers were
even arithmetically possible, so a transposed digit or a value entered against
the wrong serving size would have been invisible -- no crash, just wrong
totals, forever. Now `FoodMacroAudit` + `catalog_audit_test.dart` assert energy
agreement (fibre-aware tolerance: absolute miss under 15 kcal *or* relative
under 12%), non-negativity, that a per-100g food holds under 100g of macros and
under 900 kcal, unit validity, id and name uniqueness, tag coherence, and
Hebrew coverage -- on every row, as a fast test. It caught two genuine tagging
bugs in the new rows during authoring (chicken schnitzel tagged `eggs` without
`animalProduct`, which would have offered it to a vegan).

**A bigger catalog could not have reached anyone.** `_applySnapshot` replaces
the food list rather than merging it. That is the correct behaviour -- merging
duplicates all 53 foods on every boot and resurrects starter rows the user
deleted -- but it also means every food added after a user's first launch is
invisible to them permanently. Fixed with a high-water mark of starter ids the
install has ever been *offered*, which is deliberately not the same as the ids
it currently holds: a new id is added exactly once, and a deleted one stays
deleted because its id remains recorded. Ids 1-53 are frozen as a legacy set so
an upgrading snapshot that predates the key is read correctly rather than
guessed at. The mark is carried in the backup payload too, since a restore
would otherwise reset it and re-offer everything the user had removed.

With the base in place: 56 foods added (26 Israeli, 12 everyday staples the
catalog somehow lacked -- potato, onion, chicken thigh, steak -- 7 protein
supplements, 11 McDonald's items), a `scoop` serving unit for protein powder,
and `nameHe` on all 109 rows.

One consequence worth calling out: food search matched the English name and
brand only. Shipping Hebrew content without fixing that would have made the
Israeli foods undiscoverable to exactly the users they were added for.
`FoodItem.matchesSearch` now matches both names in either language mode.

**Resolved 2026-08-09:** the fast-food figures were read from McDonald's
Israel's own nutrition calculator (order.mcdonalds.co.il) and corrected. The
US numbers had overstated an Israeli Big Mac by 36% -- 590 kcal against 434 --
and nearly doubled its fat. See #83 for the detail.


### 80. Generated meal plans could not reach their own carbohydrate target  **[FIXED]**

Reported as "it's really hard to get to the carbs goal".

`MealPortionSolver._bounds` applied one ceiling per serving kind -- 400g for any
per-100g food, 4 units for anything countable -- with no regard for what the
food was doing in the meal. That is wrong in both directions: 400g is an absurd
amount of cheddar and a modest amount of boiled potato. Applied to starches it
made the carb target physically unreachable. An 80 kg bulking profile
(3030 kcal / 409g carbs) generated a day with rice at 400g, sweet potato at
400g and bread at 4 slices -- every carb source pinned at its maximum -- and
still landed 37% short on carbohydrate and 14% short on calories. The solver
then closed the calorie gap using the only slot with headroom left, fat, which
came in 22% over. So the plan looked short on everything except fat, and
following it exactly could not reach the carb goal.

Fixed by making the ceiling depend on the role *and* on energy density: the
starch slot gets 600g, but only for foods at or under 150 kcal/100g. Role alone
would have been wrong -- oats are a carb source at 389 kcal/100g, and 600g of
dry oats is 2,300 kcal. What makes a large plate of rice reasonable is that it
is mostly water, and that is measurable from data already in the catalog. The
`portions are physically sensible` test now states the same rule in
energy-density terms rather than naming foods, so it keeps holding as the
catalog grows.

Result across the seven profile shapes in `generated_template_quality_test`:
worst-case calorie error 17.1% -> 3.9%, worst-case carb undershoot -36% -> -2%,
with protein and fat equal or better everywhere.

**Why it was not caught:** the quality test allowed carbs +/-42% and calories
+/-22%. A 37% miss passed as normal variation. Both are now pinned just outside
measured worst case (38% / 8%) -- the solver is deterministic, so there was
never a reason for that slack, and the slack is what hid the bug.

Two notes recorded because they will come up again:

  * Raising the carb weight in the solver's objective tightens carbs at the
    direct expense of protein (measured: carbs 34% -> 24% costs protein
    24% -> 27%). Left alone -- protein is the number users track, and this
    codebase already made that trade once.
  * A residual carb target is *supposed* to be the biggest number, and the
    four targets are not independent. Hitting calories, protein and fat means
    hitting carbs; missing carbs specifically means being under on calories or
    over on fat. Worth saying to a user rather than treating as a defect.


### 81. The catalog had no categories, and the audit could not check per-ml foods  **[FIXED]**

Asked for as "did you categorize it as needed... make sure you cover all the
basic foods".

**Categories did not exist.** What looked like categorisation was comment
headers in `starter_foods.dart` -- invisible to the app, so nothing could group
or filter by them, and at 109 foods the catalog page was already an
undifferentiated list with no search box. `FoodCategory` is now a stored,
persisted, bilingual field: 14 categories in a deliberate display order, plus
`other`, which the shipped catalog is forbidden to use (a starter food in
`other` is a row somebody forgot to classify, and the audit fails on it).

Kept deliberately separate from `FoodTag`. Tags say what a food *contains* and
drive diet/allergen filtering; categories say where a user would look for it.
Broccoli has no tags and still belongs under vegetables. `israeli` is a third
axis -- cuisine, not category -- so shakshuka is a prepared dish *and* Israeli.

**Coverage.** 109 -> 233 foods. The gaps were basic: no water, no coffee, no
white bread, no white pasta, no whole milk, no lettuce, no garlic, no sugar, no
ketchup, no juice, no chocolate. All of them are things a user logs in their
first week, and the audit now pins a list of them so they cannot quietly go
missing again.

**Two real defects in the audit itself,** both found by extending it rather
than by using it:

  1. *The energy check was vacuous for per-ml and per-gram foods.* The absolute
     tolerance was a flat 15 kcal regardless of serving basis, but every value
     on a per-ml row is about 0.5 -- so a milk row with ten times the correct
     fat passed the check. Demonstrated before fixing. The tolerance is now
     expressed per 100g of serving basis and scaled by unit.
  2. *Alcohol had no honest representation.* Ethanol carries 7 kcal/g and is
     none of the three macros, so a beer's stated calories cannot be
     reconstructed from its macros -- the row is right and the identity does
     not apply. Rather than omit drinks people log, or fudge the numbers,
     `containsAlcohol` exempts a row from the energy identity and from nothing
     else. The audit fails a row that sets the flag *without* needing it, so it
     cannot be used to wave a bad row through.

Upgrading installs get categories backfilled with the same rules as the Hebrew
names: field-level, never overwriting a user's value, never resurrecting a
deleted food, and skipping a row the user renamed.


### 82. Rehab sessions could not be filled, and whole muscles had no bodyweight option  **[FIXED]**

Asked for as "fix the workouts rehab exe and more exe for each body part".
Measured first; every number below is from the library as it was.

**Two rehab problems.** `SetupEngineService.getRehabExercises` was dead code
with no production callers -- a hardcoded map of exercise *name strings*
covering three of the seven body parts, whose own test asserted that an elbow
injury correctly returns nothing. Deleted. The real path (`rehabFor` tags,
filtered by equipment in `WorkoutTemplateGenerator`) was sound but underfed:
the generator asks for five exercises and **silently skips the session** when
the pool is empty, and the bodyweight-only pools were shoulder 2, elbow 2,
knee 3, ankle 3. Ankle could not reach five with *any* equipment. All seven
body parts now reach five with nothing but bodyweight, verified by driving the
generator rather than by counting rows.

**Training holes.** Zero bodyweight exercises for hamstrings, shoulders and
biceps -- a user who owns nothing could not train them at all -- and zero
`carry` exercises in the whole library, so no generated plan could contain one.
57 exercises added (58 -> 115), closing every measured gap.

**The same migration bug as the food catalog.** `_applySnapshot` replaces the
exercise list, so all 57 additions would have reached only fresh installs. The
high-water mark is now a single generic implementation shared by foods and
exercises rather than a second copy of a subtle contract.

**What the audit enforces now** (`exercise_audit_test.dart`) is *coverage*, not
just field validity -- a library can be perfectly well-formed and still unable
to program a session:

  * five rehab options per body part, per equipment kit, bodyweight included;
  * every muscle trainable with each kit (two options bare-bodyweight, three
    otherwise), and at least three overall;
  * two options per movement pattern;
  * nothing both rehabilitates and endangers the same body part -- that row
    would land in a physiotherapy session for the injury it aggravates;
  * no injury silently wipes out a muscle group. One exception is clinically
    correct and pinned by name rather than waved through: every way to train
    the triceps loads the elbow extensors, so an elbow injury leaves no direct
    triceps work. Any other pair joining that set is a real hole.

Also fixed in passing: `Brisk Walk` used the unit `min` while nothing else did,
which the unit check caught; and Hebrew names now exist for all 115 exercises
and are backfilled onto upgrading installs.


### 83. Fast-food macros were US figures on an Israeli menu  **[FIXED]**

Flagged as owner-action in #79 and resolved by reading McDonald's Israel's own
nutrition calculator (`order.mcdonalds.co.il/nutrition-calculator`, verified
2026-08-09) rather than trusting an aggregator. Worth recording *how*, because
the first two attempts were wrong:

  * A plain web search returned US values dressed up as Israeli ones.
  * Two Israeli aggregator sites disagreed with each other, and one was
    internally impossible -- 99 kcal/100g for a Big Mac, with a stated 400g
    serving that did not match its own per-serving total. Neither was used.

The official calculator is JavaScript behind an iframe, so it needed a real
browser rather than a fetch. Every figure taken from it reconciles against
4/4/9 to within 2%, which is the check that made it trustworthy.

The corrections are not cosmetic:

| | was (US) | is (Israel) |
|---|---|---|
| Big Mac | 590 kcal, 34g fat | **434 kcal, 18.8g fat** (214g) |
| McChicken | 400 kcal | 340 kcal (151g) |
| Cheeseburger | 300 kcal | 276 kcal (118g) |
| Hamburger | 250 kcal | 227 kcal (104g) |
| Fries | 320 kcal | 294 kcal (regular, 100g) |
| McFlurry Oreo | 510 kcal | 445 kcal (233g) |
| Coca-Cola | 210 kcal | 169 kcal (regular, 400ml) |

The menu also differs in *what exists*, which matters more than the numbers.
Israel has no Quarter Pounder (it has the larger Mac Royal, 584 kcal), no
Filet-O-Fish (only the Double Mac Fish, 740 kcal) and no 6-piece nuggets
(4/5/9/12/24). Those three rows keep their US figures and now say **"McDonald's
US menu"** on their face, with the Israeli items added alongside as new ids --
an id is permanent and a logged meal points at it, so correcting a number is
right but changing what a row *is* would rewrite somebody's history. Egg
McMuffin is not in the Israeli calculator at all and is likewise marked US.

### 84. The whole Profile page renders English in Hebrew mode  **[OPEN]**

Found while clearing the mechanical half of ROADMAP C5. `profile_page.dart`
contains **zero** references to `AppLocalizations` -- not "a few strings left",
the entire screen. C5 described ~20-30 strays in the appearance and calendar
screens; this is a whole page and was not in that count.

Sized rather than guessed: 218 string literals, of which ~100 already have an
l10n key and would just need wiring, and ~29 are real UI copy needing new
Hebrew (`My Profile`, `Nutrition Targets`, `Recalculate from Body & Goal`,
`Update your templates?`, the unit pickers, and so on). The rest are import
paths, route names and enum ids that must *not* be touched -- `'male'`,
`'fat_loss'`, `'dumbbells'` are stored values, and translating one would
silently corrupt a profile.

**Left for you (**me**)** deliberately, for two reasons: it needs new Hebrew
copy authored, which is exactly the half C5 says wants a person; and it is
~140 edit sites in a 1,050-line file whose only coverage is an
`integration_test` that cannot run here without a simulator. Doing it blind on
a screen in daily use is the wrong trade. The mechanical wiring in the files
that *were* already localised is done (17 strings).

---

### 85. The meal editor called itself the food editor  **[FIXED]**

`MealEditorPage`'s app-bar title was `isEditing ? l10n.editFood : l10n.addFood`
-- copy-pasted from the food editor onto the screen that edits a *meal*. Found
while moving the page onto the shared iOS scaffold, which forced every title to
be read out rather than carried along. Now `editMeal` / `logNewMeal`
(`editMeal` is a new key in both ARBs).

### 86. A Settings row went somewhere other than where it said  **[FIXED]**

The Settings list had one row labelled "Workout Templates" whose `onTap` pushed
`Routes.workoutSettings`. Nothing was wrong with the destination -- the label
was simply the wrong one, and there was no templates screen to point at. Now
that workout templates have their own screen it is two rows, each going where
it says: **Workout Settings** -> `/settings/workouts`, **Workout Templates** ->
`/workouts/templates`.

---

### 87. The meals and workouts home screens were blank  **[FIXED]**

Reported as "the UI looks broken in a lot of areas". Both screens rendered
nothing at all -- not even a navigation bar -- while `flutter analyze` was
clean and 997 fast tests were green.

`ShortcutRow` laid its tiles out with `Row(crossAxisAlignment: stretch)`. A
sliver hands its child an **unbounded** height constraint, and stretching
against an unbounded constraint asks the children to be infinitely tall:

```
BoxConstraints forces an infinite height.
The offending constraints were: BoxConstraints(0.0<=w<=Infinity, h=Infinity)
Row:file:///lib/core/ios/shortcuts.dart:36:12
```

That throws inside `performLayout`, which fails the whole subtree -- so one
bad row took both entire screens down. Fixed with `IntrinsicHeight`, which
resolves a real height first so the tiles can then stretch to match it.

**Why nothing caught it.** No test pumped either page. The unit suite covers
the widgets underneath and the repositories behind them, and a layout
exception is invisible to both -- and to the analyzer. `test/widget/
page_smoke_test.dart` now renders all 22 screens at 402x874 and fails on any
layout exception; it reproduces this bug exactly when the fix is reverted.

### 88. Every iOS glyph rendered as an empty box  **[FIXED]**

`cupertino_icons` was never a dependency. The whole new UI is built on
`CupertinoIcons` -- the "+" buttons, back chevrons, ellipsis menus, checkmarks,
calendar and search glyphs -- and every one of them rendered as tofu. Added to
`pubspec.yaml`. Nothing in Dart analysis flags this: `CupertinoIcons` is a
const `IconData` from the framework, so it compiles fine and only the *font*
is missing at runtime.

### 89. Five horizontal overflows on settings and editor screens  **[FIXED]**

Found by the new smoke test, and pre-existing -- all five are title/subtitle
columns or label rows with no `Expanded`, which overflow as soon as the text is
long. Worst was the rest-timer sound row at **184pt** over.

| Screen | Over by |
|---|---|
| Workout settings -- sound row | 184pt |
| Workout settings -- rest-time row | 19pt |
| Appearance -- preview chip row | 28pt |
| Appearance -- section headers | 18pt |
| Workout template editor -- "Exercises" header | 6.6pt |

---

### 90. Settings' "Global Timeframe" changes nothing on the dashboard  **[FIXED]**

Reported from device testing on the Settings screen. Settings -> Preferences ->
**Global Timeframe** offers Day / Week (/ Month), and the setting is persisted
and reads back correctly on the row itself -- but the home screen keeps showing
the same day view whatever it is set to.

Expected: setting it to Week switches the whole dashboard to a weekly view --
every total, ring and summary aggregates over the week rather than today, and
the date/period label follows suit. Same for the other values the picker
offers.

**[FIXED]** The scoping answer was short: *no* dashboard section read the
preference, and the weekly aggregates it needed already existed on the database
-- `getWeekTotals`, `getCompletedWorkoutsThisWeek`, `getWorkoutMinutesThisWeek`,
`getSleepWeekTotals` were all written and never called by anything. The
dashboard now picks its data source from the setting.

What "weekly" means, per section:

| Card | Day | Week |
|---|---|---|
| Nutrition | today's totals vs the daily goals | the week's totals vs the goals **x7** |
| Workouts | today's count or minutes | the week's count or minutes |
| Sleep | last night | the week's nightly average |

Weekly nutrition is a total against a scaled goal rather than a daily average,
because a weekly sum measured against a daily goal reads as 700% and makes the
progress bars meaningless. Each card now names its period ("Calories · This
week"), without which a correct change is still invisible.

### 91. Settings' "Workout Metric" changes nothing on the dashboard  **[FIXED]**

Same shape as #90 and found in the same pass. Settings -> Preferences ->
**Workout Metric** (Time Spent / others) persists and displays on its row, but
the home screen's workout figure never changes -- the dashboard ignores the
choice and shows whatever it always showed.

Expected: the metric selected here is the one the home screen's workout card
reports.

**[FIXED]** Done with #90, and the same root cause: the card called
`getCompletedWorkoutsToday()` unconditionally. It now reads the setting and
shows a count ("2") or minutes ("90 min") over the selected period.

Both are covered by `test/widget/dashboard_preferences_test.dart`, which sets
the preference and reads the dashboard. That is the only kind of test that can
catch this class of bug: a setting nothing reads still analyses, still persists,
still round-trips through backup -- it just does nothing.

---

## Native iOS chrome, found while making Liquid Glass actually appear (2026-08-12)

Nine defects, all pre-existing on `feat/platform-native-ui`, all found by reading
the chrome layer rather than by any test — the fast suite was green at 1032
throughout and `flutter analyze` was clean.

### 92. Liquid Glass never rendered  **[FIXED]**

Reported as "make sure the liquid glass is presented". It was not, and the reason is
not obvious from the code: `NavBarHostController` and `TabBarHostController` build a
**standalone** `UINavigationBar` / `UITabBar` over the Flutter view. A bar chooses
between `standardAppearance` and `scrollEdgeAppearance` by tracking a scroll view —
and these bars have none, because Flutter's scroll views are not `UIScrollView`s.
So both sat in their scroll-edge state permanently, and that state is **transparent**.
The app asked for no material and got none.

Fixed by assigning one `configureWithDefaultBackground()` appearance to *every*
state on both bars. That call resolves to whatever the running OS considers standard,
which is Liquid Glass on iOS 26 and the correct blur below it — including the Reduce
Transparency fallback, for free.

Second half of the same bug: the shells wrapped their scroll view in a `SafeArea`, so
the viewport was the gap *between* the bars. Even with the material rendering there
was nothing behind it but flat background. The bar insets now go on the scrolled
content, so content passes under the glass.

`shell_guardrail_test.dart` now asserts both bars set `scrollEdgeAppearance`, because
the failure mode here is silence: nothing crashes, nothing logs, the glass is just
absent.

### 93. The last row of every screen sat under the tab bar  **[FIXED]**

The native shells applied `SafeArea(bottom: false)` with `extendBody: true` and added
no bottom padding of their own, while the Cupertino tier had always reserved
`LiquidGlassTabBar.reservedHeight`. Every list in the app ended underneath the bar.

### 94. The native tab bar never followed navigation  **[FIXED]**

`ChromeHostApi.setSelectedTab` existed on both sides of the bridge and was **never
called from Dart**. The highlight only moved when a tab was *tapped*; navigating by
any other route (a shortcut tile, a deep link, a back gesture) left it on the previous
tab. `NativeChromeService` now listens to `routerDelegate` and syncs from the location.

### 95. Nav bar and tab bar floated over onboarding  **[FIXED]**

`setChromeVisible` was never called either, so both bars were permanently visible —
including over the onboarding flow, which is a bare `Scaffold` with its own buttons and
its own escape rules. The tab bar also showed on pushed detail pages, where the Flutter
path hides it. Both now follow the route.

### 96. Native tab labels were hardcoded English  **[FIXED]**

`const _tabLabels = ['Home', 'Meals', ...]` in a bilingual, RTL-capable app: the native
bar read English inside an otherwise Hebrew UI. Labels are now pushed from
`AppLocalizations` at the first frame that has them, and again on every language
change. The English list survives only as the pre-first-frame fallback.

### 97. A hidden bar still reserved its inset  **[FIXED]**

`barHeight` returned the bar's frame height regardless of `isHidden`, so hiding a bar
left Flutter padding content around a bar that was no longer on screen. Both hosts now
report 0 while hidden, and `setChromeVisible` forces the layout pass that re-derives
the insets.

### 98. Two of the three native shells ignored the app theme  **[FIXED]**

`PlatformChildPage` and `PlatformNavPage` rendered on `Colors.transparent`, which
showed the container's `.systemBackground` — so every settings and editor screen used
the *iOS* background rather than the theme the user picked. Only the sliver shell was
correct.

### 99. Bridge failures were unhandled  **[FIXED]**

Every Pigeon call was wrapped in `try/catch`, but Pigeon's methods return futures and
fail *asynchronously* — the catch never saw anything. On the pre-iOS-15 fallback path
(a plain `FlutterViewController`, no host API registered) that is an unhandled
`PlatformException` on every page build. Now handled with `catchError` at each call.

### 100. Deferred chrome sync leaked, and pushed stale chrome  **[FIXED]**

The in-progress work on the branch deferred the nav-bar sync until a route's push
animation completed. A route popped mid-push never completes, so its entry and its
status listener outlived it; and the closure captured the chrome from the page's
*first* build, so a page whose title resolved later pushed the wrong one. Now keyed by
animation with the latest chrome as the value, and unhooked on `dismissed` as well as
`completed`.

### The glass pass itself

Not a bug — the whole-app Liquid Glass conversion the owner asked for. See
`docs/CHANGELOG.md` (2026-08-12) for what changed, and
`docs/PLATFORM_UI_ARCHITECTURE.md` §4 for the design rule it deliberately reverses.

**Two things it does not cover**, recorded here rather than left to be discovered:

  * **`AlertDialog` bodies (12 sites) are still opaque.** Material's `AlertDialog`
    builds its own surface and offers no way to put a backdrop filter behind it
    without reimplementing the widget. The six *custom* `Dialog(child: Container(…))`
    bodies did convert, because those have a bounded size to paint behind. The right
    fix for the rest is to migrate them onto `showAppConfirm`, which is Cupertino and
    already renders the framework's real vibrancy material — a separate, mechanical
    pass.
  * **SnackBars are still opaque**, for the same reason: `SnackBar` takes a colour,
    not a widget.

---

### 101. The Analytics screen is a red error page  **[FIXED]**

Found on device (screenshot, 21:06). Opening **Analytics** renders nothing but
the framework's red error screen under the nav bar — the whole screen body is
gone; only the native nav bar and tab bar survive.

```
A GlobalKey was used multiple times inside one widget's child list.
The offending GlobalKey was: [GlobalKey#21486]
The parent of the widgets with that key was:
  NotificationListener<ScrollMetricsNotification>
The first child to get instantiated with that key became:
  _ScrollSemantics-[GlobalKey#21486]
The second child that was to be instantiated with that key was:
  NotificationListener<ScrollMetricsNotification>
```

The key belongs to a `Scrollable` (`_ScrollSemantics` is `Scrollable`'s own
internal `GlobalKey`), so this is one scroll view's element being asked to
exist in two places in the same child list at once — the usual causes being a
single scrollable *widget instance* stored in a field or a `const`/cached list
and inserted twice, or a `ScrollController`/key shared between two live
scrollables on the page.

Almost certainly fallout from the platform-native UI work on this branch
(#92–#100), which reworked how pages nest inside scaffolds and scroll views —
Analytics was rendering before that pass. Not yet scoped: needs the widget tree
for `analytics_page.dart` walked to find where the scrollable is duplicated.

**Why nothing caught it:** `test/widget/page_smoke_test.dart` (added by #87)
renders all screens and fails on layout exceptions — worth checking whether
Analytics is in its list, and if it is, why this build error didn't trip it.

Owner: unmarked (mine).

### 102. Onboarding renders English in Hebrew mode  **[FIXED]**

Found on device (screenshots, steps 2/7 and 7/7). The screen chrome is fully
Hebrew — headings, the sex toggle, the buttons — but strings sitting *next to*
numbers are not, and one whole card is untranslated:

| Where | Shows | Should be |
|---|---|---|
| Step 2 — height | `cm 170` | `170 ס"מ` |
| Step 2 — weight | `kg 70.0` | `70.0 ק"ג` |
| Step 2 — preferred units | `g` / `oz`, `kJ` | Hebrew unit labels (`קק"ל` already is) |
| Step 7 — daily targets | `kcal 2550`, `126g`, `334g`, `79g` | Hebrew unit suffixes |
| Step 7 — metabolic card | `BMR: 1643 kcal` / `TDEE: 2546 kcal` / `Goal: Maintenance` | all three Hebrew, and the goal name translated |

Two distinct defects, worth separating when this is fixed:

1. **Untranslated strings.** The unit abbreviations and the three
   `BMR:`/`TDEE:`/`Goal:` status lines are the exact items #30 listed as still
   open in `onboarding_page.dart` and left for a translator pass. `Maintenance`
   is a *goal id rendered raw* — the same class of thing as #84's warning that
   stored enum values must be mapped for display, never translated in place.
2. **Unit-before-number in RTL.** `cm 170` / `kg 70.0` / `kcal 2550` read
   backwards: bidi puts the LTR run first inside an RTL paragraph, so a
   `'$value $unit'` string flips. Even once the units are Hebrew, these need to
   be composed so the number stays adjacent and ordered correctly (an ARB
   placeholder string rather than string interpolation, or an explicit
   `Directionality`/LRM). Note `25 שנים` on the same screen is right, because
   its unit is already Hebrew — so this is purely the mixed-script case.

Related: #30 (the original list), #31 (needs a translator), #84 (same gap on
the Profile page). Owner: unmarked (mine) for the wiring and the bidi fix; the
Hebrew unit wording itself is **me** if it should not be my own copy.


---

### 103. Onboarding never created the plan  **[FIXED]**

Reported as "why doesn't onboarding create the workouts, meals and sleep on the
calendar". Generation worked; it was never allowed to finish.

`UserProfileService.saveProfile()` called `setSetupCompleted(true)`, and the
router takes `profileService` as its `refreshListenable`:

```dart
if (isSetupComplete && isOnOnboarding) return '/';
```

Onboarding calls `saveProfile()` **first**, then runs three generators --
workout templates, meal templates, and last the calendar schedule. So the
moment the profile was written the router tore the wizard down and navigated to
the dashboard while generation was still awaiting. The calendar schedule runs
last and is the only one that goes through `ref.read`, so it was first to die on
the disposed container -- the `Tried to read a provider from a ProviderContainer
that was already disposed` line that had been in the test logs all along.

It could not self-correct: `setup_completed` was already true, so the wizard
never ran again.

**Solution:** `saveProfile` takes `markSetupComplete` (default true, so profile
edits are unchanged); onboarding passes false and flips the flag only after the
plan exists. The `calendarStateProvider.notifier` read is hoisted up with the
other `ref.read`s -- it was the one read happening after three awaits, which is
exactly what the existing "read all providers BEFORE any async operations"
comment was trying to prevent. Guarded by two fast tests in
`profile_and_backup_test.dart` and by `onboarding_calendar_render_test.dart`,
which asserts on the calendar *state* rather than the database.

**Why nothing caught it:** `onboarding_schedule_flow_test` claims in its own
doc comment to check "the calendar renders the result", but every assertion in
it reads the database through `readScheduledEvents`. Generation and persistence
were well covered; rendering was not covered at all.

---

### 104. `ListTile` inside a glass surface asserts on every build  **[FIXED]**

`ListTile` resolves its ink, background and `selected` tint against the nearest
`Material`. Inside a `ContentSurface`/`GlassSheet` there is none, so Flutter
raises `ListTile background color or ink splashes may be invisible` rather than
degrading -- on the settings rows, the profile page, both food pickers, the
workout-template exercise picker, the onboarding "build schedule" switch, and
the calendar's event menu.

**Solution:** the grouped rows became `InsetRow`; the pickers became
`Pressable`; the calendar's six-tile sheet became a real `showAppActionSheet`,
so it is now a `UIAlertController` with a system Cancel. All of them lose the
ink ripple, which was the point.

---

### 105. Analytics `OverflowBox` given an infinite size  **[FIXED]**

`ChartAxisLabels` bounded `maxWidth` but not `maxHeight`. Inside a sliver the
incoming height constraint is unbounded, so it asked for infinite height and
threw `RenderConstrainedOverflowBox object was given an infinite size during
layout` -- 30 exceptions on one screen. A fixed `maxHeight` would work until
Dynamic Type moved it; `fit: OverflowBoxFit.deferToChild` sizes to the label and
keeps the horizontal overflow the widget exists for.

---

### 106. The device suite had been unrunnable since the native chrome landed  **[FIXED]**

21 of 23 sanity tests failed before reaching the screen under test. The nav bar
and tab bar are UIKit objects, so `find.byKey(Key('glass_tab_/meals'))` and
every dashboard-action finder matched nothing.

**Solution:** the launcher overrides `nativeChromeActiveProvider` and
`NativeUI.debugForceUnavailable`, driving the Flutter tier -- a real shipped
code path (Android, iOS < 15, bridge not attached) rendering the same pages
behind the same keys.

**The trade, stated plainly:** these tests no longer cover the native chrome
itself -- the bars, SF Symbols, scroll-edge behaviour, native alerts and the
banner. That needs XCUITest, which this repo does not have.

Also fixed on the way: `tap()` silently misses any row under the floating tab
bar (the finder matches, the bar swallows the tap, and the failure surfaces two
steps later), hence the `tapInScroll` helper; and a batch of finders stale since
the design pass -- a `FilledButton` that became a `GlassButton`, an
`Icons.insights_outlined` that became a Cupertino icon, and a Hebrew test
asserting an English food name against a catalog that renders
`displayName(language)`.

Sanity 23/23, regression 25/25, e2e journey green.

---

### 107. The generated plan and catalog rendered English in Hebrew  **[FIXED]**

A plan generated during Hebrew onboarding came out in English on the calendar,
and the food/template lists were mixed.

Three separate causes, all "the bilingual field exists and nothing reads it":

* `CalendarScheduleGenerator` copied `template.name` -- the English column --
  though `WorkoutTemplateData.nameHe` had been filled all along. It now takes
  the onboarding language and resolves the name.
* `MealTemplate` has a `nameHe` column the generator never filled. All 14
  recipes gained `nameHe` and every meal slot a Hebrew label, so a template
  composes as `ארוחת בוקר: ביצים וטוסט`.
* Seeded built-in workout templates had no `nameHe` at all, so the list mixed
  translated generated sessions with untranslated built-ins.

Plus the display layer: the meal editor read `food.name` rather than
`displayName(language)`; `FoodTag`, `Equipment` and `BodyPart` gained the
`label(AppLanguage)` shape `FoodCategory` already used; units are mapped by
token (`100g` -> `100 ג`, keeping the number); and `FoodItem.displayBrand`
maps the 59 distinct brand descriptors in one place rather than adding a
`brandHe` column to 234 rows.

**Deliberately not translated:** rehab template names, which are pinned to
English so stored rows do not inherit whichever locale happened to be active.

---

### 108. RTL: reversed number+unit strings, and chevrons pointing the wrong way  **[FIXED]**

Two bidi defects, both app-wide rather than per-screen.

`'$value $unit'` inside an RTL paragraph has its LTR run reordered, so `170 cm`
rendered as `cm 170`. `RTLHelper.numericLTR` already existed and was simply not
applied. `InsetRow` now forces LTR for *number-led* values only -- word values
like `שמירה` keep the ambient direction, since forcing those is the same bug
pointing the other way.

`CupertinoIcons.chevron_back`/`chevron_forward` read as directional but their
glyphs are fixed. A `Row` mirrors under RTL, so Previous correctly moved to the
right-hand side and then still drew a left-pointing arrow: both chevrons ended
up pointing at the wrong neighbour. `RTLHelper.chevronBack/chevronForward` pick
the glyph by direction; applied to the date strip, the calendar day view, the
workout session stepper and every `InsetRow` disclosure.
