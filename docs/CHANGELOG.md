# Changelog

Notable completed work, most recent first. Update when a feature or fix ships —
see `CLAUDE.md` for the full doc-tracking rules.

## Unreleased

### Goal-driven workout programming (2026-08-06)

Generated workouts were `3 sets x 10 reps, no weight, no rest` for every goal
and every person -- a placeholder that looked like a program. Filed as
`ISSUES.md` #70.

- **Sessions are programmed from the goal.** Sets, reps and rest now come from
  the goal (`muscle_gain` 4x8, `fat_loss` 3x14, `maintenance` 3x10,
  `mobility_rehab` 2x12), with rest split by mechanic -- compounds rest two to
  three times as long as accessories.
- **Exercise count is derived from a time budget**, not fixed. Sessions target
  45 minutes and are capped at 60, warm-up ramps included. A fixed six
  exercises is ~45 minutes at 3x10 and ~75 at 4x8 once real compound rest is
  counted.
- **Starting weights are prescribed**, from bodyweight-relative strength
  standards adjusted for sex, training experience and age, converted to the
  rep range via Epley and rounded to 2.5kg. Only ever for `kg`-based
  exercises; bodyweight, band and timed work get none.
- **New onboarding question: training experience.** Activity level is a
  calorie input and a poor strength proxy -- an active postman is not an
  experienced lifter.
- **Splits target training each muscle twice a week** and support 1-7 days.
  The schedule capped at 5, so asking for 6 silently gave 5; the training-days
  slider capped at 6.
- **Selection is by movement pattern, not muscle name.** Fixes sessions that
  paired Bench Press with Push-ups, or Squats with Bodyweight Squat, while
  never reaching the arms at all. Loaded lifts are preferred over bodyweight
  ones when the user owns the kit, because the progression rule is "add
  2.5kg".
- **Per-exercise rest drives the in-session timer**, replacing one global 90s
  value used for heavy squats and cable curls alike. Visible and editable in
  the template editor.
- **The profile and every setting are now in the backup.** They were in no
  backup at all: restoring on a new phone brought back the meals and workouts
  and dropped the goal, targets, equipment and injuries that give them
  meaning. Preferences are captured by walking the store, so a new setting
  cannot be forgotten.
- Generated templates carry Hebrew names, which `WorkoutTemplateData` has
  supported all along and the generator never filled.

### Notification audit (2026-08-05)

