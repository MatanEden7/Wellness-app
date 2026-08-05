# Session Log

Updated after every completed work session. Most recent first.

---

## 2026-08-05 — Notification audit

**Current task:** None. Filed and fixed as `ISSUES.md` #69.

**Last completed:** a full pass over the notification path, asked for as "make
sure we can interact and it really plays sounds whenever needed". Dispatch was
already fixed in earlier passes (#4/#58/#59) and was fine; what was broken sat
underneath it.

- **Snooze (×3) and meal Remove were unreachable.** iOS decides which isolate
  gets an action purely from whether it is declared `foreground` — not from
  whether the app is running. Those four weren't, so every press went to the
  background isolate and its `debugPrint`-only handler. The handler code for
  them had been written, reviewed and tested, and could never run.
- **One completed rest timer disabled every notification button** for the rest
  of the session. A duplicate `NotificationService` in `lib/core/notifications.
  dart` re-initialized the singleton plugin without a response callback. File
  deleted.
- **The rest timer was silent** — its `AudioPlayer` was given a volume and
  never a source. Generated `assets/audio/rest_timer_beep.wav` and wired it up.
- **No notification preference reached the existing OS queue.** Added
  `CalendarNotifier.rescheduleAllNotifications()`, called from every
  schedule-affecting setter, plus on app start and language change.
- Sleep goal-reached alert no longer shows "Start Sleep"/"Snooze 30m"; the
  rest-timer notification is localized and honours the sound prefs; the unused,
  preference-bypassing `NotificationService.rescheduleAll()` is gone.

New `test/regression/notification_delivery_test.dart` (9 tests). 351 → 360
fast tests, all green; `flutter analyze lib/` clean.

**Method note worth keeping:** the three worst findings were all invisible from
Dart alone — they came from reading `FlutterLocalNotificationsPlugin.m`'s
delivery routing and the plugin's Dart `initialize()`. Auditing our own code
against the plugin's *documented* behaviour would have found none of them.

**Next task:** the device pass (ROADMAP B1/B3/B4). Everything here changed real
runtime behaviour and the fast suite cannot observe the OS side. The device
suite also has not run since these changes.

---

## 2026-08-05 (final) — Epic H complete + perf

**Current task:** None. Everything not needing the user is done.

**Last completed:**
- H3 tag editors (food + exercise), so user-added content gets tagged too --
  the piece that stops the tagging system decaying, since untagged content
  fits every profile by design.
- H4 profile filtering on the food catalog and exercise library, with a
  hidden-count banner, one-tap "Show all", and a reason badge on revealed
  rows. Session-scoped toggle, not persisted.
- H6b regenerate-on-profile-change: offers a rebuild when diet, exclusions,
  equipment, injuries, training days or meal count change, showing exactly
  how much would be replaced. Only `TemplateOrigin.generated` is ever
  touched; user templates and built-ins survive.
- G6: moved `requestPermissions()` off the first-frame path (it was holding
  the UI behind the OS permission dialog on first launch).
- G4 (partly): `getDayTotals` was O(meals x allItems) per stream emission,
  now a single pass. Deliberately not a maintained index, given two
  stale-id-cache bugs already shipped.
- 331 -> 336 tests, analyze clean. Three commits pushed to `rc`.

**Next task:** Nothing unblocked remains. Outstanding work is the 5 items
needing the user (keystore, bundle ID, stale-nutrition decision, Hebrew
translation, two device checks) plus the larger Epic G items (G1/G2/G3
rebuild-reduction, G5 search debounce) which are real but low-urgency.

---

## 2026-08-05 (later) — content/profile architecture

**Current task:** Epic H paused after H1/H2/H5/H6a; H3, H4 and H6b remain.

**Last completed:**
- Diagnosed why nothing matched the onboarding answers. Root cause was that
  content carried no metadata: `FoodItemData` had no allergen/diet fields and
  `ExerciseData` had no equipment/contraindication fields, so "does this fit
  me?" was unanswerable and was being faked with hardcoded English food-name
  lists and self-minted exercises.
- Built the architecture first, as asked: `FoodTag`, `Equipment`, `BodyPart`,
  `TemplateOrigin`, and `ProfileFit` as the single source of truth (the role
  `FoodNutritionMath` plays for unit math).
- Tagged the whole catalog and expanded it using values pulled from the USDA
  FoodData Central API: foods 42 -> 52, exercises 16 -> 40. Added the `neck`
  injury. Sizing driven by a new coverage test across all 192 diet x exclusion
  combinations plus every equipment and injury option.
- Rewrote both generators to select from the catalog through `ProfileFit`.
- Added the opt-in "set up my full schedule" step to onboarding, and fixed the
  schedule generator to pin events to profile-generated templates rather than
  blind built-ins.
- Fixed several converter bugs found along the way, all the same class as the
  earlier `sourceEventId` drop: the *shared* `foodItemFromData` dropped `tags`
  (so all filtering would have silently no-op'd), the exercise and template
  converters dropped their new fields, and seeded built-ins were labelled
  `user` instead of `builtin`.
- 286 -> 331 tests, analyze clean. Four commits, pushed to `rc`.

**Next task:** H3 (tag editors, so user-added content is tagged), H4 (list
filtering + "show all"), H6b (regenerate-on-profile-change prompt). The
service-layer support for H6b already exists and is tested --
`ProfileFit.contentAffectingFieldsChanged` and `isReplaceable`.

---

## 2026-08-05

**Current task:** Done — awaiting review of the edit-path fixes.

**Last completed:**
- Fixed the `nutrition_math_ui_test.dart` device failure carried over from the last
  session: the new "Time (optional)" field pushed the food-picker's Add button below
  the fold, and the test tapped a fixed offset instead of scrolling to it.
- Acted on the report that "the edits ask you to add all the parameters again":
  audited **every** edit form in the app. Only the calendar was broken — foods,
  exercises, sleep entries, meal items, meal-template items and both template
  editors all prefill correctly. The calendar's Edit action never passed the event
  to a dialog that fully supported editing, so the form opened blank *and* saving
  created a duplicate instead of updating (ISSUES.md #63).
- Found and fixed three more bugs while reviewing the surrounding code, each
  verified to fail against the unfixed code before fixing (ISSUES.md #64–66):
  `sourceEventId` dropped on every meal/workout/sleep update (resurrecting the
  calendar duplicate bug, reachable just by stopping a sleep timer); `createdAt`
  stamped forward when editing a meal (silently moving it on the calendar); stale
  id-cache entries left behind by `deleteWorkoutSession`/`deleteSleepEntry`.
- Fixed an iPad crash I introduced last session: the export share sheet had no
  `sharePositionOrigin`, which UIKit requires to anchor a popover (ISSUES.md #67).
- Added missing test coverage for last session's work, which had shipped untested:
  sleep streaks, `deleteDataOlderThan`/`deleteEventsOlderThan`, `Meal.loggedAt`,
  calendar-events export/import, and a real DST-boundary case for
  `AppDateUtils.startOfWeek`/`endOfWeek`.
- Fast suite 259 → 286 tests, all green; `flutter analyze` clean (0 errors).

**Next task:** User to review; no device/simulator runs performed this session per
their instruction. Remaining engineering work is Epic G (performance) — everything
else open needs the user (see docs/STATUS.md).

---

## 2026-08-04

**Current task:** Diagnosing device-suite failure in `nutrition_math_ui_test.dart`.

**Last completed:**
- Closed every "not me" item from the `docs/ISSUES.md` / `docs/ROADMAP.md` status
  table generated earlier this session (17 items — profile screen entry points,
  export/import share sheet + file picker + calendar events, sleep streaks, a real
  DST bug fix, `Meal.loggedAt`, dashboard sleep-stop affordance, data-aging cleanup,
  icon/switch/contrast consistency fixes (3 real WCAG AA failures found & fixed),
  accessibility tooltip sweep, golden tests, widget-interaction tests, a
  notification-scheduling test, and a verified (not blind) trim of
  `BackgroundRefreshService`).
- Caught and fixed a real dependency-resolution break: adding `file_picker` pulled in
  a `win32` version incompatible with this project's Dart SDK — fixed via
  `dependency_overrides` + loosening the `ffi` pin.
- Ran the fast suite (259/259 green) and the full device suite (11/12 green, one
  failure under investigation).
- Restructured project docs: `CLAUDE.md` moved to repo root (was empty, in the wrong
  place); `REPO_GUIDE.md`, `ISSUES.md`, `RELEASE.md`, `TESTING.md`,
  `WELLNESS_APP_SPEC.md` moved into `docs/`; `PRODUCT_PLAN.md` renamed
  `docs/ROADMAP.md`; `OPTIMIZATION_PROGRESS.md` folded into new `docs/CHANGELOG.md`;
  `PROFILE_AND_SETTINGS_PLAN.md` retired (fully superseded by the profile screen
  built this session). Added `.claude/commands/` with 10 project slash commands.

**Next task:** Fix the `nutrition_math_ui_test.dart` failure, re-verify device suite,
then hand back to the user for review of the new doc/command structure.
