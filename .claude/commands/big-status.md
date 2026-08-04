Full-detail status. Tables only, minimal prose, in this order:

**0. Latest update** — what was done most recently, bulleted, before anything else.
Note whether it's verified (tests run) or not.

**1. Health** — `Check | Result` — unit tests, device suite (if run recently), `flutter
analyze`, any notable on-device verification.

**2. Remaining — issues** — from `docs/ISSUES.md`, filtered to Open/Partly-fixed only:
`# | Issue | Severity | Owner | Est.`

**3. Remaining — roadmap** — from `docs/ROADMAP.md`, filtered to not-`[DONE]` items:
`ID | Item | Priority | Owner | Est.`

**Owner column:** blank = mine to implement unprompted. **me** = needs the user
specifically — a decision, a credential, a manual device check, a translation/design
call. Never write "you"/"Claude" — blank already means Claude by default.

Close with one bolded line of totals and, at most, one sentence naming the single
biggest gap.

Re-derive the numbers from the actual files and a real test run if anything might be
stale — don't quote an old answer from earlier in the conversation.
