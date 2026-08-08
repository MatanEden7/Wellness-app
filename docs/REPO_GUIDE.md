# Wellness App - Repository Guide

> **Quick Start for Future Development**  
> This guide provides essential information for understanding and working with this codebase.

---

## Architecture Overview

### What This App Actually Is

This is a **Flutter wellness tracking app** backed by **in-memory lists that are
persisted as a JSON snapshot**, not a SQL database:

- **Storage**: Static lists in memory, saved to disk as one JSON document
- **Persistence**: Automatic — debounced snapshot writes on every mutation
- **State**: Riverpod for reactive state management
- **UI**: Material Design 3 with Hebrew/English RTL support
- **Features**: Meals, workouts, sleep tracking, calendar scheduling

### Storage Reality Check

**There is no SQL database.** The collections are still plain static lists in
[`lib/data/db/drift_database.dart`](lib/data/db/drift_database.dart) — no `.drift`
schema files, no queries, no migrations. Drift is no longer imported at all; the
dead `_openConnection()` has been removed.

What changed: those lists are now **durable**. `AppDatabase` takes a
[`SnapshotStore`](lib/data/db/drift_database.dart) and:

- `load()` restores the previous session's data before `runApp`
- every mutator funnels through `_touch()`, which notifies listeners *and*
  schedules a debounced (300ms) snapshot write
- `flush()` forces a write; `main.dart` calls it when the app is backgrounded,
  since iOS can suspend the process before the debounce fires
- writes are atomic (temp file + rename), so a crash mid-write cannot corrupt
  the snapshot
- a corrupt snapshot is moved aside to `.corrupt` and the app starts from the
  seeded catalog rather than failing to launch

Unit tests construct `AppDatabase()` with **no** store, which keeps them
filesystem-free; pass a `SnapshotStore` to exercise persistence (see
[`test/regression/persistence_test.dart`](test/regression/persistence_test.dart)).
Because the collections are static, tests that mutate data must call
`AppDatabase.resetForTesting()` in `setUp`.

---

## How Data Works

### Storage Architecture

```
User Action
    ↓
UI Layer (Riverpod widgets)
    ↓
Repository Layer (domain models)
    ↓
AppDatabase (static in-memory lists)
    ↓
_touch() → stream notify + debounced snapshot write
    ↓
SnapshotStore → wellness_data.json (atomic write)
```

### Data Collections

Located in [`lib/data/db/drift_database.dart`](lib/data/db/drift_database.dart):

| List | Content |
|------|---------|
| `_foods` | Food catalog with nutrition per unit |
| `_meals` | Meal entries with date (yyyymmdd format) |
| `_mealItems` | Individual food items in meals (with denormalized nutrition) |
| `_mealTemplates` | Reusable meal recipes |
| `_mealTemplateItems` | Food items in templates |
| `_exercises` | Exercise library (muscle groups, equipment) |
| `_workoutTemplates` | Workout routines |
| `_templateExercises` | Exercises in templates |
| `_workoutSessions` | Completed/in-progress workouts |
| `_setEntries` | Individual sets (reps/weight) |
| `_sleepEntries` | Sleep tracking data |
| `_bodyWeightEntries` | Weigh-ins, one per calendar day (upserted, not appended) |

### Reactive Updates

- **Not DB watchers**: each collection has a broadcast `StreamController`;
  mutators fire it via `_touch()`
- Repository `watchX()` methods map those signals into model streams
- Streams that dedupe use `listEquals`, which compares elements with the
  Freezed-generated deep `==`. **Do not** write a hand-rolled predicate that
  only compares list length or item counts — an earlier version did, and it
  silently swallowed amount edits and renames (and left day totals stale)
- Several screens still build their stream inside `build()`, which creates a
  new stream per rebuild and resets any `StreamBuilder` to its waiting state.
  Prefer a cached provider — see `exercisesStreamProvider` in
  [`lib/features/workouts/data/repositories.dart`](lib/features/workouts/data/repositories.dart)
  for the pattern to follow when touching one of these screens

---

## Food Amount System

### How Units Work

All unit conversion and macro math is centralized in two files — **do not duplicate this
logic anywhere else**:

