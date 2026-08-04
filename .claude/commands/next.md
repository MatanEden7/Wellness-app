Return the next few tasks worth picking up, ordered by priority then ease.

Pull from `docs/ISSUES.md` (Open/Partly-fixed, Owner blank) and `docs/ROADMAP.md`
(not-`[DONE]`, Owner blank) — skip anything tagged **me**, that's not a "next task" for
this session.

Format:

| # | Task | Source | Est. |
|---|---|---|---|

Up to 5 rows. If fewer than 5 unblocked items exist, say so rather than padding with
**me**-tagged items.
