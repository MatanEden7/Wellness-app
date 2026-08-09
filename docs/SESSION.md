# Session Log

Updated after every completed work session. Most recent first.

---

## 2026-08-09 — Nutrition targets rebuilt

**Current task:** None.

**Last completed:** `ISSUES.md` #78. Reported as "the nutrition calculator
looks fishy — maybe the amount per food, maybe the goal amount". Checked the
per-food side first and it was clean: `FoodNutritionMath` is the single source
of truth for display↔stored quantity, `MealItem.create` snapshots macros
through it, and the seeded catalog's per-100g values reconcile with 4/4/9. The
fault was `SetupEngineService`, which produces the *targets*.

- The tell was `calculateFatTarget(weightKg, calorieTarget, proteinG)` ignoring
  two of its three parameters. It returned the 0.6 g/kg essential-fat minimum
  as if it were a target, so fat sat at 13–16% of intake and carbs — computed
  as the remainder — absorbed everything else. 80 kg maintenance: 48 g fat,
  ~370 g carbs.
- Three more in the same block: flat ±400/250 kcal regardless of body size and
  with no floor (a 50 kg sedentary woman cutting got 922 kcal/day), protein at
  2.2 g/kg of *scale* weight (264 g/day at 120 kg), and carbs clamping to 0 so
  the stored four numbers need not add up to their own calorie target.
- Replaced with one `calculateTargets()` that solves all four together. The
  reconciliation step is the part worth remembering: when protein + fat overrun
  the budget it walks fat back to its floor, then protein, instead of letting
  carbs go negative-then-zero. Rounding is applied last with carbs absorbing it,
  so `4P + 4C + 9F` still reconstructs the calorie target within ~12 kcal.
- Deleted `getMacroPercentages` — dead code that documented splits the engine
  never produced, which is exactly the kind of thing that makes a number look
  fishy when you go reading.
- Onboarding and the Profile page had each open-coded the same four calls. Both
  now call the one method, so the screen you edit from can't change your targets.
- Test approach: rather than pinning formula outputs (which is what the old
  tests did, and why a wrong formula stayed green for months), the new sweep
  runs all 72 profile shapes the onboarding form can produce and asserts
  *properties* — reconciles, clears the safety floor, macro shares defensible.
  Two of my first bounds were wrong, not the code: a 45 kg very active bulker
  legitimately eats 62% carbs, and 1.8 g/kg protein is only 13% of intake for a
  light person eating 2750 kcal.

**Next task:** nothing queued from this work. Full fast suite green (705).

---

## 2026-08-09 (later) — Food catalog rebuilt

**Current task:** None.

**Last completed:** `ISSUES.md` #79. Asked for as "make sure all the food types
have the correct amounts and add more... but first build a solid base". Taking
the base seriously is what made the rest cheap, and it changed the shape of the
answer twice.

- **The amounts were already right.** Auditing all 53 against 4/4/9 turned up
  no errors. The scary-looking outliers (broccoli 34 vs 43, spinach 23 vs 30)
  are fibre plus USDA's food-specific energy factors — correct as published.
  Resisting the urge to "fix" them into agreement was the right call, and the
  tolerance in `FoodMacroAudit` is shaped around that reality: pass if the miss
  is under 15 kcal absolute *or* 12% relative, which forgives leafy veg (where
  8 kcal is 25%) and nuts (where 8% is 45 kcal) without forgiving a misplaced
  decimal point.
- **The real defect was that nothing could check.** Wrong catalog numbers fail
  silently forever. `FoodMacroAudit` + `catalog_audit_test.dart` now gate every
  row. It earned its keep immediately, catching two tagging bugs in rows I was
  writing at the time.
- **The structural blocker, found before adding anything:** `_applySnapshot`
  replaces the food list rather than merging, so a catalog addition could only
  ever reach fresh installs. Adding 56 foods without noticing this would have
  shipped nothing to the one user who has the app. Fixed with a high-water mark
  of ids the install has been *offered* (≠ ids it holds), a frozen 1–53 legacy
  set so upgrading snapshots are read rather than guessed, and the mark carried
  in the backup so a restore cannot resurrect deletions either.
- Then the content: 26 Israeli foods, 11 McDonald's, 7 protein supplements, a
  `scoop` unit, and 12 everyday staples the audit exposed as missing — there was
  no potato, no onion, no chicken thigh and no steak in a food catalog.
- `nameHe` on all 109 rows. Which surfaced one more thing: search matched
  English only, so shipping Hebrew content without fixing it would have made
  the Israeli foods unfindable by the people they were for.

**Next task:** none queued. Full fast suite green (842). Fast-food figures are
US-menu and tagged **me** in ISSUES for a local-menu pass if wanted.

---