- [`lib/features/meals/domain/food_serving_kind.dart`](lib/features/meals/domain/food_serving_kind.dart) —
  the `FoodServingKind` enum (`per100g`, `perGram`, `perMl`, `perOz`, `perCount`) and the
  parser (`FoodServingKindParser.fromLegacyUnit`) that maps a `FoodItem.unit` string (e.g.
  `"100g"`, `"g"`, `"oz"`, `"piece"`) to a kind.
- [`lib/features/meals/domain/food_nutrition_math.dart`](lib/features/meals/domain/food_nutrition_math.dart) —
  `FoodNutritionMath`, the single source of truth for:
  - `displayQuantity()` / `storedQuantity()` — converting between what the user types and
    what gets persisted on `MealItem.amount`
  - `displayUnitLabel()` — the unit suffix shown next to the amount field
  - `computeMacros()` / `computeMacrosFromDisplay()` — turning an amount into
    kcal/protein/carbs/fat

Every screen that shows or edits a food amount (meal editor, meal template editor,
calendar auto-created meals, notification-triggered meals) calls into `FoodNutritionMath`
rather than re-implementing unit math locally. Previously several of these screens had
their own copy-pasted `if (unit.contains('100'))` conversion helpers that had drifted out
of sync with each other and with the save-path calculation — that duplication has been
removed in favor of the shared module.

`MealItem.amount` always stores the **normalized** quantity, not necessarily what the user
typed:

#### 100g Foods (Most Common)

**Example**: Chicken Breast (`unit: "100g"`, `kcalPerUnit: 165` = kcal per 100g)

User enters: **150** (grams, shown in the UI)
- `storedQuantity` = `150 / 100` = `1.5` (portions of 100g) → this is what's saved as `MealItem.amount`
- `computeMacros`: `165 kcal × 1.5 = 247.5 kcal`

#### Per-gram / per-ml / per-oz Foods

**Example**: unit `"g"`, `"ml"`, or `"oz"` — `kcalPerUnit` is defined per single gram/ml/oz.

User enters an amount in that unit directly; display and stored quantities are the same
(no scaling). `oz` is **not** converted to/from grams — if `kcalPerUnit` is "per ounce",
the amount entered must already be in ounces. (An earlier version of this code divided the
amount by 28.35 here on top of a UI layer that was *already* passing ounces through
unchanged, silently under-calculating oz-based foods by ~5.7x. That double conversion has
been removed.)

#### Count-based Foods (`piece`, `slice`, `tbsp`, `serving`, or a literal size like `"30g"`)

**Example**: Banana (`unit: "piece"`, `kcalPerUnit: 105` = kcal per piece)

User enters: **2** (pieces)
- Display and stored quantity are both `2.0`
- `computeMacros`: `105 kcal × 2.0 = 210 kcal`

A unit written as a fixed size (e.g. `"30g"` for one labeled 30g serving) is also treated
as count-based: nutrition is per-block, and the amount is how many blocks — it is **not**
scaled the way the `"100g"` unit is.

### Nutrition Storage

**Denormalized on save** - nutrition is calculated once (via `FoodNutritionMath.computeMacros`)
and stored in `MealItem`:

```dart
MealItem {
  foodId: "abc123",
  amount: 1.5,      // normalized/stored quantity, see above
  kcal: 247.5,      // Snapshot at creation
  protein: 46.5,
  carbs: 0.0,
  fat: 5.4
}
```

**Important**: If you edit a `FoodItem`, existing `MealItem` records keep their old nutrition values.

---

## Analytics

`lib/features/analytics/` is layered deliberately, and the layering is the part
worth preserving:

```
domain/     pure Dart -- no Flutter, no DB. Ranges and bucketing, series maths,
            goal scoring, e1RM + plateau detection, insight rules.
data/       AnalyticsRepository (the ONLY thing here that touches AppDatabase)
            and the providers.
ui/         the page, seven section cards, and four CustomPainter primitives.
```

Four rules this feature holds to:

1. **One provider, one pass.** Every section reads a slice of a single
   `AnalyticsView` from `analyticsViewProvider(range)`. Sections must never
   query anything themselves — seven per-section streams would re-run the whole
   aggregation seven times a frame, which is the `build()`-time stream pattern
   listed under Known Issues.
