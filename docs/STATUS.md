# Status

Snapshot only — update when overall project status changes, not on every commit.
See `CLAUDE.md` for the doc-tracking rules and `.claude/commands/status.md` /
`big-status.md` / `my-status.md` for how to regenerate this.

Last updated: 2026-08-21 (Swift migration cutover)

## Current task

Branch `swift`: **Flutter removed, native Swift app is the shipping codebase.**

All 9 phases of the Swift migration plan (`docs/SWIFT_MIGRATION_PLAN.md`)
executed. The Flutter codebase (`lib/`, `test/`, `integration_test/`, `android/`,
`ios/Runner/`, `macos/`) has been deleted from this branch in a single commit.
It remains intact on `rc` and `main`.

## Health

| Area | Status |
|---|---|
| SPM build (`swift build`) | Green — 46 tests pass |
| Xcode build (WellnessApp) | Clean on iPhone 17 simulator |
| Xcode build (WellnessWidgetsExtension) | Clean |
| Localization | 915 keys × en/he, parity test green |
| Flutter (`rc` branch) | Untouched, 1172 tests |

## What shipped

| Phase | Commit | Content |
|---|---|---|
| 1 Skeleton | SPM package + Xcode project + app shell |
| 2 Models + Persistence | Value types, SwiftData @Model, store protocols |
| 3 Domain | Nutrition math, setup engine, all generators |
| 4 Persistence | SwiftDataStore actor, container factory |
| 5 Services | Backup, preferences, notifications, demo seed |
| 5b Design + Stores | @Observable stores, walking skeleton |
| 6 Screens | All real screens wired to stores |
| 7 Widgets | 9 widgets, 2 Live Activities, 4 App Intents |
| 8 Localization | 915-key String Catalog, L10n helper, parity tests |
| 9 Cutover | Flutter deletion, docs rewrite |

## Open for me

- Hebrew translation review (Claude-written, not translator-verified)
- Week of daily use on Swift build with real data before final sign-off
