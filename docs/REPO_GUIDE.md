# Wellness App — Repository Guide

> Native SwiftUI / SwiftData iOS app. Zero third-party dependencies.

---

## Architecture Overview

A **100% Swift** wellness tracking app: meals, workouts, sleep, calendar
scheduling, analytics, widgets, and Live Activities. The Flutter codebase this
replaced lives in git history on `rc` and `main`.

| Layer | Where | What |
|---|---|---|
| Models | `WellnessModels` | Value types, enums, IDs — Foundation only |
| Domain | `WellnessDomain` | Pure logic: nutrition math, setup engine, generators, rest prescription |
| Catalog | `WellnessCatalog` | Starter foods + exercises as JSON resources |
| Persistence | `WellnessPersistence` | SwiftData `@Model` classes + store protocols |
| Services | `WellnessServices` | Backup, notifications, preferences, widget snapshots, App Intents |
| Stores | `WellnessStores` | `@Observable @MainActor` feature stores wrapping persistence |
| UI | `WellnessUI` | SwiftUI screens, app shell, localization (915 keys × en/he) |

All seven modules live in one SPM local package:
`Packages/WellnessKit/Package.swift`.

### Targets

| Target | Bundle ID | What |
|---|---|---|
| WellnessApp | `com.matan.wellnessx123` | Main app (`App/`, `WellnessApp.xcodeproj`) |
| WellnessWidgetsExtension | `com.matan.wellnessx123.widgets` | WidgetKit extension (`Widgets/`) |

Both share the App Group `group.com.matan.wellnessx123` for widget data.

---

## Storage

**SwiftData** with `@Model` classes in `WellnessPersistence`. The container is
created by `WellnessContainer.create()` — one call in the app entry point.
Tests use `ModelConfiguration(isStoredInMemoryOnly: true)`.

### Data Models

| Model | Content |
|---|---|
| `SDFood` | Food catalog with nutrition per unit |
| `SDMeal` / `SDMealItem` | Meal entries with denormalized nutrition |
| `SDMealTemplate` / `SDMealTemplateItem` | Reusable meal recipes |
| `SDExercise` | Exercise library (muscle, equipment) |
| `SDWorkoutTemplate` / `SDTemplateExercise` | Workout routines |
| `SDWorkoutSession` / `SDSetEntry` | Completed/in-progress workouts |
| `SDSleepEntry` | Sleep tracking |
| `SDBodyWeight` | Weigh-ins (upserted per calendar day) |
| `SDScheduledEvent` | Calendar events |
| `SDUserProfile` | Physical stats, goals, preferences |

### Store Protocols

Each domain area has a protocol (`FoodStore`, `MealStore`, etc.) that the
`SwiftDataStore` actor conforms to. Feature stores in `WellnessStores` wrap
these protocols, providing `@Observable` state for SwiftUI.

---

## Nutrition Math

All unit conversion and macro math is in `WellnessDomain`:

- `FoodServingKind` — the enum (`per100g`, `perGram`, `perMl`, `perOz`, `perCount`)
- `FoodServingKindParser` — maps a unit string to a kind
- `FoodNutritionMath` — the single source of truth for display/stored quantity
  conversion and macro computation

---

## Content Language

English + Hebrew. **Content is written in one language, once, and never
re-resolved.** Chrome follows the current language; content does not.

| Kind | Example | Language decided |
|---|---|---|
| Content (stored rows) | food/exercise names, template names | once, at seed or generation time |
| Chrome (rendered labels) | buttons, enum labels, unit strings | every build, from current locale |

---

## Localization

915 keys × 2 languages (en, he) in a single String Catalog:
`WellnessUI/Resources/Localizable.xcstrings`.

Access via `L10n.tr("key")` or SwiftUI `Text("key")` within the WellnessUI module.

Parity test in `WellnessUITests/LocalizationParityTests.swift` asserts:
- Every key has both en and he
- No empty values
- Format specifiers match between languages
- Key count is 915

---

## Widgets & Live Activities

Nine widgets in `Widgets/`:

| Widget | Family | Content |
|---|---|---|
| TodayWidget | small, medium | Calorie ring + macro chips |
| NextUpWidget | medium | Next 3 calendar events |
| WeekWidget | large | 7-day adherence grid |
| StreakWidget | small | Workout streak count |
| WorkoutLiveActivity | Dynamic Island + banner | Current exercise, set count, rest timer |
| SleepLiveActivity | Dynamic Island + banner | Elapsed sleep time |
| LockScreenWidgets | accessoryCircular/Rectangular/Inline | Calorie gauge, next event, streak |

Data shared via `WidgetSnapshotStore` (UserDefaults in the app group).

---

## App Intents

Four Siri Shortcuts (`WellnessIntents.swift`): Log Meal, Start Workout, Start
Sleep Timer, Log Body Weight. English + Hebrew phrases.

---

## Key Files

| Path | Purpose |
|---|---|
| `App/WellnessApp.swift` | `@main` entry point |
| `App/RootView.swift` | SwiftData container setup |
| `App/AppRouter.swift` | Navigation routing |
| `App/Wellness.entitlements` | App Group entitlement |
| `Packages/WellnessKit/` | All seven SPM modules |
| `Widgets/` | WidgetKit extension (9 widgets) |
| `parity/` | Migration evidence: golden corpus, test inventory |
| `docs/` | Project tracking (see `CLAUDE.md`) |

---

## Development

### Build

```bash
# SPM tests (no simulator needed)
cd Packages/WellnessKit && swift test

# Xcode build
xcodebuild -project WellnessApp.xcodeproj -scheme WellnessApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# Widget extension
xcodebuild -project WellnessApp.xcodeproj -target WellnessWidgetsExtension \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

### Tech Stack

- **Swift 6.2** with strict concurrency (`Sendable` throughout)
- **SwiftUI** with Liquid Glass (iOS 26+)
- **SwiftData** for persistence
- **WidgetKit** + **ActivityKit** for widgets and Live Activities
- **AppIntents** for Siri Shortcuts
- Zero third-party packages
- Team: `R6NSBVKVXV`, deployment target iOS 26.0

---

**Last Updated**: August 2026
