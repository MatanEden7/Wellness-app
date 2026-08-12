# Platform UI Architecture — Flutter core, Material Android, native iOS chrome

Design document. **No implementation until this is agreed** — the roadmap
counterpart is Epic N in `docs/ROADMAP.md`.

Goal: one shared Flutter/Dart application; a Flutter/Material Android UI; an iOS UI
whose *system* layer is genuine SwiftUI/UIKit — including real Liquid Glass — without
rewriting the app in Swift and without a bridge per widget.

---

## 0. Where the codebase actually is today

Verified against the tree on `rc`, not assumed. This matters because the starting
point is not what the request implicitly assumes.

| Fact | Number | Source |
|---|---|---|
| Dart files / LOC | 134 / 57,920 | `find lib -name '*.dart'` |
| Feature UI files | 48 | `lib/features/*/ui/` |
| Domain + data files | 34 | `lib/features/*/{domain,data}/` |
| Service files | 25 | `lib/services/` |
| Files importing `core/ios/` | 22 | `grep -rl core/ios lib` |
| Platform branch sites in Dart | **3** | `routes.dart` ×2, `settings_stub.dart` ×1 |
| Custom Swift in `ios/Runner/` | **0 files** (AppDelegate only) | `find ios/Runner -name '*.swift'` |
| iOS deployment target | **13.0** | `project.pbxproj` |
| Toolchain | Xcode 26.3, iOS 26.2 SDK, sim 26.3 | `xcodebuild -showsdks` |
| Flutter | 3.44.8 (Dart 3.12.2) | `.fvmrc` |

### The three findings that shape everything below

**1. Android currently ships the iOS imitation.** There are only three
platform-branch sites in 134 files, and none of them switch the shell. `AppScaffold`
— a Flutter reproduction of the iOS large-title navigation bar, per its own doc
comment — is the shell for **all 22 shell-using files on both platforms**.
`LiquidGlassTabBar` is a `BackdropFilter` painting a fake glass bar, and Android gets
it too. So this project is not "add native iOS"; it is **split one iOS-flavoured UI
into two real ones**. The Android half is the larger and more overdue piece of work.

**2. The imitation already documents its own ceiling.** From
`lib/core/ios/liquid_glass_tab_bar.dart:26`:

> "It is *not* the genuine system material."

The file goes on to name what it cannot do: edge refraction and the gyroscope-tracked
highlight, both needing a fragment shader with a full-screen texture read per frame.
That is precisely the argument for going native, written by the code itself. It also
means the Flutter path is a *known-good fallback*, not a thing to be ashamed of — it
is what iOS < 26 and Reduced Transparency will use.

**3. Content is Material, chrome is Cupertino-imitated.** `theme.dart` is 46 KB of
Material `ThemeData` with an `_appleize()` pass; content widgets are Material
throughout (`Card` ×171, `SnackBar` ×73, `TextButton` ×55, `ListTile` ×32). The
seam between "app content" and "system chrome" therefore already exists in practice
— it just isn't named. Naming it is most of the refactor.

**4. Flutter 3.44.8 has no Liquid Glass.** The SDK's `src/cupertino/` has gained
`sheet.dart` (`CupertinoSheetRoute`) and `menu_anchor.dart`, but a case-insensitive
search for `liquid`/`glass` across `packages/flutter/lib/src/` returns nothing. Real
glass is only reachable through native APIs. Confirmed, not assumed.

---

## 1. Flutter architecture (shared core)

Unchanged in substance — this layer is already clean and stays 100% shared. Nothing
below the shell learns which platform it is on.

```
models · freezed entities · nutrition math · profile fit
services/ (25)      calendar, notifications, meal/workout generation, export/import
features/*/domain   business rules
features/*/data     repositories + Riverpod providers
l10n/               en + he, RTL
```

