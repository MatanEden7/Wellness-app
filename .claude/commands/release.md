Walk `docs/RELEASE.md`'s checklist against the current state of the repo — don't just
reprint the file, actually verify each item where that's checkable (grep the code,
check a config file, run a quick command).

Output:

| Item | Status | Blocker |
|---|---|---|

Status: ✅ done / ⚠️ partial / ❌ blocked / **me** (needs the user — credential,
account, external action).

Update `docs/RELEASE.md` itself only if you find an item whose written status no
longer matches reality (mark stale entries, don't silently leave them wrong).
