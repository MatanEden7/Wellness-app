# Status

Snapshot only — update when overall project status changes, not on every commit.
See `CLAUDE.md` for the doc-tracking rules and `.claude/commands/status.md` /
`big-status.md` / `my-status.md` for how to regenerate this.

Last updated: 2026-08-12 (Liquid Glass pass + native-chrome bug fixes)

## Current task

None. Branch `feat/platform-native-ui` carries two things beyond Epic N: nine
native-chrome bug fixes (`ISSUES.md` #92–#100) and the whole-app Liquid Glass
pass. Built and installed on the iPhone 17 simulator (iOS 26.3).

The headline finding: **glass was never rendering at all.** A standalone
`UINavigationBar`/`UITabBar` tracks no scroll view, so it never leaves its
transparent `scrollEdgeAppearance`. Both bars now assign
`configureWithDefaultBackground()` to every state, and the shells no longer
wrap their scroll view in a `SafeArea` — content passes under the bars, which
is what gives the material something to blur.

Glass is now on every card, list group, sheet, custom dialog and Cupertino-tier
bar, over a theme-derived gradient wash, with a Settings → Appearance →
**Glass Effect** control (Off / Subtle / Full). Reduce Transparency forces Off
and turns the native bars opaque with it.

**Waiting on you: the visual pass.** Everything below is verified by tests and
by the analyzer; how it actually *looks* is not, and that is the one thing a
test cannot answer.

## Snapshot

| Area | Status | Progress |
|---|---|---|
| Fast unit suite | ✅ Green | 1100/1100 (smoke test now covers both shells) |
| `flutter analyze` | ✅ Clean | 0 errors (info-level style lints only) |
| Device suite | ⚠️ Not re-run | finders updated for the new iOS chrome; needs a simulator pass |
| Analytics screen | ✅ Shipped | EN+HE, a11y labelled, exercised by an integration flow |
| `docs/ISSUES.md` open items | 5 remain | all 5 need the user — see below |
| Liquid Glass | ✅ Shipped, unseen | every surface + native bars; **needs your eyes on the simulator** |
| Glass raster cost | ⚠️ Not measured | one `BackdropGroup` per route, but no `--profile` run yet |
| iOS UI shell | ✅ Shipped | every page on `lib/core/ios/`; meals ≙ workouts |
| Native chrome bugs | ✅ Fixed | 9 found by reading the Epic N code (#92–#100) |
| Template breaks | ✅ Shipped | "Customize breaks" switch; break rows draggable anywhere |
| `docs/ROADMAP.md` Epic B (notifications) | B1/B3/B4 open | all three are device checks — **me** |
| Exercise catalog depth | ⚠️ Binding constraint | Calves ×1, Glutes ×2, Biceps ×2 — Leg Day A/B identical at 6 days |
| `docs/ROADMAP.md` epics A–F | Closed | except the 4 user-blocked items below |
| `docs/ROADMAP.md` Epic H | ✅ Complete | tagging, filtering, regeneration all shipped |
| `docs/ROADMAP.md` Epic G (perf) | 2 of 6 done | G1/G2/G3/G5 remain — real but low-urgency |

## Waiting on you

| Item | What |
|---|---|
| `docs/ISSUES.md` #49 | Android release keystore |
| `docs/ISSUES.md` #51 | Bundle ID decision (iOS vs Android mismatch) |
| `docs/ROADMAP.md` A3 | Stale-nutrition product decision |
| `docs/ROADMAP.md` B1/B3/B4 | ~10-min device pass: sleep-goal alert, sound/vibration + the new rest-timer beep, and the Approve/Remove/Snooze buttons #69 unblocked |
| `docs/ISSUES.md` #30/#31, `ROADMAP.md` C5 | Hebrew translator pass |
| `docs/ROADMAP.md` F2 | Weight-unit icon, second opinion |

## ETA

No engineering work currently queued. Epic G (performance) is the only unblocked
work left and is ~1–2 days end to end, or pickable one item at a time.

## Next 3 tasks

1. **Your visual pass on the simulator** — glass, both light and dark, at least one
   non-default theme, and Hebrew/RTL. Turning Glass Effect to Off should give back
   very nearly the pre-glass build, which is the fastest regression check available.
2. `flutter run --profile` and watch the raster thread while scrolling the dashboard
   and the 233-row food catalog. A glass surface outside the shared `BackdropGroup`
   costs a full-screen read and fails no test.
3. Migrate the 12 remaining `AlertDialog` bodies onto `showAppConfirm` (real Cupertino
   vibrancy — they are the last opaque surfaces), then merge the branch.
