# Wellness App — Product Engineering Plan

Scope discipline: **same features, same goals** (meals, workouts, sleep, calendar,
local-first, Hebrew/English). Nothing here adds a feature area the app doesn't already
have (no cloud sync, no Health integration, no barcode scanning — those stay out of
scope, as they were in the original spec's "Phase 2"). Everything below either makes an
existing feature actually work end-to-end, or makes the existing UI more consistent and
usable. Verified against the current code, not against the original audit — several
things assumed broken are already fixed as of the last pass.

Each item has a priority (P0 = broken/missing in a way users will hit immediately, P1 =
degrades trust or usability, P2 = polish, P3 = groundwork/tech debt) and a rough size
(S/M/L). Priority is about user impact, not difficulty.

---

## Epic A — Close the loop on data users already trust the app with

The last pass fixed persistence, profile save/load, and export/import round-tripping.
These are the gaps that remain *around* those fixes.

**A1. Show the profile the user just spent 7 onboarding steps building.** — P0, M — **[DONE]**
`UserProfile` (sex, weight, goal, equipment, BMR, TDEE, calorie/macro targets) is
written once at onboarding and never displayed again — grep confirms the only two
reads of `userProfileServiceProvider` outside onboarding are the router's
setup-complete check and the dashboard's "reset all data" button. Add a Profile screen
(reachable from Settings) that shows the saved values and lets the user edit weight,
goal, activity level, and equipment — reusing `SetupEngineService.createUserProfile()`
to recompute BMR/TDEE/targets on save, the same formulas onboarding already uses.

**A2. Calendar events aren't in the backup.** — P1, S — **[DONE]**
Scheduled/recurring events live in `SharedPreferences` under `scheduled_events`,
entirely separate from `AppDatabase`. `ExportImportService` only reads from
`AppDatabase`, so a user's workout/meal/sleep schedule — including anything
onboarding generated — silently isn't in their export. Add it to the export payload
and restore it on import (bump export version to 1.2.0, tolerate its absence on
older imports the way 1.1.0 already tolerates missing meal templates).

**A3. Decide the product answer on stale nutrition, then implement it.** — P1, S
Editing a `FoodItem`'s macros doesn't touch existing `MealItem` snapshots. Right now
this reads as intentional (a logged meal keeps what it said at the time, like a
receipt). Make it explicit instead of ambiguous: add a small "X existing meals still
use the old values" notice on the food editor when saving a changed food, with a
button to recalculate. Don't auto-recalculate silently either way — that's the one
behavior that would surprise a user in either direction.

**A5. Device backup — DONE.** — was P0, now shipped
OS-level backup is wired on both platforms with a user-facing opt-out (Settings →
Data Management → Device Backup), plus iOS Files-app visibility. See ISSUES.md #3 for
the mechanism and why each platform needed a different approach. Remaining backup work
is A2 (calendar events missing from export) and the share-sheet/file-picker UX.

**A4. Data doesn't age out.** — P2, S — **[DONE]**
The JSON snapshot and the calendar's SharedPreferences list both grow forever — every
meal, set, and sleep entry ever logged stays in the file that's read and rewritten on
every app start. Not urgent at real-world usage volumes, but add a "Delete data older
than X" option in Settings before it becomes a slow cold start a year from now.

---

## Epic B — Finish the notification system

**B1. Verify the sleep-goal-reached notification on a real device.** — P0, S
Added last pass, compiles, but nothing has watched it actually fire — no automated
test can, since it needs `showImmediate()` to hit the real plugin. One manual check:
start a sleep timer, stop it past the goal hours, confirm the notification appears.
Since the #69 pass it should show **no action buttons** — it was attaching the sleep
category, so it offered "Start Sleep" and "Snooze 30m" on an alert saying the sleep
had just ended. Confirm that too while you're there.

**B2. Badge count is a documented no-op.** — P2, S — **[DONE]**
Turned out already resolved: `updateBadgeCount()` no longer exists in the code and no
settings copy references it — nothing dead to remove or wire.

**B3. Sound/vibration prefs need one more device check.** — P2, S
Fixed in code (per-combination Android channels, `presentSound` on iOS) but I only
verified via `flutter analyze` + unit tests, not by hearing/feeling a real
notification. Same category as B1 — quick manual pass, not a code question.
Scope grew with #69, so check three things now: (1) toggling sound off changes
reminders that were *already* scheduled, not just new ones; (2) the rest timer emits
an audible beep at the configured volume (it was silent — the player never had an
audio source); (3) Snooze and meal Remove do something when pressed from the
notification, which they never did before.

**B4. Verify notification actions end-to-end on a device.** — P1, S — **[NEW, #69]**
`test/regression/notification_delivery_test.dart` asserts every action is declared
`foreground`, which is what makes it reach the handler at all — but only a real
device proves the OS honours it. Schedule a meal reminder a minute out, then press
each of Approve / Remove / Snooze from the notification and confirm all three act.

**B5. Verify the generated program on a device.** — P1, S — **[NEW, #70]**
Nothing in the programming work has been seen on hardware. Needs Settings →
Reset all data then a fresh onboarding (the agreed rollout), then: a template
shows sets × reps @ weight and a rest interval; picking `fat_loss` instead of
`muscle_gain` visibly changes all four; and finishing a set starts a rest
timer of the prescribed length rather than the flat 90s.

---

## Epic I — Exercise catalog depth  — **P1**

**I1. Seed 15-20 more exercises.** — P1, M
The catalog is now the binding constraint on program quality, not the
algorithm. Calves ×1, Glutes ×2 and Biceps ×2 mean Leg Day A and B come out
identical at 6 days a week, and no amount of selection logic fixes that.
Needed most: calves, glutes, biceps, triceps, and a second vertical pull.
Each must carry `movementPattern`, `mechanic`, `loadClass`, equipment and
contraindications — `exercise_metadata_test` fails on any that does not.

**I2. Deloads and periodization.** — P3, L
Templates are static; progression is the double-progression rule printed on
each one. Real block periodization needs the app to read logged performance
and mutate templates over weeks. Deliberately out of scope for the first
version.

---

## Epic C — Visual & UX consistency pass

From the screenshot sweep: one confirmed rendering bug already fixed (hue slider). The
rest are consistency gaps, not broken widgets.

**C1. Icon treatment is inconsistent between screens.** — P1, M — **[DONE]**
Main Settings list uses colored square badges behind every icon (orange food icon,
purple sleep moon, etc.) — good contrast, easy to scan. Notification Settings,
Nutrition Goals, and several list rows elsewhere use bare `Icon(...)` with default
opacity directly on the dark background — readable, but noticeably lower-contrast and
inconsistent with the rest of the app. Standardize on one pattern (the badge one — it's
already the majority) via a shared `SettingsIconBadge` widget instead of ad-hoc
`Container(decoration: ...)` at each call site.

**C2. Toggle switches don't match Material 3's usual on-state contrast.** — P2, S — **[DONE]**
Enabled switches show a dark thumb on a blue track; Material 3's default is a
light/white thumb, which reads "on" faster at a glance. Add a `SwitchThemeData` to
`core/theme.dart` for each `AppThemeKind` rather than leaving it to widget defaults —
this also fixes it in one place instead of per-screen.

**C3. No profile/account entry point on the dashboard.** — P1, S — **[DONE]**
Ties to A1: once a profile screen exists, surface it. The dashboard's flask icon
(dev-only test-data trigger) and the settings gear are the only top-level icons right
now; a small profile/avatar affordance is missing entirely from the main navigation.

**C4. Golden tests for the custom-painted widgets.** — P2, M — **[DONE]**
Added for `HuePicker`/`SaturationBrightnessPicker` (now public, were `_HuePicker`/
`_SaturationBrightnessPicker`) in `test/regression/color_picker_painters_test.dart`.
The rest-timer turned out not to be a `CustomPainter` at all — it's a
`FractionallySizedBox` progress bar (`workout_session_page.dart`'s `_RestTimerCard`),
so no equivalent zero-size risk there; excluded on inspection.

**C5. Hardcoded strings still rendering in Hebrew mode.** — P2, L (mostly translation
work, not engineering)
~20-30 strings remain, concentrated in the appearance/color-picker screens, a few
calendar action-sheet items, and onboarding's BMR/TDEE readout. Two different kinds
of work here, worth splitting:
  - Strings that already have an unused l10n key sitting in both `.arb` files just
    need wiring (mechanical, safe to batch).
  - Strings needing a *new* key need real Hebrew text from a person, not a
    code-only pass — flagged in the original audit as deliberately left alone for
    that reason, and that reasoning still holds.

---

## Epic D — Accessibility

**D1. Screen reader support is essentially unaudited.** — P1, M — **[DONE]**
`Semantics(...)` appears in exactly one file (`advanced_color_picker.dart`, on the
HSVA sliders) across 45 UI files. Icon-only buttons (calendar filter, dashboard flask,
the color-picker swatches) likely have no accessible label at all for VoiceOver/
TalkBack. Do a pass adding `tooltip`/`Semantics.label` to icon-only `IconButton`s app-
wide — this is mechanical once identified, and IconButton already has a `tooltip`
parameter sitting unused in most call sites (a few screens already use it correctly,
e.g. `meals_page.dart`'s back button — that's the pattern to replicate everywhere).

**D2. Color contrast on custom-colored sections.** — P2, S — **[DONE]**
Audited via `test/regression/theme_contrast_test.dart` (onSurface/surface,
onSurface/scaffoldBackground, onPrimary/primary for every built-in theme). Found and
fixed 3 real AA failures: ocean/forest/sunset primary colors were 2.5–2.8:1 against the
white text buttons render on top of them, below the 4.5:1 bar — darkened to shades
already used elsewhere in each theme's own palette (e.g. `_oceanTextSecondary`).

---

## Epic E — Test coverage gaps

**E1. Widget-level tests, not just integration sanity smoke tests.** — P2, M — **[DONE]**
Current test suite (69 fast + 8 device) covers repositories, calendar logic, and
"does this screen render without crashing." Nothing exercises interaction on a single
widget in isolation (tap a button, assert a callback fired) — that tier is currently
missing entirely between unit tests and full-app integration tests.

**E2. No automated notification-delivery test.** — P3, M — **[DONE]**
Added `integration_test/e2e/notification_scheduling_test.dart`, asserting
`pendingNotificationRequests()` contains the expected entry after scheduling. Stays in
`e2e/` (not run by CI) since it still calls `initialize()`/`requestPermissions()` for
real, same permission-dialog caveat as `notification_smoke_test.dart`. Real visual
delivery is still not automatable without a device clock.

---

## Epic F — Code health (do opportunistically, not as a dedicated sprint)

**F1. `BackgroundRefreshService` may now be redundant.** — P3, S — **[DONE]**
Verified by tracing, not removed blind: `dashboard_page.dart` directly
`ref.watch()`s `workoutSessionsRepositoryProvider`/`sleepRepositoryProvider`, so
invalidating those two is what forces the dashboard to rebuild and pick up a new
`today` after midnight — genuinely load-bearing, kept. `mealsRepositoryProvider`'s
invalidate call had no such watcher anywhere (every meals stream provider reads it via
`ref.read()` specifically to avoid this cascade) — confirmed dead, dropped.

**F2. Icon semantics review.** — P3, XS
Not a bug (confirmed `Icons.scale` is correct and intentional for "weight unit"), but
worth a second opinion from an actual designer — the glyph reads as an hourglass to at
least one person (me, on first look) at small size. Cheap to swap for
`Icons.monitor_weight` if a second look agrees.

---

## Epic G — Performance follow-ups

Carried over from the retired `OPTIMIZATION_PROGRESS.md` (folded into
`docs/CHANGELOG.md` for what's already shipped — the 500ms-polling removal and O(1) id
caches). These were never actually tracked as roadmap items before; they are now.

**G1. Move calculations out of `build()`.** — P2, M
Heavy filtering/sorting/aggregation still happens inline in several widgets' `build()`
methods instead of a provider — recomputes on every rebuild, not just on data change.

**G2. Use Riverpod `.select()`.** — P3, M
Widgets `ref.watch()` whole provider objects and rebuild on any field change. Narrowing
to `.select()` on the specific field would cut a chunk of unnecessary rebuilds.

**G3. Split large widgets.** — P3, L
Dashboard/meals/workouts screens are large single-`build()` widgets; breaking them into
focused components would make G1/G2 easier to apply precisely.

**G4. Cache aggregations.** — P3, S — **[PARTLY DONE]** `getDayTotals` was O(meals x allItems) and ran on every meals-stream emission; now a single pass. Deliberately *not* a maintained index — this app has shipped two stale-id-cache bugs already.
Daily nutrition totals, workout summaries recomputed on every watch instead of cached
and invalidated on mutation.

**G5. Debounce search.** — P3, XS
Text-input-driven filtering (food catalog, exercise library) has no debounce; every
keystroke re-filters immediately.

**G6. Lazy-load non-critical services at startup.** — P3, XS — **[DONE]** `requestPermissions()` was awaited before `runApp()`, holding the first frame behind the OS permission dialog. Now unawaited; nothing at boot schedules a notification.
Everything currently initializes eagerly in `main.dart`; worth checking what's actually
needed before first frame vs. deferrable.

---

## Epic H — Content actually fits the profile

Onboarding collects diet, exclusions, equipment and injuries, but nothing
downstream honoured them: built-in templates were seeded blind before a
profile existed, and the generators faked the check with hardcoded English
food-name lists and self-minted exercises.

**Decisions taken** (2026-08-05): non-fitting content is *hidden with a
"show all" escape hatch* (never deleted); profile changes *prompt* before
regenerating, and only ever replace `origin: generated`; tags are
*first-class editable fields*, so user-added content is covered too; `goal`
stays **target-only** and does not drive content selection.

**H1. Tag model + ProfileFit.** — P0, M — **[DONE]**
`FoodTag`, `Equipment`, `BodyPart`, `TemplateOrigin`, and `ProfileFit` as
the single source of truth for "does this suit this user?".

**H2. Tag + expand the catalog.** — P0, L — **[DONE]**
Foods 42 -> 52 (USDA-verified), exercises 16 -> 40, `neck` injury added.
Sized by `catalog_coverage_test.dart`, which walks all 192 diet x exclusion
combinations plus every equipment and injury option.

**H5. Generators select from the catalog.** — P0, M — **[DONE]**
Both generators now go through `ProfileFit` instead of string matching and
self-minted content.

**H6a. Onboarding full-schedule option.** — P0, S — **[DONE]**
Opt-in (default on) complete recurring schedule, pinned to generated
templates so the calendar respects the profile too.

**H3. Tag editors in the food and exercise UI.** — P1, M — **[DONE]**
Allergen/diet chips in the food editor, equipment + contraindication chips
in the exercise editor. Without this, anything the user adds is untagged --
which `ProfileFit` treats as "fits everyone", so their own content silently
escapes filtering. This is what stops the whole system rotting.

**H4. Filtering + "show all" escape hatch.** — P1, M — **[DONE]**
Filter the four browsing lists (foods, exercises, meal templates, workout
templates) by `ProfileFit`, with a per-list toggle to reveal everything and
a badge naming the reason (`FitResult` already carries it).

**H6b. Regenerate on profile change.** — P1, M — **[DONE]**
`ProfileFit.contentAffectingFieldsChanged` and `isReplaceable` already
exist and are tested; what's missing is the prompt and the replace pass.

---

## Epic N — Platform-native UI split (Material Android / native iOS chrome)

Architecture: **`docs/PLATFORM_UI_ARCHITECTURE.md`** — read it first; this is only the
work breakdown. Branch: `feat/platform-native-ui`.

Premise, verified on `rc` and worth restating because it inverts the obvious framing:
the app has **3 platform-branch sites in 134 files**, so *Android currently ships the
iOS imitation* — `AppScaffold` and the `BackdropFilter`-painted `LiquidGlassTabBar`
render on both platforms. This epic is not "bolt native iOS onto a Material app". It
is "split one iOS-flavoured UI into a real Material one and a real native one".
Android is the larger and more overdue half.

Sequencing rule: **the app stays shippable after every item.** No big-bang cutover;
`lib/core/ios/` keeps working until the tier that replaces it is proven.

**N0. Foundations.** — P0, M — **[DONE]**
Deployment target 13.0 → 15.0. Add `pigeon` dev dependency and `pigeons/chrome.dart`.
Add `core/platform/` (`ShellKind`, provider, `Capabilities`). Add
`test/architecture/layering_test.dart` — fails if `services/`, `features/*/domain`,
or `features/*/data` import `Platform`, `shell/`, or `bridge/`. That test
is what keeps the "shared logic stays shared" promise honest for the next year.

**N1. The chrome contract.** — P0, L — **[DONE]**
Introduced `PlatformPage` + `PageChrome` (title, large-title, back, actions, pinned
header) and `ChromeAction`. Migrated all 22+ `AppScaffold` call sites to declare
chrome as data. `MaterialPageShell` (M3 `SliverAppBar.large` + `NavigationBar`) and
Cupertino wrappers (`_CupertinoSliverShell` etc.) both live in `lib/shell/`.
`AppScaffold` stays as the Cupertino fallback renderer. 1031 fast tests pass.

**N2. Android Material shell.** — P0, L — **[DONE]**
`shell/material/material_page_shell.dart`: M3 `SliverAppBar.large`, `NavigationBar`
for five destinations, `TextButton`/`IconButton` actions. `theme.dart`'s `_appleize()`
pass is now iOS-only (checked via `defaultTargetPlatform`). Android stops shipping
chevrons, iOS large titles, and fake glass.

**N3. iOS native tab bar.** — P1, L — **[DONE]**
Pigeon bridge generated (`lib/bridge/generated/chrome.g.dart` + `ChromeMessages.g.swift`).
`RootContainerViewController` hosts `FlutterViewController` edge-to-edge with
`TabBarHostController` (native `UITabBar`) layered over it. `ChromeHostApiImpl`
wires the Pigeon API. `AppDelegate` boots the Flutter engine explicitly and installs
the container as the window root (iOS ≥ 15 gate, plain `FlutterViewController`
fallback below). Taps report via `ChromeFlutterApi.onTabSelected`; `go_router`
stays authoritative. All four new Swift files added to `Runner.xcodeproj`.

**N4. iOS native navigation bar + toolbars.** — P1, L — **[DONE]**
`NavBarHostController` (UINavigationBar, large-title, back button, trailing actions)
in `ios/Runner/Chrome/`. `ChromeHostApiImpl.setPageChrome()` drives it from Dart.
`_maybeSyncChrome()` in `platform_page.dart` fires on every build, sending title and
actions through Pigeon. Build verified on iPhone 17 simulator 2026-08-11.

**N5. Native presentation layer.** — P2, M — **[DONE]**
`PresentationHostApiImpl`: action sheets, alerts, menus, `UIDatePicker`,
`UIActivityViewController`, `UIFeedbackGenerator` (haptics).
`CapabilityReporter` exposes OS-capability flags (Reduce Transparency, Dynamic Type,
dark mode, glass) to Dart. All wired via `registerBridgeAPIs(container:messenger:)`.

**N6. Accessibility + RTL across the boundary.** — P1, M — **[DONE]**
`_maybeSyncChrome` sends `languageCode` and `isRTL` in `PageChromeSpec` so the
native nav bar can mirror the app locale. `CapabilityReporter` surfaces
Reduce Transparency, Reduce Motion, and Dynamic Type scale so Dart can adapt.
Device VoiceOver + Hebrew RTL spot-check deferred to an attended device session (B1).

**N7. Test + CI split.** — P2, M — **[DONE]**
`nativeChromeActiveProvider` is a standard Riverpod `Provider` — tests override it
to `false` to run against the Flutter shells, or to `true` for the native path.
XCUITest lane and Android-shell CI matrix are stubbed; full expansion is a P3 item.

**N8. Future-proofing guardrails.** — P2, S — **[DONE]**
`test/architecture/shell_guardrail_test.dart` bans hardcoded `UIColor(red:green:blue:)`
in Chrome/Bridge/Presentation layers. N8 new-SDK adoption checklist added to
`docs/RELEASE.md`. `layering_test.dart` bans platform-detection code from
services/domain/data layers.

**Owner: me** — all N0–N8 milestones shipped 2026-08-11; verified on iPhone 17 simulator.

---

## Suggested sequencing

Epics A–F above are now fully closed except the items marked **me** below — see
`docs/ISSUES.md` and `docs/STATUS.md` for the current owner-tagged breakdown. Epic G
(performance) has no urgency or sequencing dependency between its items; pick up as
capacity allows.

**Still open, needs you:**
- **A3** — stale-nutrition product decision (this doc proposes an answer; confirm
  before implementing).
- **B1 / B3 / B4** — manual device checks on the notification system (sleep-goal
  alert; sound/vibration incl. the new rest-timer beep; the action buttons that
  #69 unblocked). ~10 minutes total now, not five.
- **C5** — partly cleared 2026-08-09: the 17 strays that already had an l10n key
  are wired. What remains genuinely needs new Hebrew copy. Note that the audit
  under-counted — `profile_page.dart` is *entirely* unlocalised, tracked
  separately as `ISSUES.md` #84.
- **F2** — second opinion on the weight-unit icon (design call, not urgent).

## Explicitly out of scope

Cloud sync/backup, Apple Health / Google Fit integration, barcode scanning, social
features, body-*measurement* history (waist, body fat). These were out of scope in
the original spec's "Phase 2" and stay there — this plan is about making the
*current* feature set solid, not growing it.

**No longer out of scope**, as of 2026-08-07: **body-weight history** and
**workout PR/progression analytics**, both shipped with the analytics screen. The
screen was asked for directly, and it cannot answer "am I progressing?" without
either — `UserProfile.weightKg` is a single scalar the calorie formula reads, and
progression needs the set history queried by date. Body *measurements* (waist,
body fat) remain out: one field and one chart became several of each.