**One rule, enforced by test:** nothing under `features/*/domain`, `features/*/data`,
or `services/` may import `dart:io`, `Platform`, or anything from `shell/` or
`bridge/`. A `test/architecture/layering_test.dart` greps for violations. Shared logic
staying genuinely shared is the whole premise; it needs a tripwire, not good
intentions.

Feature UI (`features/*/ui/`, 48 files) stays Flutter on both platforms and stays
**shell-agnostic**: it renders content and declares its chrome *as data*, never as
widgets. Concretely, a page today says

```dart
AppScaffold(title: 'Meals', actions: [NavBarAction(...)], slivers: [...])
```

and afterwards says

```dart
PlatformPage(
  chrome: PageChrome(
    title: l10n.meals,
    largeTitle: true,
    actions: [ChromeAction.add(onTap: ...), ChromeAction.overflow([...])],
  ),
  slivers: [...],   // unchanged Flutter content
)
```

`PageChrome` is a plain data class. On Android the Material shell renders it as an
`AppBar`; on iOS the Cupertino shell forwards it over the bridge to a real
`UINavigationBar`. The 48 content files never branch.

---

## 2. iOS native architecture

### The central mechanism: native chrome *over* Flutter, not Flutter *inside* SwiftUI

The constraint "do not embed the entire application inside SwiftUI" rules out the
obvious approaches, and the remaining one is also the best one:

- ❌ **SwiftUI `TabView` with a `FlutterViewController` per tab** — needs multiple
  engines or engine-group instances, multiplies memory, and loses Flutter navigation
  state across tabs. Rejected.
- ❌ **Flutter `PlatformView` embedding a glass bar into the widget tree** — every
  `UiKitView` is composited into the Flutter scene, which forces platform-view
  compositing overhead and, critically, means the glass samples *only what Flutter
  hands it*, not the live scene. Wrong tool for full-width chrome. (Still the right
  tool for small inline system controls; see §5.)
- ✅ **`FlutterViewController` stays the root; native chrome is layered over it as
  child view controllers in the same window.**

Why this works — the point worth internalising: **Liquid Glass is a property of a
native view sampling what is behind it in the render server**, and Flutter's surface
is just another layer behind it. A `UITabBar` or a `UIHostingController` hosting a
`.glassEffect()` container pinned over the Flutter view gets real refraction, real
specular highlight, real gyroscope response, real Reduced Transparency fallback —
because it *is* the system material, not a picture of one. One engine, one Flutter
view, full state retention, and the app stays Flutter.

```
UIWindow
└── RootContainerViewController
    ├── FlutterViewController            ← the entire app: all content, all logic
    │                                       renders edge to edge, under the chrome
    ├── NavBarHostController             ← UIHostingController, top, glass
    ├── TabBarHostController             ← UIHostingController, bottom, glass
    └── (transient) sheets / menus / alerts presented modally over both
```

Flutter draws **no chrome at all** on iOS. It receives the chrome's occluded insets
over the bridge and reserves scroll padding, which is exactly what `AppScaffold`
already does for its floating bar today (`reservedHeight`) — so the content-side
contract is unchanged.

### Version gating

The installed toolchain is **Xcode 26.3 / iOS 26.2 SDK**. There is no iOS 27 SDK on
this machine, so no iOS 27-only symbol can be compiled today. That is fine and does
not change the design — it is the reason for the rule in §10: target the *API family*,
gate at runtime with `if #available`, and never hardcode a measurement or colour
taken from a screenshot. When the iOS 27 SDK lands, adopting it is a deployment-target
bump plus one new `#available` branch, not a redesign.

Three-tier runtime resolution, decided once at launch in Swift and reported to Dart:

| Tier | Condition | Chrome |
|---|---|---|
| `native.glass` | iOS ≥ 26, Reduce Transparency **off** | Native bars with `.glassEffect` / system glass backgrounds |
| `native.opaque` | iOS ≥ 26 with Reduce Transparency **on**, or iOS 15–25 | Native bars, system-standard opaque/blur material — automatic, we do nothing |
| `flutter.fallback` | Native host failed to attach (defensive) | Existing `lib/core/ios/` Flutter shell, unchanged |

