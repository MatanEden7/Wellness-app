# Status

Snapshot only — update when overall project status changes, not on every commit.
See `CLAUDE.md` for the doc-tracking rules and `.claude/commands/status.md` /
`big-status.md` / `my-status.md` for how to regenerate this.

Last updated: 2026-08-04

## Current task

Diagnosing one device-suite failure:
`integration_test/regression/nutrition_math_ui_test.dart` — "typing 150g of Chicken
Breast previews and saves the correct macros". 11/12 device tests otherwise pass.

## Snapshot

| Area | Status | Progress |
|---|---|---|
| Fast unit suite | ✅ Green | 259/259 |
| `flutter analyze` | ✅ Clean | 0 errors (info-level style lints only) |
| Device suite | ⚠️ 1 failing | 11/12 |
| `docs/ISSUES.md` open items | 8 remain | 27 fixed, 6 partly-fixed-but-open items closed this pass |
| `docs/ROADMAP.md` epics A–F | Closed except 4 items | A3, B1, B3, C5, F2 need you (see below) |
| `docs/ROADMAP.md` Epic G (perf) | Not started | 6 items, no urgency |

## Waiting on you

| Item | What |
|---|---|
| `docs/ISSUES.md` #49 | Android release keystore |
| `docs/ISSUES.md` #51 | Bundle ID decision (iOS vs Android mismatch) |
| `docs/ROADMAP.md` A3 | Stale-nutrition product decision |
| `docs/ROADMAP.md` B1/B3 | 5-min device checks (sleep notification, sound/vibration) |
| `docs/ISSUES.md` #30/#31, `ROADMAP.md` C5 | Hebrew translator pass |
| `docs/ROADMAP.md` F2 | Weight-unit icon, second opinion |

## ETA

Remaining engineering (excluding "waiting on you" items): none currently queued —
the last batch of roadmap/issue work just closed. Next work is diagnosing the one
device-test failure above (~30 min).

## Next 3 tasks

1. Fix `nutrition_math_ui_test.dart` failure, re-run device suite.
2. Confirm the doc/command restructure (this file, `CLAUDE.md`, `.claude/commands/`)
   is working as intended.
3. Pick up Epic G (performance) or wait on the "waiting on you" items — no fixed order.
