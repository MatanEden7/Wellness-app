Return only the items that need the user — never development work Claude can do
unprompted.

Pull every row tagged **me** in the Owner column from `docs/ISSUES.md` and
`docs/ROADMAP.md` (re-derive from the files, don't quote a stale answer).

Format:

| Priority | Item | What's needed | Where |
|---|---|---|---|

"What's needed" is the concrete action: a decision, a credential, a 5-minute device
check, a translation pass — not a restatement of the problem.

If nothing is currently tagged **me**, say so in one line. Don't pad with items Claude
could do instead.
