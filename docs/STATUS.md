# Status

Snapshot only — update when overall project status changes, not on every commit.
See `CLAUDE.md` for the doc-tracking rules and `.claude/commands/status.md` /
`big-status.md` / `my-status.md` for how to regenerate this.

Last updated: 2026-08-07 (analytics screen)

## Current task

None. The analytics screen is complete, bilingual and VoiceOver-readable,
reachable from the dashboard header (`/analytics`): goals-together hero chart,
nutrition, training, strength with plateau detection, body weight, sleep, and
generated insights. Body weight is a new tracked entity and is in the backup.
Planned in `docs/ANALYTICS_PLAN.md`.

Five bugs closed the same day (ISSUES #73–#77), three of them found by *running*
rather than by reading: #76 by testing against real generated localisations,
and #77 — custom foods and exercises could not be saved on a phone at all — by
running the full integration suite.

Fast suite green at 606. Device suite green: 9/9 sanity, 4/4 regression
(including four new onboarding→schedule flows), 3/3 e2e. `flutter analyze
lib/ test/` clean.

**The release build is installed on the iPhone** (`com.matan.wellnessx123`,
via `xcrun devicectl` — `flutter install` cannot find its own bundle here).
Everything above was verified on the simulator; the device itself has had the
build put on it but has not been driven through a manual pass.

## Snapshot

| Area | Status | Progress |
|---|---|---|
| Fast unit suite | ✅ Green | 606/606 |
| `flutter analyze` | ✅ Clean | 0 errors (info-level style lints only) |
| Device suite | ✅ Green | 16/16 sanity+regression, plus 3/3 e2e (2 need an attended permission tap) |
| Analytics screen | ✅ Shipped | EN+HE, a11y labelled, exercised by an integration flow |
| `docs/ISSUES.md` open items | 5 remain | all 5 need the user — see below |
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
