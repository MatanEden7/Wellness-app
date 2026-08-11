# Status

Snapshot only — update when overall project status changes, not on every commit.
See `CLAUDE.md` for the doc-tracking rules and `.claude/commands/status.md` /
`big-status.md` / `my-status.md` for how to regenerate this.

Last updated: 2026-08-09 (iOS UI shell, verified on device)

## Current task

None. Every screen in the app is now built from the shared iOS kit in
`lib/core/ios/` — collapsing large titles, nav-bar actions instead of floating
buttons, action sheets instead of overflow menus, swipe-to-delete, inset
grouped lists. Meals and workouts are structurally identical: day-anchored
home screen, templates screen, catalog/library screen, matching routes.

Five bugs fell out of it: ISSUES #85–#89. Three were serious and were only
found by *running* the app — the meals and workouts screens rendered blank
(#87) and every iOS glyph was a tofu box (#88).

Fast suite green at 1019, including a new `page_smoke_test.dart` that renders
all 22 screens at phone size and fails on any layout exception — the gap that
let #87 ship. `flutter analyze` clean. Screens verified visually on the
simulator: dashboard, meals, workouts, food catalog.

**The `integration_test/` device suite still has not been run** since the
conversion; its finders were updated for the new chrome but not confirmed.
That is the one open thread.

## Snapshot

| Area | Status | Progress |
|---|---|---|
| Fast unit suite | ✅ Green | 1022/1022 (incl. 22-screen smoke test) |
| `flutter analyze` | ✅ Clean | 0 errors (info-level style lints only) |
| Device suite | ⚠️ Not re-run | finders updated for the new iOS chrome; needs a simulator pass |
| Analytics screen | ✅ Shipped | EN+HE, a11y labelled, exercised by an integration flow |
| `docs/ISSUES.md` open items | 5 remain | all 5 need the user — see below |
| iOS UI shell | ✅ Shipped | every page on `lib/core/ios/`; meals ≙ workouts |
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

1. Device pass on notifications (ROADMAP B1/B3/B4) — #69 changed real runtime
   behaviour (action routing, the rest-timer beep, reschedule-on-toggle) and only
   a device can confirm the OS side of it.
2. Re-run the device suite — it has not run since the #63–67 or #69 changes.
   `notification_action_handler_test.dart` is the one most likely to be affected:
   `lib/core/notifications.dart` is gone and the rest-timer call moved.
3. Start Epic G, or clear the user-blocked items above — no dependency between them.