2. **No per-day queries.** `watchMealsByDate` is one day and
   `getMealItemsByMealId` is one meal; calling either in a loop over 365 days
   re-scans the item list every iteration. `AnalyticsRepository` indexes once
   and joins in memory.
3. **In-progress sessions are excluded from every aggregate.**
   `WorkoutSession.endedAt == null` means "still running". One that leaks
   through logs as a zero-volume training day and hands out a free streak day.
4. **Null in a series means *no data*, never zero.** An unlogged day must not
   drag an average toward the floor, and a chart must draw a gap rather than a
   line through the axis.

Two domain decisions that look like bugs if you don't know them:

- **Strength plots estimated 1RM (Epley), not the top-set weight.** Adding a rep
  at the same load is progress, and a raw-weight line renders that flat — the
  exact false "I'm stuck" reading the plateau strip is meant to be the only
  source of.
- **A night of sleep is attributed to the day it *ended* on.** Attributing by
  start scores a 23:30 bedtime against the previous day.

Body weight is a real collection (`_bodyWeightEntries`), distinct from
`UserProfile.weightKg` — that scalar is an input to the calorie formulas and
cannot answer "am I trending down?". Entries are **upserted per calendar day**:
weight swings a kilo across a day on water, so two readings are a correction,
not two data points.

Charts are four hand-written `CustomPainter`s
([`ui/charts/`](lib/features/analytics/ui/charts/)) rather than a package. The
app has 9 user-selectable themes plus custom section colours, so a package's own
theming layer would be a second source of truth for colour.

---

## Key Files & Structure

### Entry Points

- **[`lib/main.dart`](lib/main.dart)** - App initialization, provider overrides, seed data
- **[`lib/app.dart`](lib/app.dart)** - MaterialApp, routing, localization, theme

### Core Systems

- **[`lib/data/db/drift_database.dart`](lib/data/db/drift_database.dart)** - In-memory storage (18 static lists)
- **[`lib/routing/routes.dart`](lib/routing/routes.dart)** - GoRouter configuration

### Feature Modules

Each feature follows this structure:

```
lib/features/{meals|workouts|sleep|calendar}/
├── domain/
│   └── models.dart          # Freezed domain models
├── data/
│   └── repositories.dart    # Data access layer
└── ui/
    └── *_page.dart          # UI pages
```

**Key domain models**:
- Analytics: [`lib/features/analytics/domain/`](lib/features/analytics/domain/) — see
  "Analytics" below. Its own plain value objects (`analytics_input.dart`), not the
  freezed models, so the whole layer stays free of Flutter and the database
- Meals: [`lib/features/meals/domain/models.dart`](lib/features/meals/domain/models.dart) - `FoodItem`, `Meal`, `MealItem`, `MealTemplate`
  - Unit/macro math lives separately in `domain/food_serving_kind.dart` and
    `domain/food_nutrition_math.dart` (see "Food Amount System" above) — not in `models.dart`
- Workouts: [`lib/features/workouts/domain/models.dart`](lib/features/workouts/domain/models.dart) - `Exercise`, `WorkoutTemplate`, `WorkoutSession`, `SetEntry`
- Sleep: [`lib/features/sleep/domain/models.dart`](lib/features/sleep/domain/models.dart) - `SleepEntry`
- Calendar: [`lib/features/calendar/domain/models.dart`](lib/features/calendar/domain/models.dart) - `ScheduledEvent`, `CalendarState`

### Services