## 2026-08-09 (third) — Carbs diagnosis, then catalog categories

**Current task:** None.

**Last completed:** `ISSUES.md` #80 and #81.

- "It's really hard to get to the carbs goal" turned out to be a real bug, and
  the way to find it was to *print the generated portions* rather than reason
  about the solver. Rice 400g, sweet potato 400g, bread 4 slices -- every carb
  source pinned at its ceiling, so the plan closed the calorie gap with fat.
  Worth remembering: when a solver's output looks biased, check whether it is
  actually up against a constraint before touching the objective weights.
- The fix needed two passes. Role-aware bounds alone were wrong: oats are a
  carb source at 389 kcal/100g, and the existing "portions are physically
  sensible" test caught 600g of dry oats. Energy density, not role, is what
  makes a big plate reasonable. That test earned its keep.
- Tightened the quality tolerances afterwards (carbs 42% -> 38%, calories
  22% -> 8%). The loose bound is *why* a 37% miss survived. Deterministic code
  does not need slack.
- Then categories, which the catalog never actually had -- comment headers in a
  source file are not a category axis. Kept it separate from `FoodTag` (what a
  food contains) and added `israeli` as a third cuisine axis rather than
  overloading either.
- 109 -> 233 foods. Generated and validated the data in Python before emitting
  Dart, which caught every macro error up front; the only bugs left were in the
  emitter (apostrophe in "McDonald's" broke the quote-aware splitter twice).
- Two genuine defects found in my *own* audit while extending it: the absolute
  energy tolerance was a flat 15 kcal, which is vacuous for per-ml rows (a milk
  row with 10x the fat passed -- demonstrated before fixing), and alcohol had
  no honest representation. Both fixed properly rather than by loosening.

**Next task:** none queued. Full fast suite green (977).

---

## 2026-08-07 — Analytics screen

**Current task:** None. Shipped end to end.

**Last completed:** the analytics page, asked for as "graphs for all the
important data according to dates... to know that I'm using the same weight for
a while... and in the top graph put all the goals reached together", clean and
simple in an iPhone idiom. Architecture written up first in
`docs/ANALYTICS_PLAN.md`, then built to it.

- `features/analytics/domain/` is pure Dart — ranges/bucketing, series maths,
  goal scoring, e1RM + plateau detection, insight rules. No Flutter, no DB,
  same shape as `WorkoutProgramming`, and where all 49 new tests point.
- `AnalyticsRepository` is the only thing that touches `AppDatabase`; it
  indexes once and joins in memory rather than calling the existing per-day
  `watchMealsByDate` in a loop.
- One `analyticsViewProvider(range)` feeds all seven cards. Deliberately not
  per-section streams — that is the `build()`-time stream pattern the repo is
  working its way out of, and it would have run the aggregation seven times a
  frame.
- Charts are four hand-written painters. `fl_chart`'s theming would have been a
  second source of truth for colour next to 9 themes and custom section
  colours, and its default look is Material rather than iOS.
- Body weight became a real entity. It is the one thing the screen needed that
  the app had no history for — `UserProfile.weightKg` is a scalar the calorie
  formula reads. Wired into export/import in the same change, and into the
  exact-key-set assertion in `export_completeness_test`, which is the test that
  exists because meal templates, calendar events and the profile each spent a
  release missing from backups.
- Two behaviour notes worth remembering: in-progress sessions are filtered out
  of every aggregate (otherwise an abandoned workout is a zero-volume training
  day and a free streak day), and a night of sleep is attributed to the day it
  *ended* on.
- Reverses two "explicitly out of scope" lines in `ROADMAP.md` — weight history
  and progression analytics — because the screen cannot answer "am I
  progressing?" without them.
- 531 → 581 fast tests. `flutter analyze` clean on everything new.

**Then, same day — four bug fixes.** Reported as "I scheduled a workout and I
can't see it in the calendar yet".

