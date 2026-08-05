# Status

Snapshot only — update when overall project status changes, not on every commit.
See `CLAUDE.md` for the doc-tracking rules and `.claude/commands/status.md` /
`big-status.md` / `my-status.md` for how to regenerate this.

Last updated: 2026-08-05 (content architecture pass)

## Current task

None. Epic H (content fits the profile) is complete, and the two smallest Epic G
performance items are done. Everything still open needs you — see below.

## Snapshot

| Area | Status | Progress |
|---|---|---|
| Fast unit suite | ✅ Green | 336/336 |
| `flutter analyze` | ✅ Clean | 0 errors (info-level style lints only) |
| Device suite | ⚠️ Stale | 12/12 passed on 2026-08-04; not re-run since (no simulator runs without an explicit request) |
| `docs/ISSUES.md` open items | 8 remain | all 8 need the user — see below |
| `docs/ROADMAP.md` epics A–F | Closed | except the 4 user-blocked items below |
| `docs/ROADMAP.md` Epic H | ✅ Complete | tagging, filtering, regeneration all shipped |
| `docs/ROADMAP.md` Epic G (perf) | 2 of 6 done | G1/G2/G3/G5 remain — real but low-urgency |

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

No engineering work currently queued. Epic G (performance) is the only unblocked
work left and is ~1–2 days end to end, or pickable one item at a time.

## Next 3 tasks

1. Review the edit-path fixes (ISSUES.md #63–67) — 3 of them were user-visible.
2. Re-run the device suite when convenient (it has not run since the #63–67 fixes;
   `nutrition_math_ui_test.dart` passed after its fix, the rest are untouched by
   these changes but unverified together).
3. Start Epic G, or clear the user-blocked items above — no dependency between them.