Tier 2 is mostly free: asking UIKit/SwiftUI for a standard bar *already* yields the
correct material for the OS version and accessibility settings. That is the entire
argument for native over imitation, and it is why we must not paint anything
ourselves.

---

## 3. Android architecture

100% Flutter, 100% Material 3, and **independent of the iOS path** — no shared
"adaptive widget" that tries to be both, because that is how the current situation
arose in the first place.

- `NavigationBar` (M3) for the five destinations — not a glass bar, not a floating
  pill.
- `AppBar` / `SliverAppBar.large` for chrome; Material scroll-under elevation, not an
  iOS large-title collapse.
- Material dialogs, `showModalBottomSheet` with drag handles, `SnackBar` for
  transient feedback (73 existing call sites are already correct here and stay).
- Material page transitions, ripple/`InkWell` feedback, back-gesture predictive back.
- `theme.dart`'s Material `ThemeData` becomes Android's real theme rather than a base
  that gets `_appleize()`d. **The `_appleize()` pass is deleted** — it exists only to
  make Material look iOS-ish, which is the bug.

Android quality here is a genuine upgrade, not a port: today Android users get iOS
chevrons, iOS large titles, and a fake glass bar.

---

## 4. What stays Flutter (both platforms)

Everything that is *this app* rather than *this OS*:

- All screen content: dashboard, meals, food catalog, meal/template editors, workouts,
  exercise library, workout session, sleep, sleep timer, calendar grid, analytics
  charts, onboarding, all settings screens.
- Cards, lists, rows, forms, text fields, sliders, steppers, macro rings, charts,
  empty states, all custom components and animations.
- All routing decisions (`go_router` remains the single source of navigational truth
  on both platforms — see §6).
- All 25 services, all domain logic, all models, all localisation.

### Glass on content — reversed, then reversed back (2026-08-12)

**Current rule: content is opaque. Glass belongs to the layer that floats.**

The reversal recorded below stood for one working session. It was undone after
reading Apple's own material rather than reasoning from the screenshots: the
WWDC25 session *Get to know the new design system* names three layers — content,
functional, navigation — and lists **"applying Liquid Glass directly to
content"** as an anti-pattern, with the rule that controls sit *on* system
material and never straight on content.

That is also, precisely, what was wrong on screen. With every card translucent
there was nothing left for the glass to float over, so the material stopped
carrying meaning and the screens read as washed out. The owner asked for the
whole UI to be redesigned properly; this is the load-bearing half of that.

| Layer | What is in it | Material |
|---|---|---|
| Content | cards, list groups, rows, charts, editors | opaque `ContentSurface` |
| Functional | bars, pinned headers, sheets, dialogs, buttons, chips, the date strip, search and segmented controls | `GlassSurface` / `GlassButton` |
| Navigation | native nav bar and tab bar | real UIKit glass |

Enforced, not remembered: `test/architecture/glass_coverage_test.dart` fails the
build if a glass surface appears outside a documented functional file, and if a
surface is hand-painted outside either material.

Three supporting pieces landed with it, each fixing something the audit measured:

* **`lib/core/design/tokens.dart`** — the iOS type ramp (including the 17pt slot
  the theme never had, which is why 20 sites hardcoded it), one 4pt spacing
  scale replacing two that disagreed, concentric radii, and Apple's 44pt tap
  floor.
* **All nine theme ramps re-derived** — background → surface → elevated with
  measured separation. `dark` and `gold` had been byte-identical; `dark` had one
  accent repeated three times; three themes drew their hairlines in 87% white.
  `theme_contrast_test.dart` now pins all of it.
* **The scroll edge effect** (§4a below) — the thing that made a *correct*
  pinned header possible for the first time.

### 4a. Scroll edge