- **[`lib/services/preferences_service.dart`](lib/services/preferences_service.dart)** - User preferences (nutrition goals, dashboard settings)
- **[`lib/services/theme_service.dart`](lib/services/theme_service.dart)** - Theme switching (light/dark/gold + 6 more)
- **[`lib/services/language_service.dart`](lib/services/language_service.dart)** - i18n (English/Hebrew)
- **[`lib/services/calendar_service.dart`](lib/features/calendar/data/calendar_service.dart)** - Dual-source calendar (SharedPreferences + DB)
- **[`lib/services/export_import_service.dart`](lib/services/export_import_service.dart)** - JSON backup/restore
- **[`lib/services/notification_service.dart`](lib/services/notification_service.dart)** - Local notifications: iOS action categories, scheduling, immediate alerts, the rest-timer alert. The **only** `NotificationService` — a duplicate in `lib/core/notifications.dart` was removed in #69, because its separate `initialize()` on the singleton plugin silently nulled this one's tap handler.
- **[`lib/services/notification_action_handler.dart`](lib/services/notification_action_handler.dart)** - What each notification tap and action button does. Reached only for actions declared `foreground` in `NotificationService.notificationCategories`; anything else is delivered by iOS to a background isolate that cannot act.
- **[`lib/services/workout_programming.dart`](lib/services/workout_programming.dart)** - How a session is programmed: rep scheme by goal, rest by mechanic (compound vs isolation), bodyweight-relative starting loads adjusted for sex/experience/age, weekly volume landmarks, and the duration estimator that *derives* how many exercises fit a 45-minute session. Pure functions, no I/O — this is where the domain judgement lives and it is verifiable without constructing an app.
- **[`lib/services/workout_template_generator.dart`](lib/services/workout_template_generator.dart)** - Applies the above to the seeded catalog. Compounds are selected by `movementPattern`, isolation by `primaryMuscle` — a curl and a lateral raise are both `MovementPattern.isolation` and only the muscle says which belongs on a pull day. Loaded lifts sort ahead of bodyweight ones, because the progression rule on every template is "add 2.5kg".
- **[`lib/services/notification_preferences_service.dart`](lib/services/notification_preferences_service.dart)** - Per-category switches, lead times, quiet hours, sound/vibration. Every schedule-affecting setter fires `onScheduleAffectingChange`, wired in `main.dart` to `CalendarNotifier.rescheduleAllNotifications()` so a toggle also re-issues reminders already sitting in the OS queue.

### Unused/Dead Code

All removed. `nutrition_unit_converter.dart` and `food_data_validator.dart` (parallel,
never-imported nutrition logic) went first; since then `SeedService` + its
`food_starter.json` asset (dead — the `AppDatabase` constructor already seeds, so its
"already seeded" guard always returned early, and its 8 hardcoded exercises were a stale
duplicate of the 16 real ones), `main_simple.dart`, three committed `.bak` files, the
`isSetupCompletedProvider`, and the dead Drift `_openConnection()` have all been deleted.

`FoodNutritionMath` remains the only nutrition math implementation.

---

## Known Issues & Limitations

Most of what used to be listed here has been fixed — see
[`ISSUES.md`](ISSUES.md) for the full audit and what remains.

### Still Open

1. **Stale Nutrition**
   - `MealItem` nutrition is denormalized (a snapshot taken at save time)
   - Editing a `FoodItem` does not update existing meal items, and there is no
     "recalculate history" action

2. **Setup Engine YAML**
   - [`assets/data/setup_engine_spec.yaml`](assets/data/setup_engine_spec.yaml)
     is no longer loaded (it was parsed into a field nothing read), but every
     formula is still hardcoded in `SetupEngineService`. The asset is now
     documentation, not configuration.

3. **Meals have no time of day**
   - `MealData` stores only a `date` int. The calendar infers a time from the
     row's `createdAt`, falling back to keyword matching on the meal name.
     A real `loggedAt` field would need a UI to set it.

4. **Streams built inside `build()`**
   - ~15 screens still call `ref.watch(repo).watchX()` in `build()`, creating a
     new stream per rebuild. Fixed for exercises via `exercisesStreamProvider`;
     the same treatment is worth applying as other screens are touched.

5. **No profile editing UI**
   - The profile now saves and loads correctly, but nothing surfaces it after
     onboarding.

### Recently Fixed

Persistence, profile save/load, export/import round-trip, notification action
wiring, referential integrity, recurring-event actions, and the fabricated
"planned" workouts. Each has regression coverage in
[`test/regression/`](test/regression/).

---

## Development Workflow

### Setup

**Use Flutter 3.24.5** — the version in [`.fvmrc`](.fvmrc) and CI. Newer SDKs pin a
different `intl` than `flutter_localizations` requires here and will fail to resolve.
On macOS, make sure `/opt/homebrew/bin` is on `PATH` so `pod` is visible, or iOS
integration test runs fail with "CocoaPods not installed".

