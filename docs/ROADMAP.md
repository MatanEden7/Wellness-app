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

**B2. Badge count is a documented no-op.** — P2, S — **[DONE]**
Turned out already resolved: `updateBadgeCount()` no longer exists in the code and no
settings copy references it — nothing dead to remove or wire.

**B3. Sound/vibration prefs need one more device check.** — P2, S
Fixed in code (per-combination Android channels, `presentSound` on iOS) but I only
verified via `flutter analyze` + unit tests, not by hearing/feeling a real
notification. Same category as B1 — quick manual pass, not a code question.

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

**G4. Cache aggregations.** — P3, S
Daily nutrition totals, workout summaries recomputed on every watch instead of cached
and invalidated on mutation.

**G5. Debounce search.** — P3, XS
Text-input-driven filtering (food catalog, exercise library) has no debounce; every
keystroke re-filters immediately.

**G6. Lazy-load non-critical services at startup.** — P3, XS
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

**H3. Tag editors in the food and exercise UI.** — P1, M
Allergen/diet chips in the food editor, equipment + contraindication chips
in the exercise editor. Without this, anything the user adds is untagged --
which `ProfileFit` treats as "fits everyone", so their own content silently
escapes filtering. This is what stops the whole system rotting.

**H4. Filtering + "show all" escape hatch.** — P1, M
Filter the four browsing lists (foods, exercises, meal templates, workout
templates) by `ProfileFit`, with a per-list toggle to reveal everything and
a badge naming the reason (`FitResult` already carries it).

**H6b. Regenerate on profile change.** — P1, M
`ProfileFit.contentAffectingFieldsChanged` and `isReplaceable` already
exist and are tested; what's missing is the prompt and the replace pass.

---

## Suggested sequencing

Epics A–F above are now fully closed except the items marked **me** below — see
`docs/ISSUES.md` and `docs/STATUS.md` for the current owner-tagged breakdown. Epic G
(performance) has no urgency or sequencing dependency between its items; pick up as
capacity allows.

**Still open, needs you:**
- **A3** — stale-nutrition product decision (this doc proposes an answer; confirm
  before implementing).
- **B1 / B3** — five-minute manual device checks (sleep-goal notification; sound/
  vibration).
- **C5** — remaining Hebrew strings need a real translator pass, not more code.
- **F2** — second opinion on the weight-unit icon (design call, not urgent).

## Explicitly out of scope

Cloud sync/backup, Apple Health / Google Fit integration, barcode scanning, social
features, weight/body-measurement history as a new tracked entity, workout PR/
progression analytics. All were out of scope in the original spec's "Phase 2" and
stay there — this plan is about making the *current* feature set solid, not growing
it.