A bar carries no material while content rests against it, and gains the system
material once anything is underneath. iOS derives this from a connected
`UIScrollView`; ours are standalone over a Flutter canvas, so nothing could
observe it — which is why both bars were pinned to a single appearance and the
date strip went through a band, no band, and unpinned before this existed.

`ScrollEdgeObserver` (`lib/core/design/scroll_edge.dart`) reduces the page's
scroll offset to one bit and publishes it two ways: `ScrollEdgeScope` for the
Flutter-drawn bars, and the Pigeon call `setScrollEdge(bool)` for the native
ones, where Swift switches between `configureWithTransparentBackground()` and
`configureWithDefaultBackground()`. The bit is deduped at both ends — it crosses
a platform channel, and one message per scroll frame would be the most expensive
thing in the app.

---

### Superseded: glass on content (the 2026-08-12 reversal)

This section used to read: *"Nothing in this list is wrapped in glass. Per Apple's
guidance and the explicit requirement: glass belongs to the functional navigation
layer. Content sits under the glass and stays legible; it does not become glass. The
existing app already has 171 Cards — if those became glass the design would collapse
into soup."*

**That rule no longer holds.** The owner asked for the whole app to read as glass,
was shown this paragraph and the trade-off it describes, and chose the wider scope
anyway. It is their call, and the reversal is recorded here rather than left as a
silent contradiction between the doc and the code.

What changed in the design so the "soup" risk is actually managed, rather than
ignored:

1. **One material, one file.** `lib/core/ios/glass.dart` is the only place blur,
   saturation, tint and rim highlight are expressed. Every card, list group, sheet
   and Cupertino-tier bar calls `GlassSurface`. There is no second recipe anywhere.
2. **The tint is the theme's own `surface`, at an alpha.** Not a grey film. This is
   what keeps nine themes looking like themselves, and it makes legibility provable:
   the composite of `surface` over `scaffoldBackground` has a luminance between the
   two, and `theme_contrast_test.dart` already pins `onSurface` at ≥ 4.5:1 against
   both — so it clears the bar against everything in between. That test now runs for
   every theme × every glass level, plus the coloured page wash.
3. **The user can turn it down or off.** Settings → Appearance → Glass Effect
   (Off / Subtle / Full). Reduce Transparency forces Off regardless, and drives the
   native bars opaque through `setChromeStyle` too, so chrome and content never
   disagree.
4. **Small tinted things stay opaque**: macro chips, icon badges, progress tracks,
   colour swatches, calendar day dots, chart surfaces. Those are where "everything is
   glass" would genuinely become unreadable, and they are listed as out of scope in
   the plan rather than left to taste.
5. **One `BackdropGroup` per route**, via `GlassLayer`. Every surface uses
   `BackdropFilter.grouped`, so the engine reads the backdrop once per screen instead
   of once per card.

The one rule from this section that did **not** change: this is all still Flutter
painting an imitation. §10's "ask for the material, never draw it" continues to bind
the Swift layer absolutely — the hand-tuned numbers live in Dart, where there is no
system material to ask for, and they must never migrate into `ios/Runner/`.
`shell_guardrail_test.dart` now enforces that rather than merely claiming to.

---

## 5. What becomes native SwiftUI/UIKit (iOS only)

Deliberately short. Each entry earns its bridge by providing behaviour Flutter cannot
reproduce, not merely an appearance.

