# Session Log

Updated after every completed work session. Most recent first.

---

## 2026-08-16 — Real UIKit, an Apple calendar, and the Hebrew that was already there

**Current task:** None. Branch `feat/liquid-glass-native-ios`. Installed on the
iPhone 17 simulator and on the Matan Eden iPhone (release, iOS 27.0).
`flutter analyze` clean; device suites green; fast suite not re-run after the
final localisation batch.

**Asked for, in order:** make the whole app native iOS Liquid Glass; make the
calendar look like Apple's; deploy to the phone; run the tests and fix what
breaks; then a long tail of "this is still English" reported from live
screenshots.

**Three findings reframed the work.**

1. **The native presentation bridge was dead code.** `PresentationHostApiImpl.swift`
   implements alerts, action sheets, menus, date pickers, share and haptics on
   real UIKit, `AppDelegate` registers it, pigeon generates the Dart — and no
   Dart ever called it. Every dialog in the app was Flutter drawing a
   look-alike beside an unused `UIAlertController`. Rewriting the shared helpers
   in `sheets.dart` made every existing call site native at once.

2. **Onboarding was destroying its own output.** `saveProfile()` flipped
   `setup_completed`; the router takes the profile service as its
   `refreshListenable` and redirects off `/onboarding` immediately — while the
   three generators were still awaiting. The calendar schedule runs last and is
   the only one going through `ref.read`, so it died on the disposed container.
   The user reported it as "onboarding doesn't create the plan"; the
   `ProviderContainer that was already disposed` line had been in the test logs
   all along.

3. **The Hebrew was mostly already written.** ISSUES #84 estimated "~29 new
   Hebrew strings" for the Profile page. In the event 35 of its 55 literals
   already had ARB keys, and *all 28* of its picker option labels did. The same
   held for goal names, BMR/TDEE, macro abbreviations, food names and the back
   button. ~60 strings were genuinely new; the rest was wiring.

**A pattern worth carrying forward:** twice, a fix looked complete and a second
copy of the same switch lived elsewhere. `_goalLabel` existed in both
`profile_page` and `settings_stub`; `formatDuration` exists on *two* classes
named `AppDateUtils`, and callers resolve to whichever they imported
unprefixed. Both times the first fix left the bug visibly alive.

**On the test suite.** The device suite had been unrunnable since the native
chrome landed — 21 of 23 sanity tests died before reaching their screen, because
the bars are UIKit objects and the finders look for Flutter widgets. Forcing the
Flutter tier in the launcher fixed that and got sanity to 23/23, regression to
25/25 and the e2e journey green — at the cost of no longer covering the native
chrome at all. That needs XCUITest. Repairing the suite also surfaced three real
product bugs (#104 `ListTile` in glass, #105 the analytics `OverflowBox`, plus
an `InsetRow` overflow of my own making).

**Owner preference recorded:** don't run the full suites to check a small
change — they are slow (sanity ~7min, regression ~9min, and the notification
scheduling e2e blocks on a native permission dialog for hours). Prefer
`flutter analyze`, then a single named file.

**Next task:** run the fast suite against the localisation batch — it touched
`drift_database.dart`, the recipe catalog and two shared `formatDuration`
signatures, which is exactly what those tests exist to catch. Then decide
whether the validation-message refactor is worth it, and get a native-speaker
pass over the ~60 new Hebrew strings.

---

## 2026-08-12 (later) — The UI design pass: a real Liquid Glass system

**Current task:** None. Branch `feat/platform-native-ui`, built and installed on the
iPhone 17 simulator (iOS 26.3). 1168 fast tests green, `flutter analyze` clean.

**Asked for:** a full UI design pass — "make sure to see actual design of liquid glass,
fix all the themes, change all the things you see fit from the size of buttons to size
of everything".

**The finding that reframed the work.** I read Apple's own material rather than
reasoning from screenshots. The WWDC25 session names three layers — content, functional,
navigation — and lists **"applying Liquid Glass directly to content"** as an
anti-pattern. We had glass on every card, twice, on request. That is why the screens
read as washed out: with everything translucent there was nothing left for the glass to
float over, so the material stopped meaning anything.

**And the system underneath was worse than the material.** The audit measured:

  * two spacing scales that disagreed (screen padding 16 vs 20), with **86% of paddings
    written as raw literals** and the most common pair in the app — `horizontal: 14,
    vertical: 7` — belonging to neither;
  * 18 font sizes, no 17pt slot, so iOS body text could only be a literal (20 sites);
    `AppThemeKind.custom` had **no textTheme at all** and silently reflowed the app to
    Roboto;
  * 13 corner radii arranged anti-concentrically — 18pt chips inside 12pt cards;
  * six tap heights, 24+ controls under Apple's 44pt floor;
  * **`dark` and `gold` were byte-identical palettes**, `dark` had one accent repeated
    three times, three themes drew hairlines in 87% white, and the light family sat at
    1.05:1 background-to-surface, where a surface is invisible.

