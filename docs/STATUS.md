# Status

Snapshot only — update when overall project status changes, not on every commit.
See `CLAUDE.md` for the doc-tracking rules and `.claude/commands/status.md` /
`big-status.md` / `my-status.md` for how to regenerate this.

Last updated: 2026-08-05 (notification audit)

## Current task

None. The notification audit (ISSUES.md #69) is complete: snooze/remove now
reach their handler, the rest timer no longer disables every notification
button, it plays an actual sound, and preference changes re-apply to reminders
already scheduled. Fast suite green. Everything still open needs you — including
one new device check (ROADMAP B4) to confirm the OS honours the action routing.

## Snapshot

| Area | Status | Progress |
|---|---|---|
| Fast unit suite | ✅ Green | 360/360 |
| `flutter analyze` | ✅ Clean | 0 errors (info-level style lints only) |
| Device suite | ⏳ Not re-run | 12/12 on 2026-08-05, before the #69 changes |
| `docs/ISSUES.md` open items | 8 remain | all 8 need the user — see below |
| `docs/ROADMAP.md` Epic B (notifications) | B1/B3/B4 open | all three are device checks — **me** |
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
