# Status

Snapshot only — update when overall project status changes, not on every commit.
See `CLAUDE.md` for the doc-tracking rules and `.claude/commands/status.md` /
`big-status.md` / `my-status.md` for how to regenerate this.

Last updated: 2026-08-06 (workout programming)

## Current task

None. Workout programming (ISSUES.md #70) is complete: sessions are programmed
from the goal with real sets, reps, rest and starting weights, sized to a
45-minute budget. The profile and every setting are now in the backup (#71) —
they were in none. Fast suite green at 531.

Nothing in the last two days has been seen on hardware. The new programming
only appears after Settings → Reset all data and a fresh onboarding, which is
the agreed rollout.

## Snapshot

| Area | Status | Progress |
|---|---|---|
| Fast unit suite | ✅ Green | 531/531 |
| `flutter analyze` | ✅ Clean | 0 errors (info-level style lints only) |
| Device suite | ⏳ Not re-run | 12/12 on 2026-08-05, before the #69 changes |
| `docs/ISSUES.md` open items | 8 remain | all 8 need the user — see below |
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
