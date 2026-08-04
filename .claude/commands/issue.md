File or update an entry in `docs/ISSUES.md` for the bug/issue described as this
command's argument.

**New issue:** append to the summary table (next `#`, a one-line description,
severity, status, time estimate) and add a full write-up in the matching P0–P4
section, matching the existing entries' format: what's broken, where (`file:line`),
consequence, and either **[FIXED]** with the solution or **[OPEN]** with what's needed.
Tag Owner as **me** in the summary table only if it needs the user (decision,
credential, device check, translation) — otherwise leave blank.

**Existing issue:** update its status ([OPEN] → [FIXED], severity, estimate) and add a
short note on what changed. Don't rewrite the historical description of the original
bug — append, don't replace.

Severities: Critical / High / Medium / Low / Trivial — Critical means the app is
broken or data-lossy for a normal user; Trivial means dead code or a typo.