| Component | Native API family | Why native |
|---|---|---|
| Tab bar (5 destinations) | `UITabBar` / SwiftUI `TabView` chrome, glass background | Real glass, morph-on-scroll, tab-item accessibility, minimise-on-scroll behaviour |
| Navigation bar + large title | `UINavigationBar` large-title, glass scroll edge | Genuine large→inline collapse curve, scroll-edge appearance, Dynamic Type |
| Bottom toolbars / floating action clusters | SwiftUI `.toolbar` + `glassEffect`, `GlassEffectContainer` | Glass grouping/merging between adjacent controls — impossible in Flutter |
| Context menus | `UIContextMenuInteraction` | Real peek/haptics/preview; Flutter's is an imitation |
| Action sheets & alerts | `UIAlertController` | System behaviour, Dynamic Type, VoiceOver ordering |
| System sheets | `UISheetPresentationController` (detents, grabber) | Detents + interactive dismissal + stacked-card scaling |
| Share / export | `UIActivityViewController` | Replaces `share_plus` for iOS export (Epic A already ships export) |
| Date & time pickers | `UIDatePicker` (wheel/compact) | Used heavily in meal times, sleep, calendar; system picker is better and free |
| Haptics | `UIFeedbackGenerator` | Correct impact taxonomy |

### And what does *not* become native — equally important

- ❌ Buttons, cards, rows, list sections inside content. Flutter, both platforms.
- ❌ App-content sheets (meal editor, template editor, food picker). These are full
  Flutter screens; presenting them natively would mean a second Flutter view or a
  Swift rewrite of the editor. **Use Flutter's `CupertinoSheetRoute`** — new in the
  3.44.8 SDK, already gives the stacked-card presentation and interactive dismissal.
  Native sheets are reserved for system-shaped content (share, pickers, alerts,
  action sheets) whose entire body is a system control.
- ❌ Search fields, segmented controls inside page content — `CupertinoSearchField`
  and `CupertinoSlidingSegmentedControl` are close enough that a platform view per
  instance is a bad trade.
- ❌ Anything requiring a `PlatformView` per list row. Compositing cost scales with
  instance count; chrome is O(1), rows are O(n).

Rule of thumb for future additions: **bridge the layer, not the widget.** Four bridges
total, listed next — if a proposal needs a fifth, it needs a paragraph justifying it.

---

## 6. Flutter ↔ native iOS communication

**Pigeon** for everything structural — type-safe, generated on both sides, no
stringly-typed method channels drifting apart. `EventChannel` only for the one
continuous stream (scroll offset for bar morphing), because Pigeon is
request/response.

Four APIs. That is the whole surface.

```dart
// pigeons/chrome.dart  →  generates Dart + Swift

@HostApi()                         // Dart → Swift
abstract class ChromeHostApi {
  void configureTabs(List<TabSpec> tabs);
  void setSelectedTab(int index);
  void setPageChrome(PageChromeSpec spec);   // title, large, back, actions, toolbar
  void setChromeVisible(bool navBar, bool tabBar);
}

@FlutterApi()                      // Swift → Dart
abstract class ChromeFlutterApi {
  void onTabSelected(int index);
  void onChromeAction(String actionId);
  void onBackPressed();
  void onInsetsChanged(ChromeInsets insets);   // top/bottom occlusion
}

@HostApi()                         // Dart → Swift, async replies
abstract class PresentationHostApi {
  @async String? presentActionSheet(ActionSheetSpec spec);   // returns chosen id
  @async bool presentAlert(AlertSpec spec);
  @async String? presentMenu(MenuSpec spec, Rect anchor);
  @async DateTime? presentDatePicker(DatePickerSpec spec);
  @async void presentShare(List<String> paths, Rect anchor);
  void haptic(HapticKind kind);
}

@HostApi()
abstract class CapabilitiesApi {
  Capabilities read();   // osVersion, glassAvailable, reduceTransparency,
}                        // reduceMotion, dynamicTypeScale, darkMode
```

**`go_router` stays authoritative.** The native tab bar does not navigate; it *reports
a tap*. `onTabSelected` → Dart → `context.go(route)` → Dart tells native which tab is
now selected via `setSelectedTab`. One direction of truth, so deep links,
notification taps (already wired in `notification_action_handler.dart`), and the
back stack all keep working unchanged. Same for `onBackPressed` → `context.pop()`.

Swift-side code never imports app logic and never reads app state. It renders what it
is told and reports what was tapped. That isolation is what keeps the Dart business
layer free of platform concerns.

---

## 7. Folder structure