**Four decisions, all the owner's**, taken before any code: Apple's layer model, real
scroll-edge behaviour piped to native, all nine themes re-derived, full 44pt spec.

**What shipped**, in eight steps: `lib/core/design/tokens.dart` (type ramp as a
`TextTheme`, one 4pt scale, `Radii.inner()` implementing concentricity, 44pt floor) ·
nine theme ramps · `ContentSurface` and 22 files off glass · glass re-tuned to tint from
the elevated rung · sizing to spec · the scroll edge · a per-screen pass · docs.

**Three things worth carrying forward:**

  * **The tests set the numbers, not my eye.** Four new per-theme assertions caught
    eight real failures mid-pass; `prominentTintAlpha` had already been moved 0.86 → 0.93
    by the contrast test earlier in the day. Every colour decision here has a test that
    would fail if it drifted.
  * **The scroll edge was the missing signal all along.** The date strip went band → no
    band → unpinned across three rounds of screenshots, and each was a workaround for
    the fact that nothing observed scroll offset. UIKit derives it from a connected
    `UIScrollView`; ours is Flutter's, so it had to be reported over the bridge.
    `setScrollEdge` is 20 lines and it retired the whole argument.
  * **`glass_coverage_test.dart` was inverted rather than deleted.** It used to enforce
    "everything is glass"; it now enforces the layer split, with a per-file reason list.
    The rule that changed is the one the test states.

**Not done:** the `--profile` raster measurement (moving cards off glass should have
*reduced* it — worth confirming), and the on-device look itself.

**Next:** owner's visual pass; then the profile run; then merge.

---

## 2026-08-12 — Liquid Glass everywhere, and nine native-chrome bugs

**Current task:** None. Branch `feat/platform-native-ui`, built and installed on the
iPhone 17 simulator (iOS 26.3). Awaiting the owner's visual pass.

**Asked for:** "fix the bugs in this branch, and make sure the liquid glass of iOS 27
is presented", then "I want all the app to be glassy".

**Worth recording about the version:** Liquid Glass is the **iOS 26** design language.
The simulator and Xcode here are both 26.3; there is no iOS 27 runtime on this Mac and
nothing in my knowledge covers one. Everything targets iOS 26's material, which is what
the device renders. Said once, early — the owner used "iOS 27" throughout and it did not
change any decision.

**Why glass was missing, which was not guessable from the code:** a standalone
`UINavigationBar`/`UITabBar` picks its appearance by tracking a scroll view. These bars
have none — Flutter's scroll views are not `UIScrollView`s — so both sat permanently in
`scrollEdgeAppearance`, which is transparent. The app was asking for nothing. Fixed by
assigning `configureWithDefaultBackground()` to every appearance state. The other half:
the shells wrapped their scroll view in `SafeArea`, so even a rendering material had
only flat background behind it.

**Nine bugs**, ISSUES #92–#100, all pre-existing on the branch and all found by reading
rather than by testing: content under the tab bar, the tab bar never following
navigation, both bars floating over onboarding, English-only tab labels, hidden bars
still reserving insets, two shells ignoring the app theme, unhandled async bridge
failures, and a leaking deferred chrome sync.

**Then the glass pass**, scoped by four decisions the owner made up front: everything
including content cards; a theme-derived gradient backdrop; an Off/Subtle/Full setting;
iOS only. `lib/core/ios/glass.dart` is the single recipe — every card, list group,
sheet, dialog and Cupertino-tier bar calls `GlassSurface`.

**Three things worth carrying forward:**

  * The tint is the theme's own `surface` at an alpha, not a grey film. That is what
    makes legibility *provable*: a composite of surface over background has a luminance
    between the two, and `theme_contrast_test` already pins `onSurface` against both.
    The test now runs every theme × every level × the coloured wash, and it is what
    fixes the alphas — not taste.
  * `GlassBackdrop` is load-bearing, not decoration. Blurring a flat colour returns the
    same flat colour; without a wash behind the content the entire pass is invisible.
  * One `BackdropGroup` per route (`GlassLayer`) with `BackdropFilter.grouped`
    everywhere. A surface outside the group still looks correct and costs a full-screen
    read — the only symptom is raster time, which no test catches.