```bash
# Install dependencies
flutter pub get

# Generate localization files
flutter gen-l10n

# Generate Freezed models (if you modify domain models)
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run -d "iPhone 15 Simulator"
```

### Making Changes

#### Adding a New Food Unit

1. Add the new unit string to `FoodServingKindParser.fromLegacyUnit()` (and, if it should be
   selectable in the catalog dropdown list, `FoodServingUnits`) in
   [`lib/features/meals/domain/food_serving_kind.dart`](lib/features/meals/domain/food_serving_kind.dart)
2. If it needs display/stored scaling different from a straight passthrough (like `100g`
   does), add a case to `displayQuantity()`, `storedQuantity()`, and `displayUnitLabel()` in
   [`lib/features/meals/domain/food_nutrition_math.dart`](lib/features/meals/domain/food_nutrition_math.dart)
3. Do **not** add unit-conversion logic anywhere else — every screen (meal editor, meal
   template editor, calendar, notifications) reads from `FoodNutritionMath`, so a change
   here automatically applies everywhere and preview/save stay in sync

#### Adding a New Feature

1. Create feature folder: `lib/features/my_feature/`
2. Add domain models (Freezed): `domain/models.dart`
3. Add repository: `data/repositories.dart`
4. Add static list to `drift_database.dart`
5. Add UI pages: `ui/my_feature_page.dart`
6. Add route in `routes.dart`
7. Add localization strings in `lib/l10n/app_en.arb` and `app_he.arb`

#### Modifying Storage

If you want **real persistence**, you need to:
1. Keep the Drift imports (already there)
2. Create `.drift` schema files
3. Add `@DriftDatabase` annotation to `AppDatabase`
4. Wire up `_openConnection()` 
5. Replace static lists with actual DAO methods
6. Run code generation: `flutter packages pub run build_runner build`

### Testing

```bash
# Fast suite: pure logic + repository/service regressions, no device needed
flutter test test/

# Real-device suite (needs a booted simulator) -- this is what CI runs
flutter test integration_test/sanity/<name>_test.dart -d <udid>
flutter test integration_test/regression/<name>_test.dart -d <udid>

# Check for issues -- lib/ is expected to be free of warnings and errors
flutter analyze
```

`integration_test/e2e/` is deliberately **not** run by CI; treat it as exploratory.

Never use `pumpAndSettle()` in this app: several screens show an indeterminate
`CircularProgressIndicator`, whose animation never settles, so it hangs until timeout.
Use the bounded `settle()` helper in
[`integration_test/support/app_launcher.dart`](integration_test/support/app_launcher.dart).

### Data Management

**During Development**:
- Data persists across restarts in `wellness_data.json` in the app documents directory
- Use hot reload freely - data stays in memory and is written back on change
- To start clean, delete that file (or reinstall the app on the simulator)

**For Testing**:
- Use Settings → Export Data to save state
- Use Settings → Import Data to restore
- Exported JSON is human-readable - you can edit it

---

## Localization (i18n)

### Languages Supported

- **English** (`en`) - Left-to-right
- **Hebrew** (`he`) - Right-to-left (RTL)

### Translation Files

- [`lib/l10n/app_en.arb`](lib/l10n/app_en.arb) - 200+ English strings
- [`lib/l10n/app_he.arb`](lib/l10n/app_he.arb) - 200+ Hebrew translations

### Adding Translations

1. Add key to both `.arb` files
2. Run: `flutter gen-l10n`
3. Use in code: `AppLocalizations.of(context)!.myKey`

### RTL Adaptations

- Text direction automatic based on locale
- UI elements mirror for Hebrew (back buttons, navigation)
- Numbers stay LTR for readability
- Calendar weekends: Friday/Saturday (Israeli convention)

---

## Future Work & Migration Path

### Recommended Improvements

1. **Real Database Migration**
   - Create `.drift` schema files
   - Implement proper Drift DAOs
   - Add migrations for schema updates
   - Wire up foreign key constraints

2. **Notification System** — *done; see `ISSUES.md` #4/#7/#58/#59/#69.* The
   handler is wired in `app.dart`, sound/vibration prefs are applied and
   re-applied to pending reminders, recurring occurrences are expanded under
   iOS's 64-pending cap, and onboarding-generated schedules notify. What
   remains is device verification only (ROADMAP B1/B3/B4).