```
lib/
  core/
    platform/
      shell_kind.dart          enum { material, cupertino }
      shell_provider.dart      Riverpod provider — overridable in tests
      capabilities.dart        Dart mirror of CapabilitiesApi + fallbacks
    ui/                        platform-neutral tokens: spacing, type scale, colour roles
    (theme.dart, widgets.dart, utils.dart … unchanged shared helpers)

  shell/
    platform_page.dart         PlatformPage + PageChrome (the data contract)
    platform_actions.dart      dialogs/sheets/menus/share/haptics — one facade,
                               two implementations, called by feature code
    material/                  Android: AppBar, NavigationBar, M3 dialogs & sheets
    cupertino/
      native/                  thin Dart proxies over the bridge
      fallback/                current lib/core/ios/* — iOS < 26 & defensive tier

  bridge/
    generated/                 Pigeon output (checked in)
    chrome_bridge.dart         facade + no-op impl for Android/tests

  features/…/ui/               48 files — content only, shell-agnostic
  services/ · l10n/ · data/    unchanged, fully shared

ios/Runner/
  Chrome/                      TabBarHost.swift, NavBarHost.swift, ToolbarHost.swift,
                               GlassContainer.swift, RootContainerViewController.swift
  Presentation/                Sheets.swift, Menus.swift, Alerts.swift, Share.swift,
                               DatePicker.swift, Haptics.swift
  Bridge/                      Pigeon generated + ChromeHostApiImpl.swift
  Support/                     Availability.swift, CapabilityReporter.swift
  AppDelegate.swift            wires RootContainerViewController

pigeons/chrome.dart            the schema, single source for both sides
```

`lib/core/ios/` is **not deleted** — it moves to `shell/cupertino/fallback/` and keeps
earning its place as the iOS < 26 and defensive tier. Its 8 files are good code; they
were only ever wrong about being the *only* tier.

---

## 8. How the platform UI is selected

Not with `Platform.isIOS` sprinkled through feature code — that is unreadable and
untestable. One resolution, injected:

```dart
final shellKindProvider = Provider<ShellKind>((ref) =>
    defaultTargetPlatform == TargetPlatform.iOS
        ? ShellKind.cupertino
        : ShellKind.material);
```

- Resolved **once**, at `WellnessApp` build, and passed down through the widget tree.
- Feature code never reads it. Feature code uses `PlatformPage` and
  `PlatformActions`, which resolve it internally.
- Tests override the provider, so the **existing 606 fast tests run against either
  shell** by changing one line — and new tests run the important screens against
  both. This is the single most valuable property of the design: it keeps the fast
  suite meaningful after the split, instead of forcing everything onto the simulator.
- The native tier resolves separately inside the Cupertino shell (§2), so a simulator
  running iOS 26 and a device running iOS 18 both work without a rebuild.

macOS (present in the tree) follows `ShellKind.cupertino` with the fallback tier — no
native chrome work planned.

---

## 9. Limitations and performance

Stated plainly, because several are real costs rather than caveats.

1. **Compositing two render systems.** Native glass over the Flutter surface means the
   render server samples Flutter's layer every frame. Cheap for two bars; ruinous if
   glass were applied per card. This is a performance argument for the same
   restraint Apple's design guidance asks for — they happen to agree.
2. **`flutter test` cannot see native chrome.** Widget tests assert on the fallback or
   Material shell; native chrome needs XCUITest or `integration_test` with native
   assertions on a simulator. Mitigation: the chrome contract is a *data class*
   (`PageChrome`), so what a page *declares* is fast-testable even when what iOS
   *renders* is not. Test the contract in `test/`, test the rendering on device.
3. **No hot reload for Swift.** Chrome iteration costs a full rebuild. Keep Swift thin
   and dumb; keep decisions in Dart.
4. **Insets and keyboard.** Chrome occlusion must be pushed to Dart
   (`onInsetsChanged`) and re-pushed on rotation, Dynamic Type change, and keyboard
   show/hide. Getting this wrong produces content under the tab bar — the most likely
   category of bug in this whole plan.