- **#74** was not where it looked. The calendar *service* returned the event
  correctly in all five shapes I probed (plain, same-day, recurring,
  full-month, last-day-of-month). The state layer was the problem:
  `refresh()` reloaded only `state.focusedDate`'s month, and `onMonthChanged`
  deliberately never moves `focusedDate` (that re-animates the scroll list --
  #44). Anything scheduled into a scrolled-to month saved and never rendered.
  The notifier now tracks the months actually paged in and refreshes all of
  them. Two hand-rolled reloads in `calendar_page.dart` that had been papering
  over this for the complete and delete paths came out.
- **#75** turned up while reproducing #74: scheduling for *now* wrote the data
  before the event existed, so there was no id to link, and the three
  `create*` repository methods had no parameter to accept one anyway. Fixed by
  ordering plus plumbing; `_createDataFromTemplate` now takes the id as a
  *required* argument, which is what stops the ordering regressing.
- **#73** (a11y) and **#72** (bilingual) closed together on the analytics
  screen. 77 ARB keys, no English literals left, screen-reader sentences
  included.
- **#76** only exists because #73's tests ran against real generated strings:
  `gen-l10n` orders parameters alphabetically without metadata, so
  `"from {min} to {max}"` generated `(max, min)` and announced ranges
  backwards. Seven keys, silently wrong. Metadata now declared for all 33.

Two lessons worth keeping. Test at the layer that can actually fail --
`#74`'s regression test asserts on `CalendarState.days` because a
service-level test stays green through the whole bug, and `#75`'s goes through
the repositories because inserting `*Data` rows directly cannot catch a create
path that never sets a field. And `#76` is the case for testing generated
localisations against the real strings rather than a stub.

581 -> 606 fast tests.

**Then — install on the iPhone, and integration flows.**

- **Installed on the device.** `flutter install` reports "Prebuilt binary ...
  does not exist" for a bundle that is plainly there, on both relative and
  absolute paths. `xcrun devicectl device install app` works. Worth remembering
  rather than re-diagnosing: build with `flutter build ios --release`, install
  with devicectl.
- **New flows**: `integration_test/regression/onboarding_schedule_flow_test.dart`.
  All four start from a user with three weeks of history, via a new `seed` hook
  on `buildTestApp`/`pumpApp`. They assert the post-onboarding schedule is
  complete, recurring, template-pinned, matches the profile just saved, is
  actually *rendered* on the calendar, and left the pre-existing history alone.
- **#77, found by running rather than reading.** The add/edit food and exercise
  dialogs had no scroll view; on a phone the content overflowed by 159pt and
  put the Add button at y=926 on an 874pt screen. Not awkward -- unreachable.
  Adding a custom food or exercise was impossible on a real device.

**The lesson that made #77 findable**, and it cost two wrong diagnoses first:
`tester.tap()` does **not** fail on an off-screen target. It hit-tests at the
widget's real coordinates, misses, prints `warnIfMissed` as a *warning*, and
carries on -- so the run dies several steps later at an unrelated finder and
reads as test rot. Three separate places were silently no-op'ing this way. There
is now a `tapVisible()` helper and every form/onboarding button goes through it.
Treat a `warnIfMissed` line in an integration log as a failure.

**Full run:** fast 606/606. Device: sanity 9/9, regression 4/4, e2e 3/3. The two
notification e2e tests need an attended session -- the iOS permission alert
reappears per build and has to be tapped, which is why they stay out of CI.

**Next:** the device has the build but has not been driven through a manual
pass. The Hebrew wording on the analytics screen is mine, not a translator's --
#31 still covers that.

---

## 2026-08-06 — Workout programming

**Current task:** None. Filed and fixed as `ISSUES.md` #70 and #71.

**Last completed:** replaced the generated-workout placeholder with real
programming, asked for as "build it according to goals using real data, how
many reps, how much weight, workout strategy... a workout can be up to 1 hour
tops, usually 45 minutes".

- `WorkoutProgramming` (new, pure, no I/O): scheme by goal, rest by mechanic,
  bodyweight-relative load standards adjusted for sex/experience/age, volume
  landmarks, and a duration estimator. Exercise count is *derived* from the
  45-minute target rather than fixed -- the piece that makes the rest honest.
- Exercises gained `movementPattern` / `mechanic` / `loadClass`; all 58
  tagged. Compounds selected by pattern, isolation by muscle.
- `trainingExperience` on the profile, collected in onboarding's Goals step.
  Deliberately not an 8th step -- it belongs with the other training
  questions and avoids disturbing step indices the sanity suite walks.
- `defaultRestSeconds` per template exercise, driving the in-session timer and
  editable in the template editor.
- Profile + all preferences added to the backup; they were in none.
- Schedule supports 1-7 training days (capped at 5); slider capped at 6.
- 351 -> 531 fast tests across the day.

**Method note worth keeping:** the three best fixes in this pass came from
*printing a generated plan and reading it as a coach would*, with the suite
green at the time -- Bench Press paired with Push-ups, no isolation work
anywhere, and push-ups prescribed to a barbell owner. Property tests confirmed
the arithmetic; only looking at the output caught that the arithmetic was
being applied to the wrong exercises.

**Second note:** every behaviour in this pass was verified by reverting it and
confirming the tests fail. That caught one test of my own that passed with and
without the fix.

**Next task:** the device pass. Nothing here has been seen on hardware, and
the new programming only appears after Settings -> Reset all data and a fresh
onboarding (the agreed rollout). The catalog is now the binding constraint --
Calves x1, Glutes x2, Biceps x2 means Leg Day A and B are identical at 6 days,
and no algorithm fixes that.

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