3. **User Profile**
   - Fix save/load format
   - Load profile on app start
   - Validate setup engine YAML usage

4. **Data Integrity**
   - Add cascade deletes
   - Validate foreign keys on insert
   - Fix `clearAllData()` implementation
   - Include templates in export

5. **Remove Dead Code**
   - ~~Delete `NutritionUnitConverter`~~ done
   - ~~Delete `FoodDataValidator`~~ done
   - Clean up unused imports

### If Starting Over

**Keep**:
- Domain models (Freezed models are solid)
- UI components and design system
- Localization infrastructure
- Riverpod provider structure

**Replace**:
- In-memory lists → Real Drift database
- Polling streams → DB watchers
- Manual export/import → Auto-sync/backup

---

## Quick Reference

### File Size Estimates

- Total Dart files: ~69 files
- Lines of code: ~15,000+ (including generated)
- Assets: 30 starter foods JSON, setup YAML

### Tech Stack

- **Flutter**: 3.22.0+
- **Dart**: 3.4.0+
- **Riverpod**: 2.4.9
- **GoRouter**: 12.1.3
- **Drift**: 2.14.1 (imported but unused for real DB)
- **Freezed**: 2.4.6

### Common Commands

```bash
# Clean build
flutter clean && flutter pub get

# Regenerate everything
flutter gen-l10n && flutter packages pub run build_runner build --delete-conflicting-outputs

# Run on specific device
flutter devices
flutter run -d <device-id>

# Build release
flutter build ios --release
flutter build apk --release
```

---

## Questions & Troubleshooting

### "Where is my data stored?"

In static lists in memory. Export to JSON to save permanently.

### "Why does Drift database.dart not use real SQL?"

Historical artifact - started with Drift, switched to in-memory for simplicity, kept the file structure.

### "Can I switch to a real database?"

Yes, but requires significant refactoring. See "Future Work" section above.

### "Why is nutrition wrong after I save a meal?"

**Fixed.** All amount/unit math now goes through `FoodNutritionMath` (see "Food Amount
System" above), which treats `100g`-unit amounts as portions (not grams) and treats
`oz`/`ml`/`g`-unit amounts as direct passthrough (not a unit conversion). If you see wrong
numbers again, check that the screen in question is calling into `FoodNutritionMath`
instead of doing its own `unit.contains(...)` math.

### "The generated workout looks wrong"

Three rules decide what lands in a session, and each has its own failure look:

1. **Two near-duplicate lifts** (Bench Press *and* Push-ups) means selection
   went depth-first within a pattern instead of breadth-first across patterns.
2. **No isolation work at all** means accessories were selected by pattern;
   they must be selected by muscle.
3. **A session over an hour** means exercise count was fixed rather than
   derived from `WorkoutProgramming.exerciseBudget`, or rest is not being
   counted.

A prescribed weight of `null` is usually correct: load is only ever given to
`kg`-based exercises, and any untagged exercise resolves to `LoadClass.none`.

### "Notifications don't work"

Scheduling and the action handler both work as of #69. Two things to check first,
because both were real bugs and both are silent:

1. **A button renders but does nothing** — the action is probably missing
   `DarwinNotificationActionOption.foreground` in
   `NotificationService.notificationCategories`. iOS picks the destination isolate
   from that option alone, never from whether the app is running, so an action
   without it goes to the background isolate and is dropped.
2. **Nothing responds at all any more, mid-session** — something called
   `FlutterLocalNotificationsPlugin().initialize()` a second time. It is a
   singleton, and a re-initialize without `onDidReceiveNotificationResponse`
   nulls the callback while leaving the buttons on screen.

### "My changes disappeared after restarting"

Stale — persistence has worked since ISSUES #1. The snapshot is written
debounced and flushed when the app backgrounds. If data really is lost, check
`AppDatabase.load()` and the `_backfillExerciseMetadata` path, since
`_applySnapshot` *replaces* rather than merges.

---

**Last Updated**: August 2026  
**For Issues**: Check code comments and Known Issues section above  
**Documentation**: See also [`README.md`](../README.md) and [`WELLNESS_APP_SPEC.md`](WELLNESS_APP_SPEC.md)
