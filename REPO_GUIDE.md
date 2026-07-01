# Wellness App - Repository Guide

> **Quick Start for Future Development**  
> This guide provides essential information for understanding and working with this codebase.

---

## Architecture Overview

### What This App Actually Is

This is a **Flutter wellness tracking app** using **in-memory data storage**, not a traditional database application:

- **Storage**: Static lists in memory (not SQLite/Drift despite imports)
- **Persistence**: JSON export/import only
- **State**: Riverpod for reactive state management
- **UI**: Material Design 3 with Hebrew/English RTL support
- **Features**: Meals, workouts, sleep tracking, calendar scheduling

### Important Reality Check

**The app uses in-memory lists, NOT a real database:**
- Data stored in static lists in [`lib/data/db/drift_database.dart`](lib/data/db/drift_database.dart)
- No `.drift` schema files, no SQL queries, no migrations
- **Data is lost when app closes** unless exported to JSON
- The `wellness_app.db` path in `main.dart` is unused

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
[NO PERSISTENCE - Data lost on app restart]
    ↓
Manual Export/Import (JSON files)
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

### Reactive Updates

- **Not DB watchers**: Streams use polling (500ms intervals)
- Manual `StreamController.add()` triggers in some places
- UI calls `ref.invalidate()` to force refreshes

---

## Food Amount System

### How Units Work

The app has a **dual-representation system** for food amounts:

#### 100g Foods (Most Common)

**Example**: Chicken Breast (`unit: "100g"`, `kcalPerUnit: 165`)

User enters: **150g**
- **UI stores**: `amount = 1.5` (number of 100g portions)
- **Preview calculation**: `165 kcal × 1.5 = 247.5 kcal` ✓
- **Saved calculation**: `165 kcal × 1.5 = 247.5 kcal` ✓ (fixed)

**Code locations**:
- UI conversion: [`lib/features/meals/ui/meal_editor_page.dart:552-557`](lib/features/meals/ui/meal_editor_page.dart)
- Save calculation: [`lib/features/meals/domain/models.dart:111-113`](lib/features/meals/domain/models.dart)

#### Piece Foods

**Example**: Banana (`unit: "piece"`, `kcalPerUnit: 105`)

User enters: **2** (pieces)
- **Stored**: `amount = 2.0`
- **Calculation**: `105 kcal × 2.0 = 210 kcal`

#### Other Units

- `g` (per gram): Amount in grams, multiply directly
- `ml` (per ml): Amount in ml, multiply directly  
- `tbsp`, `slice`, etc.: Amount as count, multiply directly

### Nutrition Storage

**Denormalized on save** - nutrition is calculated once and stored in `MealItem`:

```dart
MealItem {
  foodId: "abc123",
  amount: 1.5,
  kcal: 247.5,      // Snapshot at creation
  protein: 46.5,
  carbs: 0.0,
  fat: 5.4
}
```

**Important**: If you edit a `FoodItem`, existing `MealItem` records keep their old nutrition values.

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
- Meals: [`lib/features/meals/domain/models.dart`](lib/features/meals/domain/models.dart) - `FoodItem`, `Meal`, `MealItem`, `MealTemplate`
- Workouts: [`lib/features/workouts/domain/models.dart`](lib/features/workouts/domain/models.dart) - `Exercise`, `WorkoutTemplate`, `WorkoutSession`, `SetEntry`
- Sleep: [`lib/features/sleep/domain/models.dart`](lib/features/sleep/domain/models.dart) - `SleepEntry`
- Calendar: [`lib/features/calendar/domain/models.dart`](lib/features/calendar/domain/models.dart) - `ScheduledEvent`, `CalendarState`

### Services

