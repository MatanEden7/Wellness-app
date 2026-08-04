Report-only review of the current diff (uncommitted changes, or a range if given as an
argument). Do not fix anything — this command is for surfacing findings, not applying
them.

Check for:
- correctness bugs
- architecture issues (wrong layer, duplicated state, provider misuse)
- duplicated logic that should reuse an existing widget/provider/service
- missing localization (hardcoded user-facing strings — should go through
  `AppLocalizations`)
- accessibility gaps (icon-only buttons without a `tooltip`, missing `Semantics`)
- performance issues (calculations inline in `build()`, missing `.select()`,
  unnecessary rebuilds)

Rank findings by severity. Cite `file:line`. If nothing's wrong, say so — don't invent
findings to fill space.

For a deeper, multi-agent pass use the `/code-review` or `security-review` skills
instead — this command is the quick pass for what's in flight right now.