5. **VoiceOver focus order** across the Flutter/native boundary is not automatic;
   focus grouping needs explicit ordering so the sequence is nav bar → content → tab
   bar.
6. **RTL.** The app ships Hebrew. Native bars follow the system language, Flutter
   follows `AppLocalizations` — if the user picks Hebrew in-app while the device is
   English, the two disagree. Chrome must be told the app locale explicitly via
   `PageChromeSpec`, and semantic direction forced on the native side.
7. **iOS deployment target is 13.0** and must rise (15.0 proposed) for modern hosting
   APIs; glass itself is runtime-gated so this does not force iOS 26.
8. **No iOS 27 SDK installed** (Xcode 26.3 / iOS 26.2). iOS 27-specific API cannot be
   compiled here today; §10 is how that stops mattering.
9. **Two UIs to maintain.** Honest cost: every chrome change is now two changes. The
   `PageChrome` data contract keeps it to *chrome* changes only — content changes
   remain single-edit, and content is ~48 of the ~56 UI files.
10. **Migration risk.** 22 files use `AppScaffold` and 606 tests depend on current
    structure. Sequencing in Epic N keeps the app shippable at every step; no
    big-bang cutover.

---

## 10. Staying correct as Apple changes Liquid Glass

The failure mode to design against: hardcoding iOS 26.2's appearance and having it
look wrong-but-confident on iOS 27.

- **Ask for the material, never draw it.** No blur radii, tint alphas, corner radii,
  or highlight gradients in Swift for anything the system provides. Use
  `.glassEffect()` / standard bar appearances and let the OS decide. Concretely: the
  hand-tuned constants in today's `liquid_glass_tab_bar.dart` (0.55/0.42 tints,
  hairline highlights) exist **only** in the fallback tier and never migrate to the
  native tier.
- **No `if osVersion == 26` styling.** Only `if #available(iOS 26, *)` capability
  branches choosing *which API*, never *which pixel values*.
- **`GlassEffectContainer` for grouping**, so adjacent controls merge/morph the way
  the OS defines, and any change to that behaviour arrives for free.
- **One adapter file per component** (`TabBarHost.swift` etc.), each with a single
  `@available`-gated seam. Adopting a new OS is "add a branch in N small files", and
  N is small by construction because there are only four bridges.
- **Never mirror system colours into Dart.** Dart sends semantics (title, action ids,
  selected index) and receives insets. It never learns what glass looks like, so it
  can never be wrong about it.
- **Fallback tier is permanent infrastructure**, not a temporary shim — it is what
  makes runtime gating safe and what makes the fast test suite work.
- **Adoption checklist for a new iOS SDK**: bump SDK → run device suite on the new
  simulator → look for `#available` opportunities in the ~6 `Chrome/` files → verify
  Reduce Transparency / Reduce Motion / Dynamic Type XL still behave. No Dart changes
  expected. If a new SDK requires Dart changes, the isolation has leaked and that is
  the bug to fix.

---

## Open questions — need your decision before Epic N starts

1. **iOS deployment target: 13.0 → 15.0?** Needed for clean view-controller hosting.
   Drops iPhone 6s/7 era. (Recommend yes.)
2. **Android visual direction: Material 3 defaults, or keep the current custom
   palette?** `theme.dart` has light/dark/gold custom themes. Recommend: keep the
   palette and the theme picker, drop `_appleize()`, adopt M3 *component shapes*.
3. **Scope of the first native piece.** Recommend tab bar only (N2), shipped and
   lived with, before the nav bar — it is the highest glass payoff and the lowest
   coupling to the 22 `AppScaffold` files.
4. **`share_plus` → `UIActivityViewController` on iOS?** Export already works via
   `share_plus`; switching is small but touches shipped functionality. Recommend
   deferring to N3, not doing it opportunistically.