**`docs/PLATFORM_UI_ARCHITECTURE.md` §4 said content must never be glass** ("the design
would collapse into soup"). The owner was shown that paragraph, chose the wider scope,
and the reversal is now written into the doc with its mitigations rather than left as a
silent contradiction between doc and code.

**Verification:** 1100 fast tests green (was 1032), `flutter analyze` clean, built and
installed on the simulator. `page_smoke_test` gained a second pass rendering all 21
screens on the **Cupertino shell with glass at full strength** — that branch had zero
coverage before, on either side of the bridge.

**Not done, deliberately:** the 12 `AlertDialog` bodies and all SnackBars stay opaque —
both take a colour, not a widget, so neither can host a backdrop filter without
reimplementing the widget. The right fix is migrating those dialogs onto
`showAppConfirm`, which already renders the framework's real vibrancy. Also not done:
the profile run to measure raster cost, and the on-device look itself.

**Next:** owner's visual pass on the simulator; then the profile run; then either the
`AlertDialog` migration or merging the branch.

---

## 2026-08-11 — Platform-native UI split N0–N8 complete

**Current task:** None — Epic N complete. Branch `feat/platform-native-ui` ready to merge.

**Last completed:** All 9 milestones (N0–N8) of Epic N on branch `feat/platform-native-ui`.
Build verified on iPhone 17 simulator (iPhone 17, iOS 26.2, UDID 0B4D71FD).

- N0: iOS target → 15.0, Pigeon added, `core/platform/` (`ShellKind`, `shellKindProvider`),
  architecture layering test.
- N1: `PageChrome`/`ChromeAction` data contract; `MaterialPageShell`; Cupertino fallback
  wrappers. All 22+ `AppScaffold` call sites migrated. 1031 tests pass.
- N2: `_appleize()` gated to iOS/macOS — Android gets real M3.
- N3: Pigeon bridge; `RootContainerViewController` + `TabBarHostController` + `ChromeHostApiImpl`;
  `AppDelegate` updated; native UITabBar live on simulator.
- N4: `NavBarHostController` (UINavigationBar large-title, back button, trailing actions);
  `_maybeSyncChrome()` fires Pigeon `setPageChrome` on every page build.
- N5: `PresentationHostApiImpl` (action sheets, alerts, date picker, share, haptics);
  `CapabilityReporter` (Reduce Transparency, Reduce Motion, Dynamic Type, dark mode).
- N6: `PageChromeSpec` carries `languageCode`/`isRTL`; `CapabilityReporter` surfaces
  accessibility flags. Device VoiceOver/Hebrew check deferred to attended session.
- N7: `nativeChromeActiveProvider` is a plain Riverpod `Provider`, overridable per-test.
- N8: `shell_guardrail_test.dart`; SDK adoption checklist in `docs/RELEASE.md`.

**Next:** Merge `feat/platform-native-ui` → `main`, then continue with Epic B or A3.

---

## 2026-08-09 — One iOS shell for every screen

**Current task:** None.

**Last completed:** the UI realignment asked for as "make the workout page like
the meals page ... and make the view iPhone style 100%". Scope was confirmed up
front rather than guessed: iOS idioms on Material (not a Cupertino rewrite,
which would bypass `theme.dart`'s colour system), every screen that needs it,
templates split onto their own screen, FABs dropped.

- New `lib/core/ios/` kit: `AppScaffold`/`AppNavScaffold`, action sheets and
  confirms, swipe-to-delete rows, inset lists, segmented control/search/filter
  pills, the shared date strip and shortcut tiles. Every page in `lib/features/`
  is built from it; `grep -rn "appBar: AppBar\|PopupMenuButton\|FloatingActionButton" lib`
  now returns only comments in the kit itself.
- Workouts restructured to mirror meals: date-anchored home screen (new
  `watchSessionsByDate`), templates on `/workouts/templates` with the editor at
  `templates/new` and `templates/:id`, search + muscle filtering added to the
  exercise library.
- The two add/edit dialogs (food, exercise) became full-screen modal pages —
  they were the ones capped at 85% height with the Save button falling off the
  bottom.
- Two bugs found by conversion: `ISSUES.md` #85 and #86.

**Then it turned out to be broken.** Installed on the phone, the meals and
workouts screens were completely blank and every iOS glyph was a tofu box —
with the fast suite green and the analyzer clean the whole time. Found by
running it on a simulator and reading the layout exception, not by reasoning:

- `ShortcutRow` stretched a `Row` against the unbounded height a sliver hands
  down (#87) — one bad row, two blank screens.
- `cupertino_icons` was never a dependency (#88).
- Five pre-existing horizontal overflows, worst 184pt (#89), plus an
  off-centre date label and a missing space.

**The real fix is `test/widget/page_smoke_test.dart`**: all 22 screens rendered
at 402x874, failing on any layout exception. It reproduces #87 exactly when the
fix is reverted. Nothing in the suite had ever pumped a whole page — that is
why a green suite meant nothing here.

**Verification:** fast suite 1019/1019, `flutter analyze` clean, and dashboard
/ meals / workouts / food catalog eyeballed on the simulator.

**Then: breaks in workout templates.** A "Customize breaks" switch (off =
automatic rest from the rep count, nothing to see; on = break rows plus the
button that adds them), breaks as ordinary rows in the exercise list so they
drag anywhere, compact 56pt exercise rows, and swipe-to-edit added to
`SwipeActionRow` and wired into every list in the app. Two new fields, both
defaulting false so old backups read back unchanged; covered by
`test/regression/template_breaks_test.dart`. Verified on the simulator screen
by screen.

**Next task:** run `integration_test/` on the simulator to confirm the updated
finders — still not done.

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

## 2026-08-09 (fourth) — Exercise library

**Current task:** None.

**Last completed:** `ISSUES.md` #82. Same shape as the food work, and the
measure-first habit paid off again.

- Probed the library by equipment kit before writing anything. That is what
  turned "add more exercises" into a specific list: zero bodyweight hamstring,
  shoulder and biceps exercises, zero `carry` exercises at all, and rehab pools
  of 2-3 against a generator that asks for 5 and silently skips the session
  when the pool is empty.
- `getRehabExercises` was dead code with no callers, covering 3 of 7 body parts,
  with a test asserting its own gap was correct. Second time this session that
  a wrong-but-unused function was sitting next to the right one
  (`getMacroPercentages` was the first). Worth checking callers before trusting
  that a function is the implementation.
- Validated the additions in Python against the coverage invariants *before*
  emitting Dart -- caught 18 accidental duplicates of exercises that already
  existed, which reading the file would not reliably have caught.
- The audit found two things I had not thought about: a unit inconsistency
  (`min` vs `minutes`) and, more interestingly, that every triceps exercise is
  contraindicated for the elbow. That one is clinically correct, so it is
  pinned by name as an expected exception rather than "fixed" by weakening the
  invariant.
- Third repetition of the same migration bug (foods, then exercises). Rather
  than copy the fix again, generalised it into `_mergeNewSeededRows`. If a
  third seeded collection appears, it should use that.

**Next task:** none queued. Full fast suite green (994).

---

## 2026-08-09 (fifth) — Clearing the owner-tagged items

**Current task:** None.

**Last completed:** `ISSUES.md` #83, plus half of ROADMAP C5. Asked to go
online and clear whatever was tagged **me**, leaving anything too complicated.

- Five items were tagged. Three are genuinely not mine to do: B1/B3/B4 are
  device notification checks, #9 is a device sleep-notification verify, A3 is a
  product decision and F2 a design opinion. Two were actionable.
- The McDonald's numbers took three attempts and the failures are the useful
  part. A web search returned US values dressed as Israeli. Two Israeli
  aggregators then disagreed, and one was internally impossible (99 kcal/100g
  for a Big Mac against its own 400g serving). Only the official calculator was
  usable, and it is JS behind an iframe so it needed the browser, not a fetch.
  **Rule of thumb: for nutrition data, cross-check the source against 4/4/9
  before believing it** -- that is what exposed the bad aggregator immediately.
- Menu *identity* differs, not just numbers: no Quarter Pounder, no
  Filet-O-Fish, no 6-piece nuggets in Israel. Resisted relabelling those rows,
  because ids are permanent and logged meals point at them. Corrected the
  numbers where the item is the same product; added new ids for the Israeli-only
  ones; marked the rest "US menu" on their face.
- C5's mechanical half: the naive "English value -> l10n key" mapping had two
  traps that only reading the Hebrew caught. `onboardingInjuriesBack` is 'גב',
  the body part -- wiring five navigation Back buttons to it would have put
  *torso* on them. Worth remembering: an .arb value match is not a meaning
  match.
- Stopped short of `profile_page.dart`, which turned out to have zero
  localisation at all -- a whole screen, not the strays C5 described. It needs
  ~29 new Hebrew strings and ~140 edit sites in a file whose only coverage is a
  simulator integration test. Filed as #84 rather than done blind.

**Next task:** #84 if wanted. Full fast suite green (997).

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