- **[`lib/services/preferences_service.dart`](lib/services/preferences_service.dart)** - User preferences (nutrition goals, dashboard settings)
- **[`lib/services/theme_service.dart`](lib/services/theme_service.dart)** - Theme switching (light/dark/gold + 6 more)
- **[`lib/services/language_service.dart`](lib/services/language_service.dart)** - i18n (English/Hebrew)
- **[`lib/services/calendar_service.dart`](lib/features/calendar/data/calendar_service.dart)** - Dual-source calendar (SharedPreferences + DB)
- **[`lib/services/export_import_service.dart`](lib/services/export_import_service.dart)** - JSON backup/restore
- **[`lib/services/notification_service.dart`](lib/services/notification_service.dart)** - Local notifications (partially wired)

### Unused/Dead Code

These exist but are **not called anywhere**:
- **[`lib/services/nutrition_unit_converter.dart`](lib/services/nutrition_unit_converter.dart)** - Parallel nutrition calculation logic (never imported)
- **[`lib/services/food_data_validator.dart`](lib/services/food_data_validator.dart)** - Validation rules that conflict with actual data

---

## Known Issues & Limitations

### Critical Issues

1. **No Real Persistence**
   - Data lost on app restart
   - Must use Settings → Export Data regularly
   - Import does NOT clear existing data (appends)

2. **Notification System Incomplete**
   - `NotificationActionHandler` exists but never wired in `main.dart`
   - Taps on notifications do nothing
   - Sound/vibration prefs stored but not applied
   - Recurring events only get one notification (base event)

3. **User Profile Broken**
   - `UserProfileService.saveProfile()` uses invalid format
   - `loadProfile()` never called anywhere
   - Profile lost after onboarding

4. **No Referential Integrity**
   - Deleting a `FoodItem` doesn't delete its `MealItem` references
   - Deleting an `Exercise` doesn't clean up `SetEntry` orphans
   - No validation on foreign keys

### Medium Issues

5. **Calendar Onboarding Gap**
   - Only generates workout schedules during setup
   - No meal or sleep events scheduled
   - Generated schedules bypass notification scheduling

6. **Data Export Gaps**
   - Meal templates not included in export JSON
   - `clearAllData()` is empty stub - import duplicates data

7. **Stale Nutrition**
   - `MealItem` nutrition is denormalized (snapshot)
   - Editing a `FoodItem` doesn't update existing meal items

8. **Setup Engine YAML**
   - [`assets/data/setup_engine_spec.yaml`](assets/data/setup_engine_spec.yaml) loaded but never used
   - All formulas hardcoded in `SetupEngineService`

---

## Development Workflow

### Setup

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

1. Update `_calculateNutritionForAmount` in [`lib/features/meals/domain/models.dart`](lib/features/meals/domain/models.dart)
2. Update `_toStoredAmount` / `_toDisplayAmount` in [`lib/features/meals/ui/meal_editor_page.dart`](lib/features/meals/ui/meal_editor_page.dart)
3. Ensure preview and save use the same calculation

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
# Run tests (if you add any)
flutter test

# Check for issues
flutter analyze
```

### Data Management

**During Development**:
- Data persists only while app is running
- Use hot reload freely - data stays in memory
- Closing the app = all data lost

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

2. **Fix Notification System**
   - Wire `NotificationActionHandler` in `main.dart`
   - Apply sound/vibration preferences
   - Schedule recurring event instances
   - Fix onboarding schedule notifications

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
   - Delete `NutritionUnitConverter`
   - Delete `FoodDataValidator`
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

**Fixed in latest version.** Make sure you have the corrected `_calculateNutritionForAmount` that treats 100g unit amounts as portions, not grams.

### "Notifications don't work"

Scheduling works, but action handler isn't wired up. See "Known Issues" section.

### "My changes disappeared after restarting"

Expected behavior - use Export Data before closing the app.

---

**Last Updated**: June 2026  
**For Issues**: Check code comments and Known Issues section above  
**Documentation**: See also [`README.md`](README.md) and [`WELLNESS_APP_SPEC.md`](WELLNESS_APP_SPEC.md)