Full pass over the notification path. Dispatch was already fixed (#4/#58/#59);
these are the defects underneath it, in the layer that decides whether the
handler is reached at all. Filed as `ISSUES.md` #69.

- **Snooze and meal "Remove" now actually work.** iOS routes an action to the
  background isolate unless it is declared `foreground` — regardless of whether
  the app is running. All four such actions were missing it, so their handler
  code was unreachable in production. Pressing them did nothing, always.
- **A completed rest timer no longer kills every notification button.** A
  duplicate `NotificationService` in `lib/core/notifications.dart` ran its own
  `initialize()` on the same (singleton) plugin, nulling the tap handler for the
  rest of the session. File deleted; the rest-timer notification moved onto the
  real service.
- **The rest timer plays an actual sound.** It set a volume on a player that
  had no audio source, so the sound switch and volume slider in workout settings
  were inaudible no-ops. Ships a generated beep asset.
- **Notification settings now apply to reminders already scheduled.** Sound,
  vibration, lead time, quiet hours and the category switches were read only when
  an event was written, so toggling one left the existing queue untouched. Every
  such change now re-issues the queue.
- **The queue is re-synced on app start and on language change** — it previously
  drifted after a reboot or timezone change, and pending reminders kept whatever
  language they were scheduled in.
- **The sleep goal-reached alert no longer offers "Start Sleep" / "Snooze 30m"**
  on an alert announcing that the sleep just finished.
- **The rest-timer notification is localized** (it was the last hardcoded English
  user-facing string) and honours the sound/vibration preferences.

### Edit-path fixes (2026-08-05)

- **Calendar "Edit" no longer opens a blank form — or creates a duplicate.** The
  scheduling dialog always supported editing; the Edit action just never handed it
  the event, so the form came up empty *and* saving added a second event instead of
  updating the one being edited. Recurring occurrences now resolve to their base
  event first (editing an occurrence edits the series).
- **Editing a meal, workout or sleep entry no longer un-links it from the calendar
  event that created it.** `sourceEventId` lives only on the DB row, so every
  repository update silently nulled it and brought back the duplicated-row bug.
  Reachable just by stopping a sleep timer started from an event.
- **Editing a meal no longer moves it on the calendar.** Its `createdAt` was being
  stamped forward on every edit, and the calendar falls back to `createdAt` when no
  explicit time is set.
- **Deleted workout sessions and sleep entries no longer resolve by id.** Both
  deletes skipped their `*ById` cache — same class of bug as the referential-integrity
  pass, missed there.
- **Export share sheet no longer crashes on iPad**, which the app ships for: UIKit
  needs a `sharePositionOrigin` to anchor the popover.

- Profile screen wired up end-to-end: view/edit body, goal, activity, targets;
  reachable from Settings and the dashboard. Recomputes BMR/TDEE/targets live
  via `SetupEngineService`, matches `PROFILE_AND_SETTINGS_PLAN.md`'s Option A
  (that plan is now retired — fully superseded by this).
- Calendar events + meal templates added to export/import (was DB-only before;
  scheduled events lived in SharedPreferences and were silently excluded).
- Export gained a real share sheet; import gained a file picker (previously
  paste-JSON-into-a-TextField only).
- Sleep streaks (consecutive nights meeting the sleep goal) added, surfaced on
  the Sleep page.
- Fixed a real DST bug in `AppDateUtils.startOfWeek`/`endOfWeek` — used
  `Duration`-based day arithmetic, which drifts across a clock change; now
  uses the DST-safe `DateTime(y, m, d±n)` pattern already used elsewhere.
- Added `Meal.loggedAt` — a real time-of-day field instead of guessing from
  `createdAt`/keyword matching. Meal editor has a Time (optional) field; the
  calendar prefers it when present.
- "Stop Sleep" affordance surfaced on the dashboard quick-action (reflects an
  active session instead of always reading "Sleep Timer").
- Added a "Delete data older than X" option (Settings → Data Management) for
  meals/workouts/sleep entries and one-off calendar events.
- Fixed 3 real WCAG AA contrast failures in the built-in theme palette (ocean/
  forest/sunset primary colors were 2.5–2.8:1 against white button text,
  below the 4.5:1 bar) — caught by a new `test/regression/theme_contrast_test.dart`
  that audits every built-in theme.
- Added golden tests for `HuePicker`/`SaturationBrightnessPicker` (guards the
  zero-width `CustomPaint` regression class — ISSUES.md #32).
- Added a widget-interaction test tier (`test/widget/`) — tap a widget in
  isolation, assert its callback fired.
- Added `test/regression/notification_scheduling_test.dart` — asserts a
  scheduled event reaches the OS pending-notification queue, without waiting
  on real delivery.
- Accessibility: every icon-only `IconButton` now has a `tooltip`.
- Verified (not removed) `BackgroundRefreshService` — trimmed one dead
  `invalidate()` call after tracing it had no watcher, kept the two that do.

## Earlier

### Performance pass

- **Removed 500ms polling.** Every collection (`meals`, `foods`,
  `mealTemplates`, `workouts`, `sleep`) now has a `StreamController` that
  mutators fire on insert/update/delete, instead of a 500ms polling timer.
  ~60–70% CPU-while-idle reduction; updates are now instant instead of
  delayed up to 500ms.
- **O(n) → O(1) lookups.** Added `Map<String, T>` id-caches (`_foodsById`,
  `_mealsById`, `_mealTemplatesById`, `_exercisesById`,
  `_workoutTemplatesById`, `_workoutSessionsById`, `_sleepEntriesById`)
  alongside the existing lists, kept in sync on every mutation. `getById()`
  calls that used to do a linear `firstWhere()` scan are now instant
  regardless of collection size.

(`OPTIMIZATION_PROGRESS.md`'s remaining open items — moved to `docs/ROADMAP.md`
Epic G, since they're still real and hadn't been tracked as roadmap items.)
