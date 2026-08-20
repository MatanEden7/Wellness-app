# Swift Migration Plan — Flutter → 100% native SwiftUI, Liquid Glass, WidgetKit

Branch: `swift`. Design document. **No implementation until §14's gate list is agreed.**

This plan supersedes `docs/PLATFORM_UI_ARCHITECTURE.md` (Epic N — "Flutter core,
native iOS chrome"). That document's premise was *keep the Dart, bridge the
chrome*. This one deletes the Dart. Both cannot be true; Epic N is marked
superseded in `docs/ROADMAP.md` when Phase 0 lands, not before — it stays the
active design while the Flutter app is the shipping app.

---

## 0. TL;DR

| | |
|---|---|
| **What** | Clean-room rewrite as a single-target native iOS app: Swift 6.2, SwiftUI, SwiftData, Swift Charts, WidgetKit, App Intents. Zero third-party dependencies. |
| **Minimum OS** | **iOS 26.0** (see §2 — this is what "Liquid Glass" actually requires; iOS 27 is addressed there too) |
| **Android** | **Dropped.** Not a side effect — a decision. §15 Q1. |
| **Data** | User data survives. The JSON snapshot and the export/import file format are both preserved byte-for-byte as an import contract. |
| **Proof of "we missed nothing"** | A golden-corpus parity harness (§9.1) generated from the *current Dart* before any Swift is written, replayed against Swift. Plus a row-by-row disposition of all 1,172 existing tests (§9.2). |
| **Shrinkage** | ~51,000 hand-written Dart → ~30,000 Swift, because ~61% of the current codebase is UI chrome the system supplies for free (§1). |
| **Shape of the work** | 10 phases, each with a hard exit gate. Phases 0–4 produce no UI at all and are where the risk actually lives. |
| **Not in this plan** | iPad, watchOS, HealthKit, CloudKit sync. All become *cheap* after this; none are scoped here. §15 Q19–Q21. |

---

## 1. Where the codebase actually is — measured, not assumed

Counted on `swift` at branch point (`rc` @ f820b0a), 2026-08-20.

| Fact | Number | How counted |
|---|---|---|
| Dart files in `lib/` | 156 | `find lib -name '*.dart'` |
| Total Dart LOC | 67,880 | all files |
| **Hand-written Dart LOC** | **50,963** | excluding `*.g.dart`, `*.freezed.dart`, `l10n/app_localizations*` |
| Generated Dart LOC | 16,917 | 10 files — freezed, json_serializable, l10n, pigeon |
| Feature UI (`features/*/ui/`) | 48 files / 22,120 LOC | |
| Chrome kit (`core/ios`, `core/design`, `shell/`, `bridge/`, `core/platform`) | 6,392 LOC | |
| `core/theme.dart` + `core/widgets.dart` | 2,346 LOC | |
| Domain + data (hand-written) | 6,116 LOC | |
| Services | 25 files / 7,905 LOC | |
| Storage + seed catalogs | 5,912 LOC | `data/db/` + `data/catalog/` |
| Routes | 27 | `routing/routes.dart` |
| Localized keys | 915 × 2 languages | `app_en.arb` / `app_he.arb`, `@`-metadata excluded |
| Fast test files / LOC | 72 / 15,857 | `test/` |
| Device test files | 21 | `integration_test/` |
| Tests passing at branch point | 1,172 | per `docs/STATUS.md` |
| Existing Swift in `ios/Runner/` | 10 files | bridge + chrome + presentation, all written for Epic N |
| Deployment target today | iOS 15.0 | `project.pbxproj` |
| Toolchain on this machine | Xcode 26.3 (17C529), iOS 26.2 SDK, Swift 6.2.4 | `xcodebuild -version`, `-showsdks` |

### The one number that decides the shape of this project

```
UI / chrome    30,858 LOC   61%
Logic          21,286 LOC   39%   (domain 6,116 + services 7,905 + storage/catalog 5,912
                                   + core utils 636 + main/app/routes 717)
```

**Sixty-one percent of this app is a hand-built reproduction of iOS.** A large-title
navigation bar, a fake glass tab bar, a swipe-to-delete row, an action sheet, an
inset grouped list, a date picker, a toast, a press-highlight, four hand-written
chart painters, a custom colour picker, nine hand-derived theme ramps with a
contrast test to police them, and a scroll-edge observer that exists because a
Flutter bar cannot see a scroll view.

Every one of those is a system API in SwiftUI. That is the entire economic case for
this migration, and it is also the reason the risk is *not* where it feels like it
is: the screens are the cheap part. The 21,286 LOC of logic — the workout generator,
the setup engine, the portion solver, the analytics aggregators, the nutrition unit
math, the content-language machinery — is the part that must come across *exactly*,
and §9 is about nothing else.

### What is already Swift and what happens to it

`ios/Runner/` has 10 Swift files from the Epic N bridge work: `ChromeHostApiImpl`,
`ChromeMessages.g`, `NavBarHostController`, `TabBarHostController`,
`RootContainerViewController`, `BannerPresenter`, `DatePickerSheetController`,
`Haptics`, `PresentationHostApiImpl`, `CapabilityReporter`.

**All ten are deleted.** Every one exists to let Flutter borrow a UIKit surface.
With no Flutter there is nothing to bridge; `UIAlertController` becomes `.alert`,
`BannerPresenter` becomes a SwiftUI overlay or is dropped entirely, `Haptics`
becomes `.sensoryFeedback`. Nothing in that directory is carried forward except as
reference reading. `pigeons/`, `lib/bridge/`, and `lib/shell/` go with them.

---

## 2. Two corrections to the premise, before anything is built

### 2.1 "iOS 27 Liquid Glass" — Liquid Glass is iOS **26**

Liquid Glass is the iOS 26 design system: `glassEffect`, `GlassEffectContainer`,
`glassEffectID`, `.buttonStyle(.glass)`, `.tabViewBottomAccessory`,
`.tabBarMinimizeBehavior`, `.scrollEdgeEffectStyle`, `.backgroundExtensionEffect`,
`ToolbarSpacer`. Those are the APIs this plan is written against, and they are all
in the SDK on this machine (iOS 26.2).

iOS 27 is real — `docs/STATUS.md` records a release build installed on the owner's
iPhone 15 Pro running **iOS 27.0** — but **there is no iOS 27 SDK on this machine**.
`xcodebuild -showsdks` reports iOS 26.2 as the newest. No iOS 27-only symbol can be
compiled here today, so a plan that names one is a plan that cannot be built.

**Decision.** Build against the iOS 26 API family with a minimum deployment target
of iOS 26.0. Devices on iOS 27 get iOS 27's rendering of those same APIs
automatically, which is the point of asking the system for a material instead of
drawing one. When Xcode 27 is installed, adopting genuinely-new iOS 27 API is a
deployment-target bump plus `if #available(iOS 27, *)` branches — additive, not a
redesign. §10 carries the rule that makes that true.

This is not a scope reduction. It is the same target, named correctly.

### 2.2 "widgets only" — read as *widgets included, and made first-class*

Two readings, and they lead to very different apps:

- **(a)** "…Liquid Glass style, and widgets" — the app plus a real WidgetKit surface.
- **(b)** "a widgets-only product" — no app, just home-screen widgets.

**Assumed: (a).** (b) is incompatible with everything else in the request — an
onboarding flow, a workout session screen, and a page-structure review only exist
if there are pages. Reading (a) is also the one where "widgets" is a large, real
piece of work rather than a footnote, so it is treated as a first-class phase (§8)
with its own architecture, not as decoration bolted on at the end.

If (b) was meant, say so at Phase 0 and the plan collapses to §8 plus a data store —
roughly one-fifth the work.

---

## 3. Target architecture

### 3.1 Repository and target layout

```
Wellness-app/
├─ WellnessApp.xcworkspace
├─ App/                                   ← thin app target (~1,200 LOC)
│  ├─ WellnessApp.swift                     @main, ModelContainer, scene phase
│  ├─ RootView.swift                        TabView + per-tab NavigationStack
│  ├─ AppRouter.swift                       deep links, notification routing
│  ├─ Resources/
│  │  ├─ Assets.xcassets
│  │  ├─ Localizable.xcstrings              ← en + he, migrated from ARB
│  │  └─ Info.plist
│  └─ Wellness.entitlements                 App Group, notifications
│
├─ Packages/WellnessKit/                  ← local SPM package: all the real code
│  ├─ Package.swift
│  ├─ Sources/
│  │  ├─ WellnessModels/                    entities, enums, IDs, value types
│  │  ├─ WellnessDomain/                    pure logic — NO SwiftUI, NO SwiftData
│  │  ├─ WellnessPersistence/               SwiftData models, stores, migration
│  │  ├─ WellnessServices/                  notifications, export, preferences…
│  │  ├─ WellnessCatalog/                   starter foods / exercises / recipes
│  │  ├─ WellnessStores/                    @Observable feature stores
│  │  └─ WellnessUI/                        design system + shared components
│  └─ Tests/
│     ├─ WellnessDomainTests/               Swift Testing, runs on macOS
│     ├─ WellnessPersistenceTests/
│     ├─ WellnessServicesTests/
│     └─ ParityTests/                       ← §9.1, replays the golden corpus
│
├─ Features/                              ← screens, one folder per feature
│  ├─ Dashboard/  Meals/  Workouts/  Sleep/  Calendar/  Analytics/
│  ├─ Settings/   Onboarding/
│
├─ Widgets/                               ← WidgetKit extension
│  ├─ WellnessWidgets.swift                 bundle
│  ├─ Home/  Lock/  Control/  LiveActivity/
│
├─ Intents/                               ← App Intents (in WellnessKit, surfaced here)
├─ UITests/                               ← XCUITest, mirrors integration_test/
├─ parity/                                ← §9.1 golden corpus (JSON, checked in)
└─ docs/                                  ← unchanged, still the tracking system
```

**Why a local SPM package rather than everything in the app target.** Three reasons,
all of which are things the current codebase already fought for and won:

1. **The fast suite stays fast.** `swift test` on the package runs on macOS with no
   simulator boot. That is the direct replacement for the 72-file `test/` suite the
   project relies on, and it keeps the "ask before running tests, prefer the fast
   suite" workflow intact.
2. **The layering test becomes a compiler error.** `test/architecture/layering_test.dart`
   greps for a domain file importing `dart:io` or `shell/`. As SPM modules, that rule
   is `WellnessDomain` simply not declaring a dependency on SwiftUI or SwiftData — a
   violation does not fail a test, it fails to build. Strictly better than a tripwire.
3. **The widget extension links the same code.** `Widgets/` depends on
   `WellnessModels` + `WellnessPersistence` + `WellnessDomain` and gets the real
   nutrition math, not a copy. §8.3.

### 3.2 Module dependency graph — the rule that keeps it honest

```
                    ┌─────────────┐
                    │ WellnessUI  │──────────────┐
                    └──────┬──────┘              │
                           │                     ▼
  App / Features ──────────┼──────────► WellnessStores ──► WellnessServices
                           │                     │               │
                           │                     ▼               ▼
                           └──────────► WellnessPersistence ──► WellnessModels
                                                 │               ▲
                                                 ▼               │
                                          WellnessCatalog        │
                                                                 │
                                          WellnessDomain ────────┘
```

Enforced by `Package.swift`, not by discipline:

- `WellnessModels` — Foundation only. No SwiftUI, no SwiftData, no UIKit.
- `WellnessDomain` — Foundation + `WellnessModels`. **This is the port target for
  every one of the ~14,000 LOC of business logic**, and it is the module the parity
  corpus tests. It cannot import persistence, so no generator can secretly query.
- `WellnessPersistence` — SwiftData lives here and *only* here.
- `WellnessStores` — the only module that may hold mutable app state.
- `WellnessUI` — SwiftUI, no domain logic, no persistence.
- `Features/` — may import everything; may contain no business rule that a test in
  `WellnessDomainTests` could have covered.

### 3.3 State management: Riverpod → Observation

`hooks_riverpod` (providers, `StreamProvider`, `ref.watch`) → the `@Observable`
macro plus `@Environment`. Direct mapping:

| Riverpod today | Swift |
|---|---|
| `Provider<Service>` | `@Observable final class` in `WellnessStores`, injected via `.environment(_:)` |
| `StreamProvider<List<Meal>>` | `@Observable` store exposing `var meals: [Meal]`; SwiftUI observes the property, not a stream |
| `ref.watch(x)` in `build()` | read the property in `body` |
| `StateNotifier` | `@Observable` class with mutating methods |
| `ProviderScope(overrides:)` in tests | initialiser injection — the store takes a store protocol |

**This deletes a whole documented bug class.** `docs/REPO_GUIDE.md` records that
several screens build their stream inside `build()`, creating a new stream per
rebuild and resetting `StreamBuilder` to a waiting state; and that a hand-rolled
list-equality predicate once silently swallowed amount edits. Observation has no
streams to rebuild and no equality predicate to get wrong — the property changed or
it did not. Neither failure is expressible in the target architecture.

**Concurrency.** Swift 6 language mode, **strict concurrency = complete, from the
first commit**, not retrofitted. `WellnessDomain` is `Sendable` value types
throughout (it is pure functions over structs, which is the easy case).
`WellnessPersistence` is `@ModelActor`-isolated. Stores are `@MainActor`.

### 3.4 Persistence: SwiftData, behind a protocol

**Recommendation: SwiftData**, with every feature reading through a store protocol
rather than touching `ModelContext` directly.

Rationale, and the honest counter-argument:

- The current storage is 12 in-memory collections with a debounced atomic JSON
  write, and the guide is explicit that "there is no SQL database". SwiftData is the
  smallest conceptual step from that: `@Model` classes, a container, automatic
  persistence, `@Query` where it fits.
- `ModelConfiguration(isStoredInMemoryOnly: true)` is an exact analogue of the
  existing `AppDatabase()` with no `SnapshotStore` — filesystem-free tests, which is
  a property the current suite depends on heavily (and which `resetForTesting()`
  exists to patch up; with a fresh in-memory container per test, `resetForTesting`
  has no successor because static mutable state is gone).
- App Group container sharing gives the widget extension the real data for free (§8.3).
- CloudKit sync later is a configuration flag, not a rewrite.

**The counter-argument, stated rather than buried:** analytics aggregates a year of
meals, sets and sleep in one pass, and `docs/REPO_GUIDE.md` has a standing rule that
per-day queries in a loop are forbidden. SwiftData's per-fetch overhead is real. The
mitigation is the same one the Dart code already uses — `AnalyticsRepository` fetches
each collection **once** into arrays and joins in memory. That is not a workaround
for SwiftData; it is the existing, tested design.

**The protocol is the insurance.** Every feature depends on `protocol MealStore`,
`protocol WorkoutStore`, etc., in `WellnessPersistence`. If SwiftData turns out to be
the wrong call under a real 6-month dataset (the `demo_seed_service` corpus is
exactly the benchmark to prove it on — see §14 Phase 2 gate), swapping to GRDB or raw
SQLite is one conforming type per protocol and zero feature changes. Deciding this at
Phase 2 with a measurement beats deciding it now with an opinion.

### 3.5 Navigation: go_router → NavigationStack with typed routes

27 routes today. They become an enum per tab:

```swift
enum MealsRoute: Hashable {
    case day(Date)
    case editMeal(Meal.ID)
    case newMeal(date: Date)
    case foods
    case templates
    case newTemplate
    case template(MealTemplate.ID)
}
```

with `NavigationStack(path: $router.meals)` and `.navigationDestination(for:)`.

**The URL paths are kept as a parsing layer, not thrown away.** `AppRouter` exposes
`func route(for url: URL) -> Destination?` that understands the existing 27 paths
verbatim (`/meals/edit/:mealId`, `/workouts/session/:sessionId`, …). Reason: the
notification payloads already scheduled on the owner's device carry those paths, and
`notification_action_handler.dart` routes on them. Keeping the parser means a
notification scheduled by the Flutter build still lands on the right screen in the
Swift build. §15 Q11.

### 3.6 Dependencies

**Zero third-party packages.** Not a purity stance — a specific reading of what this
app needs. Charts → Swift Charts. Local notifications → `UNUserNotificationCenter`
(the app already uses `flutter_local_notifications` as a thin wrapper over exactly
that). Timezone → `Foundation.TimeZone` (drops `timezone` + `flutter_native_timezone`,
~two packages and a data blob). Audio → `AVAudioPlayer` for the one rest-timer beep.
Share → `ShareLink`. File picking → `.fileImporter`. UUID, path, intl → Foundation.
Persistence → SwiftData.

Every one of the 20 current pub dependencies has a first-party replacement. Adding
an SPM dependency later requires a paragraph in this document saying which system
API was insufficient.

---

## 4. Module-by-module port map

Read as: *this Dart becomes that Swift*. "Delete" means the system provides it and
nothing is ported.

### 4.1 Logic — ports 1:1, must be parity-tested

| Dart | LOC | Swift target | Notes |
|---|---:|---|---|
| `features/*/domain/models.dart` (+freezed/g) | ~1,000 hand | `WellnessModels` structs | Freezed's `copyWith`/`==`/`toJson` → Swift value semantics + `Codable`. **~5,200 LOC of generated code evaporates.** |
| `meals/domain/food_nutrition_math.dart` | — | `WellnessDomain/NutritionMath.swift` | Single source of truth, preserved as such. Highest-value parity target (§9.1). |
| `meals/domain/food_serving_kind.dart` | — | `WellnessDomain/ServingKind.swift` | Enum + legacy-unit parser, verbatim including the `"30g"`-is-count rule and the *no* oz↔g conversion rule. |
| `services/workout_template_generator.dart` | 603 | `WellnessDomain/WorkoutTemplateGenerator.swift` | Includes the #109 fix — reserved accessory slots, per-session `variant` offset, interleaved patterns. |
| `services/workout_programming.dart` | 337 | `WellnessDomain/WorkoutProgramming.swift` | |
| `services/meal_template_generator.dart` + `meal_recipes.dart` | ~440 | `WellnessDomain/MealTemplateGenerator.swift` | Ingredients resolve by **catalog id**, never by name. That rule is load-bearing and gets its own test. |
| `services/meal_portion_solver.dart` | 317 | `WellnessDomain/PortionSolver.swift` | |
| `services/setup_engine_service.dart` | 462 | `WellnessDomain/SetupEngine.swift` | |
| `services/profile_fit.dart`, `profile_filter_service.dart` | ~400 | `WellnessDomain/ProfileFit.swift` | |
| `services/calendar_schedule_generator.dart` | 269 | `WellnessDomain/ScheduleGenerator.swift` | |
| `features/analytics/domain/*` (8 files) | ~1,300 | `WellnessDomain/Analytics/` | Ranges, series, goal scoring, e1RM/Epley, plateau detection, insights. The four documented rules (single pass, no per-day queries, exclude in-progress sessions, `nil` ≠ 0) carry over as written. |
| `features/analytics/data/analytics_repository.dart` | — | `WellnessPersistence/AnalyticsRepository.swift` | Still the only analytics thing that touches storage. |
| `workouts/domain/{rest_time,exercise_tags,exercise_unit,muscle_label}.dart` | ~700 | `WellnessDomain/` | `primaryMuscle`/`unit`/enum keys stay **English ids**; labels map at render. |
| `data/catalog/starter_{foods,exercises}.dart`, `starter_templates.dart` | 2,900 | `WellnessCatalog` — **JSON resources**, not code | 42 foods / 16+ exercises as `Resources/*.json` decoded into structs. Bilingual `name`/`nameHe` pairs stay in the authoring data exactly as documented, and a decode test replaces the compile-time guarantee. |
| `services/content_language_service.dart` + `content_regeneration_service.dart` | ~500 | `WellnessServices/ContentLanguage.swift` | The three-step switch order (relanguage catalog → regenerate generated templates → repin+retitle calendar events) is load-bearing and is ported *as an ordered sequence with a test that asserts the order*. |
| `services/notification_service.dart` + `notification_action_handler.dart` + `notification_preferences_service.dart` | ~1,000 | `WellnessServices/Notifications/` | Direct `UNUserNotificationCenter`. Identifier scheme and payload keys preserved. §15 Q11. |
| `services/export_import_service.dart` | 291 | `WellnessServices/BackupService.swift` | **File format frozen.** §7. |
| `services/preferences_service.dart` (+theme, language, timezone, time, backup_location) | ~1,200 | `WellnessServices/Preferences.swift` | `UserDefaults` in the App Group suite (widgets need to read some of it). |
| `services/demo_seed_service.dart`, `dummy_data_service.dart` | 1,463 | `WellnessCatalog/DemoSeed.swift`, **debug build only** | Behind a `#if DEBUG` + launch argument rather than `--dart-define`. Keeps the export→import round-trip self-check. |
| `services/background_refresh_service.dart` | — | `BGTaskScheduler` | |
| `data/db/drift_database.dart` | 2,851 | `WellnessPersistence` (~800 LOC est.) | The 18 static lists, the `_touch()` debounce, the atomic temp-file+rename write, the `.corrupt` quarantine — **all of it is SwiftData's job**. This is the single largest deletion. Its *importer* survives; see §7. |

### 4.2 UI — mostly deleted, replaced by system API

| Dart | LOC | Fate |
|---|---:|---|
| `core/ios/app_scaffold.dart` | 651 | **Delete** → `NavigationStack` + `.navigationTitle` + `.toolbar`. Large-title collapse, chevron back, Dynamic Type: free. |
| `core/ios/liquid_glass_tab_bar.dart` | — | **Delete** → `TabView` + `Tab`. The file's own comment says "it is *not* the genuine system material". Now it is. |
| `core/ios/glass.dart` | 591 | **Delete** → `.glassEffect(_:in:)` / `GlassEffectContainer`. |
| `core/ios/sheets.dart` | — | **Delete** → `.sheet` + `.presentationDetents`, `.confirmationDialog`, `.alert`. |
| `core/ios/swipe_row.dart` | — | **Delete** → `.swipeActions`, `.contextMenu`. |
| `core/ios/inset_list.dart` | — | **Delete** → `List` + `Section` (`.insetGrouped` is the default). |
| `core/ios/controls.dart` | — | **Delete** → `Picker(.segmented)`, `.searchable`, native filter chips. |
| `core/ios/pickers.dart` | — | **Delete** → `DatePicker`. |
| `core/ios/feedback.dart` | — | **Delete** → SwiftUI overlay or `.alert`; the `BannerPresenter` UIKit hack is unnecessary. |
| `core/ios/pressable.dart` | — | **Delete** → `Button` + `.buttonStyle`. |
| `core/ios/date_strip.dart`, `shortcuts.dart` | — | **Port** — these are app design, not iOS chrome. ~300 LOC Swift. |
| `core/ios/native_ui.dart` + `bridge/` + `pigeons/` + `shell/` | ~1,900 | **Delete.** Nothing to bridge. |
| `core/design/tokens.dart` + `scroll_edge.dart` | — | **Delete** → Dynamic Type text styles, system spacing, `.scrollEdgeEffectStyle`. The scroll-edge observer exists purely because a Flutter bar cannot see a `UIScrollView`. |
| `core/theme.dart` | 1,227 | **Replace** with ~250 LOC (§6.3). |
| `core/widgets.dart` | 1,119 | **Port selectively** — the app-specific pieces (macro rings, chips, empty states) survive at maybe 40% size. |
| `features/settings/ui/advanced_color_picker.dart` | 1,091 | **Delete** → `ColorPicker`. |
| `features/analytics/ui/charts/*` (4 painters) | ~900 | **Delete** → Swift Charts. |
| `features/*/ui/*` (48 files) | 22,120 | **Rewrite** as SwiftUI views — see §5 for which ones change shape rather than just language. |

---

## 5. Page structure — what changes shape, and why

The request explicitly invites this: *"if the structure of the pages there are not
fit for the new changes, think about switching to what you see fit."* Here is the
whole route table with a verdict. "Reshape" means the screen's information
architecture changes, not just its rendering.

| Route(s) | Today | Verdict | Target |
|---|---|---|---|
| 5 tabs + `/dashboard` | Fake glass tab bar, dashboard 1,480 LOC | **Reshape** | `TabView` with `Tab`; `.tabBarMinimizeBehavior(.onScrollDown)`; **`.tabViewBottomAccessory`** hosts the live workout / rest timer / sleep timer (§5.1). |
| `/` dashboard | One 1,480-LOC file | **Reshape** | Section-per-file, driven by a `DashboardSection` enum the user can reorder. Adopts `.backgroundExtensionEffect` for the header. |
| `/meals` | Date strip → totals → entries → "+" | **Keep** shape | The meals/workouts symmetry is a good decision and survives verbatim. `List` + `.swipeActions`. |
| `/meals/edit/:id`, `/meals/edit` | Full-screen pushed page | **Reshape** | `.sheet` with `.presentationDetents([.medium, .large])` + `Form`. This is what the Dart `AppFormPage`/`pushModalPage` was imitating. |
| `/meals/foods` | Catalog page, 679 LOC | **Reshape** | `List` + `.searchable` (iOS 26 bottom-aligned search) + section index. |
| `/meals/templates/*` | 3 screens | **Keep** shape, rewrite | `Form`-based editor. |
| `/workouts` | Mirror of meals | **Keep** shape | |
| `/workouts/exercises` | Library + picker sheet (1,125 LOC across 2 files) | **Merge** | One `ExerciseBrowser` view used both as a tab destination and as a `.sheet` picker. Today those are two files that drifted apart. |
| `/workouts/session/:id` | 1,391 LOC, the biggest screen | **Reshape — the flagship** | Full-screen `NavigationStack`; set entry via `Form`; **Live Activity + Dynamic Island** for the rest timer (§8.4); minimises into the tab bar accessory when the user navigates away. This is currently impossible and is the single most visible win. |
| `/workouts/templates/*` | 3 screens | **Keep** shape | |
| `/sleep`, `/sleep/timer` | 694 + 655 LOC | **Reshape** | Timer becomes a Live Activity; the page becomes history + a start control. |
| `/calendar` | 1,138 LOC page + 447 LOC month grid + 1,017 LOC scheduling dialog | **Reshape** | Month grid via `UICalendarView` (`UIViewRepresentable`) — free decorations, selection behaviour, VoiceOver and RTL. Day/week stay SwiftUI. Scheduling dialog → `.sheet` + `Form` + system `DatePicker`, which is most of those 1,017 lines. |
| `/analytics` | 7 sections, 4 hand-written painters | **Keep** structure, replace charts | Swift Charts. The `analyticsViewProvider` single-pass rule is preserved as a single `@Observable` `AnalyticsStore`. |
| `/settings/*` (7 sub-pages) | 740 + 1,014 + 1,091 + … | **Reshape** | `Form` + `NavigationLink` throughout. `advanced_color_picker` (1,091 LOC) → `ColorPicker`. Expect ~70% shrinkage across this area. |
| `/onboarding` | 1,704 LOC single file | **Reshape** | `OnboardingStep` enum + one view per step + a `NavigationStack` path. Step 0 (content language) stays step 0 and stays load-bearing — nothing is seeded before it. |

### 5.1 The tab bar accessory — the structural idea worth calling out

iOS 26 gives a `TabView` a persistent accessory view above the tab bar that
participates in the glass and morphs as the bar minimises. This app has **three**
things that currently fight for screen space and lose:

1. an in-progress workout (`WorkoutSession.endedAt == nil` — already a first-class
   state in the model, and already excluded from every analytics aggregate),
2. the rest timer,
3. the sleep timer.

Today each is trapped inside its own page. As a bottom accessory, an in-progress
session is visible and resumable from anywhere, exactly like a now-playing bar.
That is a genuine product improvement that the platform hands over, and it changes
the navigation model enough to be worth deciding now rather than discovering in
Phase 6.

### 5.2 What does *not* change

Deliberately: the meals/workouts three-screen symmetry, the analytics section list
and its four domain rules, the onboarding step order, the content-language design
(§4.1), the export file format (§7), and the docs tracking system in `CLAUDE.md`.
These are decisions the project already made, tested, and paid for. A rewrite is
not a licence to relitigate them.

---

## 6. Liquid Glass adoption

### 6.1 The one rule

**Ask for the material. Never draw it.**

This is the rule `docs/PLATFORM_UI_ARCHITECTURE.md` §10 already carries, and it
survives verbatim into a codebase where it is finally easy to obey. No
`BackdropFilter` analogue, no hand-tuned blur radius, no saturation multiplier, no
rim-highlight gradient, no hardcoded corner radius copied off a screenshot. If a
surface needs glass it calls `.glassEffect`. If it needs a background it uses a
semantic material. If a number was measured from a screenshot, it is wrong.

Corollary: **Reduce Transparency, Increase Contrast, Reduced Motion and Dynamic Type
are then free and correct**, because the system honours them in its own materials.
The current app needs a settings toggle (Appearance → Glass Effect: Off/Subtle/Full)
and a `setChromeStyle` bridge call to keep Flutter's imitation in sync with the
accessibility setting. **That toggle is deleted**; the system setting is the setting.
§15 Q7.

### 6.2 Where glass goes — the three-layer rule, kept

Already decided on `rc` after a reversal, and it was decided correctly:

| Layer | Contents | Material |
|---|---|---|
| Content | cards, list rows, charts, editors, forms | **opaque** |
| Functional | toolbars, pinned headers, sheets, buttons, chips, search, segmented | glass |
| Navigation | tab bar, nav bar | system glass, untouched |

Applying glass directly to content is an Apple-named anti-pattern and the project
already learned this the expensive way (`docs/PLATFORM_UI_ARCHITECTURE.md` records
the reversal and the "washed out" outcome). It does not get relearned.

`test/architecture/glass_coverage_test.dart` currently enforces this by grepping
Dart. Its successor is a `WellnessUI` lint test asserting that `.glassEffect` appears
only in files under `WellnessUI/Functional/` — same tripwire, same reason.

### 6.3 Themes: nine ramps → one tint

The hardest design collision in the migration, so it gets an explicit decision.

Today: nine hand-derived theme ramps (background → surface → elevated), per-area
meals/workouts/sleep colours, a custom colour picker, and a `theme_contrast_test.dart`
that pins `onSurface` at ≥4.5:1 for every theme × every glass level.

Liquid Glass assumes system materials and semantic colours, and derives depth from
the material rather than from a background ramp. Nine custom ramps underneath system
glass will fight it, and the contrast test exists precisely because they already do.

**Decision.** Keep the *idea*, drop the ramps:

- Backgrounds and surfaces become **semantic** (`.background`, `.secondarySystemGroupedBackground`, materials).
- A theme becomes an **accent colour** applied with `.tint()`, plus the three area
  colours (meals / workouts / sleep) which are informational and stay.
- Users keep a colour picker — the system `ColorPicker`, which is 1,091 fewer lines.
- Dark mode is `.dark`/`.light`/system, not a theme.
- `theme_contrast_test.dart` is replaced by `XCUIApplication().performAccessibilityAudit()`,
  which checks contrast, hit targets, labels and clipped text across real rendered
  screens — a broader guarantee than the Dart test gave.

If keeping all nine ramps matters more than the design coherence, say so at Phase 5
and they can be reintroduced as `.backgroundStyle` overrides — but they will look
wrong under glass, and that is not a fixable problem. §15 Q6.

### 6.4 Concrete API checklist (iOS 26)

`glassEffect(_:in:)` · `GlassEffectContainer` · `glassEffectID(_:in:)` for morph
transitions · `.buttonStyle(.glass)` / `.glassProminent` · `TabView` + `Tab` ·
`.tabBarMinimizeBehavior(.onScrollDown)` · `.tabViewBottomAccessory` ·
`.searchable` (bottom-aligned) with `.searchToolbarBehavior` ·
`.scrollEdgeEffectStyle(.soft, for:)` · `.backgroundExtensionEffect()` ·
`ToolbarSpacer(.fixed, placement:)` · `.toolbarTitleDisplayMode` ·
`.presentationDetents` + `.presentationBackground` · `.symbolEffect` /
`.symbolColorRenderingMode` · `.sensoryFeedback` · `ContainerRelativeShape` in widgets.

---

## 7. Data migration — the contract that makes this safe

The owner has real data on a real device (iPhone 15 Pro, iOS 27.0). Losing it is the
worst possible outcome of this project, and it is entirely preventable.

**Three independent paths, all of which must work:**

1. **In-place container read.** Keep the same bundle identifier. The Swift app on
   first launch looks for `wellness_data.json` in the Documents directory the Flutter
   app wrote to, decodes it with `SnapshotImporter`, writes it into SwiftData, and
   renames the original to `wellness_data.json.migrated` (never deletes it). If the
   file is absent, it is a fresh install and onboarding runs.
2. **Export/import.** `export_import_service.dart`'s file format is **frozen as an
   interchange contract**. The Swift `BackupService` reads and writes the same JSON.
   A backup taken from the Flutter build restores into the Swift build. This is the
   user-visible fallback and it is also the belt to path 1's braces.
3. **Manual dump.** Before cutover, one export is taken from the device and checked
   into `parity/fixtures/device_snapshot_2026-XX-XX.json` (scrubbed if it needs to
   be) as a permanent migration test fixture.

**The importer is tested, not trusted.** `WellnessPersistenceTests` replays the
snapshot fixtures and asserts, per collection: row count, id set equality, and a
field-level checksum. The current suite already has the equivalent instinct —
`export_completeness_test.dart`, `backup_fidelity_and_streams_test.dart`,
`persistence_test.dart`, `catalog_migration_test.dart` — and those four map directly
onto Swift tests.

**Snapshot schema notes carried across:** `Meal.date` is a `yyyymmdd` `Int` (kept as
such — it is an index key, not a date); nutrition on `MealItem` is **denormalized at
save time** and must not be recomputed on import (recomputing would silently rewrite
history against an edited `FoodItem`); `contentLanguage` is in the snapshot and must
be read before any seeding decision is made.

---

## 8. Widgets — the first-class surface

### 8.1 What ships

| Family | Widget | Content |
|---|---|---|
| Home (small) | **Today** | kcal + protein rings against goal |
| Home (medium) | **Today** | rings + macro breakdown + next scheduled event |
| Home (medium) | **Next up** | next 3 calendar events with type glyphs, tap → deep link |
| Home (large) | **Week** | 7-day adherence grid (meals logged / workouts done / sleep) |
| Home (small) | **Streak** | workout streak + last session |
| Lock (`accessoryCircular`) | kcal ring | |
| Lock (`accessoryRectangular`) | next event / remaining kcal | |
| Lock (`accessoryInline`) | streak | |
| Control Center (`ControlWidget`) | **Log a meal**, **Start workout**, **Start sleep timer** | one tap, via App Intents |
| Live Activity | **Workout session** — current exercise, set x/y, rest countdown; Dynamic Island compact + expanded | |
| Live Activity | **Sleep timer** | |
| Interactive widget buttons | quick-log a template meal; complete current set | `AppIntent` + `WidgetCenter.reloadTimelines` |

### 8.2 App Intents / Shortcuts / Siri

The same `AppIntent` types back the Control Center controls, the interactive widget
buttons, Shortcuts, and Siri. Free surface area once the intents exist:
`LogMealIntent`, `StartWorkoutIntent(template:)`, `CompleteSetIntent`,
`StartSleepTimerIntent`, `LogBodyWeightIntent(kg:)`. `AppShortcutsProvider` exposes
the first three with spoken phrases in **both** English and Hebrew.

### 8.3 How widgets get data — the architecture decision

An App Group (`group.<bundle-id>`) shared between app and extension, with the
SwiftData `ModelConfiguration(groupContainer: .identifier(...))`. The widget links
`WellnessModels` + `WellnessPersistence` + `WellnessDomain` and computes its numbers
with **the real nutrition math**, not a reimplementation.

**Plus a cheap cache.** A widget timeline must build in a tight memory budget, and
opening a full SwiftData container to render a ring is wasteful. So the app also
writes a small `WidgetSnapshot: Codable` (today's totals, goals, next 3 events,
streak) into the App Group on every relevant mutation. The widget reads that first
and only opens the store if it is stale.

**This is the one place a nutrition-math duplicate could sneak in, so it is
explicitly forbidden**: `WidgetSnapshot` holds *computed results*, never raw amounts
that the widget would have to convert. The rule that killed the oz double-conversion
bug is the same rule here.

### 8.4 Live Activity ↔ session state

The workout Live Activity's `ContentState` is derived from the same
`WorkoutSessionStore` that drives the screen and the tab-bar accessory — one source
of truth, three renderers. Rest-countdown updates use `Text(timerInterval:)` so the
countdown ticks without a push or a background task.

---

## 9. Testing and regression strategy — "how we know we missed nothing"

This is the part of the request that decides whether the migration is trustworthy,
so it is the most concrete section here, and **Phase 0 builds it before any Swift
exists.**

### 9.1 The golden parity corpus — the centrepiece

**Before writing a line of Swift**, add a Dart harness (`tool/parity_dump.dart`) that
runs every pure function over a fixed input matrix and writes canonical JSON to
`parity/golden/`. Swift tests replay the identical inputs and must produce
**byte-identical** output after the same canonicalisation (sorted keys, fixed
decimal formatting, fixed clock, fixed UUID sequence).

Corpus contents, with why each is in it:

| Corpus file | Inputs | Guards against |
|---|---|---|
| `nutrition_math.json` | every `FoodServingKind` × ~20 amounts × ~10 catalog foods, both `displayQuantity`/`storedQuantity` directions | the oz double-conversion class of bug, which this project has already had once |
| `serving_kind_parsing.json` | every `unit` string in the catalog + the legacy oddities (`"30g"`, `"tbsp"`, `"serving"`) | the `"30g"`-is-count-not-scale rule |
| `setup_engine.json` | a profile matrix (age × sex × weight × goal × experience × days/week × equipment) | silent profile-fit drift |
| `workout_generation.json` | same matrix → full generated programs | issue #109's exact failure: compounds-only plans and byte-identical "variations" |
| `meal_generation.json` | same matrix × both languages | the Hebrew-zero-templates bug (ingredients resolved by name) |
| `portion_solver.json` | target macros × food sets | |
| `schedule_generation.json` | programs × start dates × recurrence | calendar duplication + recurrence regressions (3 existing tests) |
| `analytics.json` | a fixed 365-day dataset → every series, aggregate, goal score, e1RM, plateau flag, insight | the four documented analytics rules, especially `nil` ≠ 0 and excluded in-progress sessions |
| `rest_prescription.json` | exercise × experience × goal | |
| `content_language_switch.json` | a seeded DB in each language, switched, dumped | the three-step switch order and the "edited rows are skipped" rule |
| `export_roundtrip.json` | the demo-seed 6-month dataset exported | the frozen file format (§7) |

**Why this is the right instrument.** A ported test asserts what someone thought to
assert. A golden corpus asserts *everything the function currently does*, including
the behaviour nobody wrote down. For a rewrite, the second is what you want. It also
runs in both directions: if a Swift output differs, either the port is wrong or the
Dart had a bug — and both outcomes are useful, whereas a silent divergence is not.

**Corpus is frozen at Phase 0 and checked in.** If a Phase 3 port deliberately
changes behaviour, the corpus file changes in the same commit with the reason in the
message. That makes every intentional behaviour change visible in a diff.

### 9.2 Disposition of the existing 1,172 tests

A CSV, `parity/test_inventory.csv`, with one row per existing test:

```
suite,file,test_name,disposition,swift_target,note
```

`disposition ∈ { ported, covered-by-corpus, covered-by-system, obsolete, new }`

- **ported** — a real assertion about app behaviour; gets a Swift Testing counterpart.
- **covered-by-corpus** — subsumed by §9.1 (most of the domain tests).
- **covered-by-system** — asserted Flutter-specific behaviour that the system now
  owns. Examples: `theme_contrast_test.dart` → accessibility audit;
  `glass_coverage_test.dart` → the `WellnessUI` file-boundary lint;
  `layering_test.dart` → SPM module boundaries (compiler-enforced);
  `shell_guardrail_test.dart` → nothing to guard, no shell;
  `scroll_edge_test.dart`, `glass_surface_test.dart` → system-owned materials.
- **obsolete** — pinned an implementation that no longer exists (e.g.
  `color_picker_painters_test.dart` when the painter is deleted). **Requires a
  written reason in the `note` column.**
- **new** — Swift-only concerns: SwiftData migration, App Group sharing, widget
  timeline, Live Activity state, App Intent invocation.

**The gate: no blank `disposition` cell.** That is what "we didn't miss anything"
means operationally — not a feeling, a file with 1,172 non-empty rows that gets
reviewed once and then cited forever.

### 9.3 The Swift test pyramid

| Layer | Tool | Runs where | Replaces |
|---|---|---|---|
| Domain unit + parity | **Swift Testing** (`@Test`, `#expect`) | `swift test`, macOS, no simulator | `test/regression/*`, `test/analytics/*` — the fast suite |
| Persistence | Swift Testing + in-memory `ModelContainer` | macOS | `persistence_test`, `crud_matrix_test`, `data_integrity_test`, `backup_*` |
| Services | Swift Testing + fakes (`UNUserNotificationCenter` behind a protocol) | macOS | `notification_*`, `quiet_hours_*`, `preferences_service_test` |
| View logic | Swift Testing against `@Observable` stores | macOS | `test/widget/*` — store assertions, not pixels |
| UI flows | **XCUITest** | simulator | `integration_test/sanity/*` (23) + `regression/*` (25) |
| Accessibility | `performAccessibilityAudit()` in XCUITest | simulator | `theme_contrast_test`, `chart_semantics_test`, plus much more |
| Widgets | Swift Testing on timeline providers; XCUITest for placement | both | new |
| Performance | XCTest `measure` on the 6-month demo corpus | simulator | the §3.4 SwiftData decision gate |

**Two testing rules carried over from the Dart suite, because they were learned the
hard way:**

- The `pumpAndSettle()` prohibition (spinners hang it) has a direct XCUITest analogue:
  never `waitForExistence` on a spinner; wait on the element you actually want.
- Notification *delivery* needs an attended session with a permission dialog and is
  not CI-safe. Same in XCUITest. Action *handling* stays fully unit-testable by
  invoking the handler directly with a synthesised `UNNotificationResponse` — the
  exact technique the Dart suite already uses.

### 9.4 CI

GitHub Actions, macOS runner, three jobs:

1. `swift test` on `Packages/WellnessKit` — the fast gate, must stay under a couple
   of minutes, runs on every push.
2. `xcodebuild build` for app + widget extension — catches integration breakage.
3. `xcodebuild test -destination 'iOS Simulator'` for XCUITest — nightly and on PR
   to `main`, not on every push.

Plus the existing prohibition stands: **no unsolicited simulator runs.** Local
verification defaults to job 1.

---

## 10. Localization, RTL, accessibility

- **915 keys × 2 languages** migrate from `app_en.arb` / `app_he.arb` to a single
  `Localizable.xcstrings` String Catalog, by script (`tool/arb_to_xcstrings.dart`,
  written once, run once, checked in with its output). ICU plurals and placeholders
  map across; the script fails loudly on any key it cannot convert rather than
  emitting a lossy string.
- `localization_parity_test.dart` (en/he key parity) → a Swift test decoding the
  catalog and asserting every key has both languages and no key is stale.
- **RTL is mostly free**: SwiftUI's leading/trailing layout flips automatically. The
  audit work is finding places that hardcode `.left`/`.right`, `x` offsets, or a
  chevron direction. `rtl_helper.dart` and `rtl_helper_test.dart` become a checklist,
  not a module.
- **The content-language architecture is unchanged** (§4.1). Chrome follows the
  current language; content is written once and re-resolved only by an explicit
  language switch. This is the project's hardest-won invariant and it is not touched.
- **Dynamic Type** is a requirement of every screen from Phase 5, not an afterthought:
  no fixed frame heights on text, `ViewThatFits` where layouts break, and an XCUITest
  run at `.accessibilityExtraExtraExtraLarge` in the accessibility job.

---

## 11. Notifications

`flutter_local_notifications` + `timezone` + `flutter_native_timezone` →
`UNUserNotificationCenter` + `Foundation.TimeZone` directly.

Preserved as contracts, because scheduled notifications already exist on the owner's
device: the **request identifier scheme**, the **`userInfo` payload keys**, the
**category/action identifiers**, and the deep-link paths in the payload (§3.5).

**But**: notifications scheduled by the Flutter build are UNNotificationRequests owned
by the same bundle id, so they survive the app replacement. The Swift app must
therefore, on first launch after migration, **cancel all and reschedule from the
calendar** rather than trusting them — a Flutter-scheduled request may have a payload
shape the new handler does not expect, and re-deriving is cheap and total. That is one
function, `NotificationScheduler.rebuildAll()`, and it gets a test.

Quiet hours, per-type toggles and the notification-action handler port directly;
`notification_actions_test.dart` and `notification_action_handler_test.dart` are
`ported`, not `covered-by-system`.

---

## 12. What gets deleted, and when

**Nothing Flutter is deleted until Phase 9.** Until cutover, `rc` remains the
shipping app and must stay buildable and installable — that is the rollback plan
(§13). The `swift` branch adds; it does not subtract.

At Phase 9, in one commit, with the reason in the message:

`lib/` · `test/` · `integration_test/` · `pubspec.yaml` + `pubspec.lock` ·
`pigeons/` · `analysis_options.yaml` · `.fvmrc` · `android/` · `ios/Runner/` (the
Flutter-hosted target) · `ios/Flutter/` · `ios/Podfile*` + `Pods/` · `web/` if present.

**Kept forever**: `docs/` (unchanged tracking system), `parity/` (the corpus, the
inventory CSV and the device fixture — they are the migration's evidence),
`.claude/commands/`, `CLAUDE.md`, and the full git history, which is where the
"why" of every one of those hard-won invariants lives.

---

## 13. Risk register

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | A domain behaviour is silently lost in the port | **High** | **Severe** | §9.1 golden corpus, built before any Swift; §9.2 inventory with no blank cells |
| R2 | User's real data lost or corrupted at cutover | Low | **Severe** | §7 three independent paths; device fixture checked in; original snapshot renamed, never deleted |
| R3 | SwiftData too slow for a year of analytics | Medium | High | Store protocol from day one; Phase 2 gate benchmarks the 6-month demo corpus; GRDB swap is one type per protocol |
| R4 | The rewrite stalls half-done, leaving two dead apps | **Medium** | **Severe** | Phases 0–4 ship no UI and are individually valuable; `rc` stays shippable throughout; every phase has a hard exit gate and can be paused *between* phases |
| R5 | Nine themes look wrong under Liquid Glass | High | Medium | §6.3 decides this up front rather than at the end |
| R6 | Hebrew/RTL regressions in the new UI | Medium | Medium | RTL audit is a Phase 8 gate with a screenshot pass in both languages; String Catalog parity test |
| R7 | Xcode 27 / iOS 27 lands mid-project and shifts the target | Medium | Low | §2.1 — target the API family, gate with `#available`. Additive by construction |
| R8 | Swift 6 strict concurrency friction in ported code | Medium | Low | Adopted from commit one; `WellnessDomain` is pure value types, the easy case |
| R9 | Scope creep into iPad / watch / HealthKit / CloudKit | **High** | Medium | §15 Q19–21: explicitly out of scope, listed as *unlocked*, not *planned* |
| R10 | Widget extension memory limit exceeded | Low | Medium | §8.3 `WidgetSnapshot` cache; timeline provider tested in isolation |
| R11 | Android users (none today, but the option dies) | — | — | §15 Q1 — accepted, explicitly |

---

## 14. The plan, 0% → 100%

Ten phases. Each has an **exit gate** that is checkable, not a feeling. Phases 0–4
produce no user-visible app; that is intentional and is where the risk actually lives.

### Phase 0 — Freeze, corpus, inventory *(no Swift written)*
1. `docs/ROADMAP.md`: Epic N marked superseded, pointing here.
2. `tool/parity_dump.dart` → `parity/golden/*.json` (§9.1), all 11 corpora.
3. `parity/test_inventory.csv` — all 1,172 rows, `disposition` filled (§9.2).
4. One export from the owner's device → `parity/fixtures/` (§7 path 3).
5. Decide §15's open questions; record answers here.
**Gate:** corpus regenerates byte-identically twice in a row (proves determinism);
inventory has zero blank cells; device fixture imports back into the Flutter app
cleanly.

### Phase 1 — Skeleton and CI
Xcode project, `WellnessKit` SPM package with all seven modules empty but wired,
App Group, entitlements, bundle id matching the Flutter app, signing (team
`R6NSBVKVXV`), the three CI jobs green on an empty `TabView`.
**Gate:** `swift test` green; app launches on device; CI green; module dependency
graph (§3.2) matches `Package.swift` exactly.

### Phase 2 — Models + persistence + migration
`WellnessModels`, `WellnessPersistence`, `SnapshotImporter`, store protocols,
in-memory container for tests, `WellnessCatalog` JSON resources.
**Gate:** device fixture imports with per-collection row count, id-set and checksum
equality; the 6-month demo corpus loads and the analytics-shaped access pattern
benchmarks acceptably (**the SwiftData go/no-go, §3.4**).

### Phase 3 — Domain port *(the big one)*
Every file in §4.1's logic table. Nutrition math → serving kinds → profile/setup →
generators → programming → portion solver → schedule generator → analytics domain.
**Gate:** **every §9.1 corpus replays byte-identically in Swift.** No exceptions
without a corpus diff and a written reason.

### Phase 4 — Services
Notifications, backup, preferences, content language + regeneration, timezone,
background refresh, demo seed.
**Gate:** export→import round-trip over the 6-month corpus matches row counts both
ways (the check `demo_seed_service` already does on every build); notification
scheduling tests green; content-language switch corpus green including the step order.

### Phase 5 — Design system, shell, Liquid Glass
`WellnessUI`: tokens (semantic), the three-layer glass rule + its lint, `TabView`
with the bottom accessory, `NavigationStack` routing, the URL parser, Dynamic Type
baseline.
**Gate:** a walking skeleton — all 5 tabs, all 27 routes reachable with placeholder
content, deep links resolve, accessibility audit clean, Reduce Transparency looks
correct with zero app-side code.

### Phase 6 — Screens
In dependency order, each shipping as a working screen against real data:
Settings → Meals → Workouts → Sleep → Calendar → Analytics → Dashboard → Onboarding.
Onboarding last, because it depends on the setup engine, both generators and the
content-language seed, and is the one flow that must be exactly right on first run.
**Gate per screen:** its XCUITest sanity test passes. **Gate for the phase:** all 23
sanity + 25 regression flows ported and green; the app is fully usable on the owner's
device with migrated data.

### Phase 7 — Widgets, Live Activities, Intents
§8 in full: home + lock widgets, Control Center controls, both Live Activities, App
Intents + Shortcuts + Siri phrases in both languages.
**Gate:** widgets render from migrated real data; workout Live Activity survives a
full session including backgrounding; every intent invocable from Shortcuts.

### Phase 8 — Localization, RTL, accessibility
String Catalog migration + parity test; full RTL pass; Dynamic Type at XXXL;
VoiceOver pass over every screen; accessibility audit in CI.
**Gate:** audit clean on every screen in both languages and both directions; no
truncation at XXXL.

### Phase 9 — Cutover
Device parity session: same data, Flutter build vs Swift build, side by side, over
the areas the docs call out (nutrition totals, generated programs, calendar, backup).
Then the deletion commit (§12), then `docs/` updated — `REPO_GUIDE.md` rewritten,
`CHANGELOG.md`, `STATUS.md`, `SESSION.md`, `RELEASE.md` for a Swift release process,
`TESTING.md` for the new pyramid.
**Gate:** owner signs off after a week of daily use on the Swift build with real data,
**with the Flutter build still installable from `rc`** until they say otherwise.

### Sizing

Rough, and deliberately rough — the useful signal is the *shape*, which is that the
screens are not the expensive part.

| Phase | Share of effort |
|---|---:|
| 0 Freeze/corpus/inventory | 8% |
| 1 Skeleton | 3% |
| 2 Persistence + migration | 10% |
| 3 **Domain port** | **22%** |
| 4 Services | 12% |
| 5 Design system + shell | 8% |
| 6 Screens | 20% |
| 7 Widgets + Live Activities | 9% |
| 8 L10n / RTL / a11y | 5% |
| 9 Cutover | 3% |

Expected output: **~30,000 LOC of Swift** replacing 50,963 LOC of hand-written Dart
(plus 16,917 generated), and roughly 900–1,100 Swift tests replacing 1,172 Dart ones.

---

## 15. Pre-answered questions

Answered as the plan intends them, so that agreeing to the plan settles them.
Anything here can be overruled — but overruling it should be a decision, not a drift.

**Q1. Does Android survive?**
No. "100% Swift" and "an Android app" are mutually exclusive, and `docs/ROADMAP.md`
Epic N's Android half — a genuine Material 3 UI to replace the iOS imitation Android
currently receives — is cancelled with it. This is the single largest thing the
migration gives up. It is also, per the repo's own measurement, a UI that no one is
using today: the app runs on the owner's iPhone. Recorded as accepted, not overlooked.

**Q2. Why not the hybrid in `PLATFORM_UI_ARCHITECTURE.md` (Flutter core, native chrome)?**
Because it was the right answer to a different question. It optimises for keeping
50,963 lines of Dart while renting real glass for the bars. It cannot give real
Liquid Glass on *content-adjacent* surfaces, cannot give Live Activities or
meaningful widgets without duplicating logic in Swift anyway, and leaves a permanent
Pigeon seam. Once "widgets" and "the tab bar accessory hosts a live workout" are in
scope, half the app is Swift regardless — at which point the hybrid is the most
expensive option, not the cheapest.

**Q3. Big-bang rewrite or incremental strangler (Flutter add-to-app)?**
Big-bang **on a parallel branch**, with `rc` staying shippable throughout. A strangler
would need `FlutterEngine` embedded in the SwiftUI app plus a live bridge for shared
state, i.e. building the hybrid *and* the rewrite. The risk a strangler normally
buys down — "the app is broken for months" — is bought down here instead by keeping
the Flutter build installable until Phase 9's gate.

**Q4. Minimum iOS version?**
26.0. Liquid Glass is iOS 26; a lower floor means shipping two designs. The app is
not on the App Store and has one known user, on iOS 27. There is nothing to lose.

**Q5. iOS 27 — when?**
When Xcode 27 is installed. Nothing in this plan blocks on it (§2.1). Adoption is
then a deployment-target bump plus `if #available(iOS 27, *)` branches.

**Q6. Do the nine themes survive?**
As accent tints, not background ramps (§6.3). The custom colour picker survives as
the system `ColorPicker`.

**Q7. Does the Glass Effect Off/Subtle/Full setting survive?**
No. It exists because Flutter had to imitate the material and therefore had to
imitate Reduce Transparency too. iOS owns this. Removing an app setting that
duplicates a system setting is a fix.

**Q8. SwiftData, Core Data, GRDB, or keep the JSON snapshot?**
SwiftData behind store protocols, with a Phase 2 performance gate (§3.4). Core Data
is the same engine with more ceremony. GRDB is the fallback the protocol exists for.
Keeping the JSON snapshot as the live store would carry the debounce/atomic-write/
corruption-quarantine machinery forward for no reason — although the snapshot
*format* is preserved as the migration and backup contract (§7).

**Q9. Riverpod → what?**
`@Observable` + `@Environment` (§3.3). No third-party state library.

**Q10. go_router → what?**
`NavigationStack` with typed route enums per tab, plus a URL parser that keeps
understanding all 27 existing paths for notification and deep-link compatibility (§3.5).

**Q11. Do notifications already scheduled on the device survive?**
They persist (same bundle id) but are **deliberately cancelled and rebuilt** on first
launch after migration, because their payloads were written by a different app (§11).

**Q12. Does the user's data survive?**
Yes — three independent paths, all tested (§7). The original snapshot file is renamed,
never deleted.

**Q13. Is the export/backup file format changing?**
No. Frozen as an interchange contract. A Flutter-era backup restores into the Swift
app. This is a deliberate constraint on the Swift design, not an accident.

**Q14. What happens to the 1,172 tests?**
Every one is dispositioned in a checked-in CSV (§9.2), and the majority of the domain
ones are subsumed by something stronger — a golden corpus that asserts current
behaviour exhaustively rather than selectively (§9.1).

**Q15. How is "we didn't miss anything" actually proven?**
Three artefacts, all checked in: the golden corpus replaying byte-identically
(Phase 3 gate), the inventory CSV with no blank cells (Phase 0 gate), and a
side-by-side device session on real data (Phase 9 gate). Not a claim — three files
and a signed-off session.

**Q16. Third-party Swift packages?**
None. Every current pub dependency has a first-party replacement (§3.6). Adding one
later requires a paragraph here naming the system API that was insufficient.

**Q17. Swift 6 strict concurrency from the start, or later?**
From the start, complete mode. Retrofitting it across 30,000 lines is a project of
its own; adopting it on a pure-value-type domain layer is nearly free.

**Q18. Charts — Swift Charts or keep hand-drawn?**
Swift Charts. The stated reason for hand-writing four `CustomPainter`s was that a
package's theming would be a second source of colour truth. With themes reduced to a
tint (§6.3) that reason evaporates, and Swift Charts brings accessibility, VoiceOver
chart descriptions and audio graphs — which `chart_semantics_test.dart` shows the
project already cares about.

**Q19. iPad?**
Out of scope. SwiftUI makes it far cheaper afterwards (`NavigationSplitView`, size
classes), and nothing in this plan forecloses it. Not a Phase.

**Q20. Apple Watch?**
Out of scope, and genuinely unlocked by this work — a watch app for the workout
session and sleep timer becomes a target that links `WellnessKit`. Listed so it is a
*decision* later, not a surprise scope expansion now.

**Q21. HealthKit / CloudKit sync?**
Both out of scope; both become cheap. HealthKit especially — body weight, sleep and
workouts all have direct HK types and the app already models them. Worth a roadmap
entry after Phase 9, not before.

**Q22. What about the demo seed (`--dart-define=DEMO_SEED=true`)?**
Ported as a `#if DEBUG` build configuration + launch argument. It keeps its
export→import round-trip self-check, which is one of the best tests in the repo and
becomes a Phase 2/4 gate.

**Q23. Does the docs tracking system in `CLAUDE.md` survive?**
Unchanged. `ROADMAP` / `ISSUES` / `REPO_GUIDE` / `CHANGELOG` / `STATUS` / `SESSION`
and the slash commands all keep working; only `REPO_GUIDE.md` needs a full rewrite,
and only at Phase 9.

**Q24. Does `docs/ISSUES.md` come along?**
Yes, triaged at Phase 0 into three buckets: *fixed by the rewrite* (anything about
Flutter chrome, ink ripples, `Material` ancestors, stream-in-`build()`), *must be
ported forward* (real behaviour bugs), and *still open* (content, translation,
design). Bucket 1 is expected to be large.

**Q25. Can the migration be paused?**
Between any two phases, yes — `rc` stays shippable and every phase's output stands
alone. Mid-phase, Phase 3 and Phase 6 are the two that should not be interrupted
partway.

**Q26. Rollback plan?**
`git checkout rc`, build, install. That works at every point until Phase 9's deletion
commit, and after it too, from history. The device fixture in `parity/` means data
can be restored into the Flutter app as well.

**Q27. Do we keep the `wellness_app` name and bundle id?**
Yes, both — bundle id continuity is what makes §7 path 1 and §11 work at all.

**Q28. Live Activities need a paid developer account?**
No. Local Live Activities (no push updates) work with the existing team
`R6NSBVKVXV` setup. Push-updated activities would need APNs; the plan uses
`Text(timerInterval:)` and local updates and does not need it (§8.4).

**Q29. What is the first thing that actually gets built?**
`tool/parity_dump.dart`. Not the Xcode project. The corpus has to be captured from
the Dart while the Dart is still the truth.

**Q30. What is most likely to go wrong?**
R1 — a quiet behavioural divergence in the generators or the analytics aggregators,
where the output looks plausible and is subtly wrong. Everything in §9 exists for
that one risk, and it is why Phase 0 comes before Phase 1.
