Give a short current-state snapshot. No prose, no preamble.

Re-derive the numbers — don't quote a stale answer from earlier in the conversation.
Run `flutter analyze` / `flutter test test/` if results might be stale; skip re-running
if they were just run in this same conversation.

Output exactly this shape:

**Current task:** one line, or "none in progress."

| Area | Status |
|---|---|
| Fast suite | ✅/⚠️/❌ X/Y |
| `flutter analyze` | ✅/⚠️/❌ |
| Open issues (`docs/ISSUES.md`) | count |
| Open roadmap items (`docs/ROADMAP.md`) | count |

**Next:** up to 3 tasks, one line each.

That's it — for the full breakdown use `/big-status`, for only what needs the user use
`/my-status`.
