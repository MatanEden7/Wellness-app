# Status

Snapshot only — update when overall project status changes, not on every commit.
See `CLAUDE.md` for the doc-tracking rules and `.claude/commands/status.md` /
`big-status.md` / `my-status.md` for how to regenerate this.

Last updated: 2026-08-16 (real UIKit, Apple calendar, Hebrew wiring)

## Current task

None. Branch `feat/liquid-glass-native-ios`, built and installed on the iPhone 17
simulator (iOS 26.3) and on the **Matan Eden** iPhone 15 Pro (iOS 27.0, release
build, team `R6NSBVKVXV`).

The headline finding: **the native presentation bridge was dead code.** The Swift
for alerts, action sheets, menus, date pickers, share and haptics was written and
registered; no Dart ever called it. Everything that looked like an iOS dialog was
Flutter drawing one. That is now wired, so those surfaces are genuinely UIKit.

The second finding: **the Hebrew was mostly already written.** What read as a
translation backlog was overwhelmingly ARB keys that existed and were never
wired — 35 of the 55 literals on the Profile page, and all 28 of its picker
option labels. `#31`'s translator scope is much smaller than the issue list
implied.

## Snapshot

| Area | Status | Progress |
|---|---|---|
| Fast unit suite | ⚠️ Not re-run since the localisation sweep | 1169/1169 at last run |
| `flutter analyze` | ✅ Clean | 0 errors, 0 warnings |
| Device suite — sanity | ✅ Green | 23/23 (was 2/23) |
| Device suite — regression | ✅ Green | 25/25 |
| Device suite — e2e journey | ✅ Green | passes end to end |
| `e2e/notification_scheduling` | ⚠️ Attended only | blocks on the native permission dialog; took 327 min |
| Native presentation layer | ✅ Shipped | alerts, sheets, menus, pickers, share, haptics, banner |
| Calendar | ✅ Shipped | red today, flat time-led rows, S M T W T F S, Today button |
| Onboarding → plan | ✅ Fixed | was silently destroyed mid-generation (#103) |
| Hebrew / RTL | ✅ Largely done | ~60 new keys; units, brands, generated plans all follow language |
| Native chrome test coverage | ❌ None | tests drive the Flutter tier; needs XCUITest |
| `docs/ISSUES.md` open items | 4 remain | all 4 need you |

## Waiting on you

| Item | What |
|---|---|
| `docs/ISSUES.md` #49 | Android release keystore |
| `docs/ISSUES.md` #51 | Bundle ID decision (iOS vs Android mismatch) |
| `docs/ROADMAP.md` A3 | Stale-nutrition product decision |
| `docs/ROADMAP.md` B1/B3/B4 | ~10-min device pass on notifications |
| Hebrew review | The ~60 new strings are mine — a native-speaker pass, not a translation project |
| Provisioning profile | Free-account profile expires **2026-08-18**; the phone build stops launching then |

## Known gaps

* **Validation messages are still English.** `validation.dart` and `utils.dart`
  expose `static` validators used as tear-offs, so localising them means
  changing every signature and call site — a refactor, not wiring.
* **~24 of 59 brand descriptors unmapped** — pack weights like `85g pack`, where
  only the unit carries meaning.
* **Two classes named `AppDateUtils`** (`core/utils.dart`, `core/date_utils.dart`)
  with different members. Callers resolve to whichever they imported unprefixed;
  this bit twice this session. Worth merging.
* **Duplicate label switches.** `_goalLabel` existed in two files with the same
  hardcoded English; fixing one left the other live. Worth a look before
  assuming any label fix is complete.
