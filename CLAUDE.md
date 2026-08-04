# CLAUDE.md

Tracking system for this repo — what documentation exists, when to update it, and
what each slash command does. Nothing here restricts general coding style, testing
practice, or communication — those come from the standing Claude Code setup, not
this file, so a change to how I work elsewhere doesn't get silently overridden here.

## Docs

| File | Purpose | Update when |
|---|---|---|
| `docs/ROADMAP.md` | Planned work, grouped by epic, priority-tagged | a milestone changes, a feature completes, priorities shift |
| `docs/ISSUES.md` | Bug/issue inventory with fix status | a bug is found, fixed, or its priority changes |
| `docs/REPO_GUIDE.md` | Architecture, data flow, how the codebase works | architecture, folder structure, services, or providers change |
| `docs/CHANGELOG.md` | What shipped, most recent first | a feature or fix completes |
| `docs/STATUS.md` | Current snapshot: health, what's open, what's waiting on the user | overall project status changes — not every commit |
| `docs/SESSION.md` | Log of work sessions: current / last / next task | after every completed session |

Reference-only, not part of the auto-tracked set above — read them, but they don't
get a standing "update when" trigger: `docs/WELLNESS_APP_SPEC.md` (original design
spec), `docs/RELEASE.md` (release checklist), `docs/TESTING.md` (test-suite
reference).

`docs/ROADMAP.md` items and `docs/ISSUES.md` rows both use an **Owner** convention:
unmarked = mine to implement, **me** = needs the user specifically (a decision, a
credential, a manual device check, a translation/design call).

## Commands

Each is fully specified in its own file — this list is just an index.

| Command | What it does |
|---|---|
| `.claude/commands/status.md` | Short current-state table |
| `.claude/commands/big-status.md` | Full detail: health + every open item from ISSUES.md/ROADMAP.md |
| `.claude/commands/my-status.md` | Only the items tagged **me** |
| `.claude/commands/next.md` | Top few next tasks |
| `.claude/commands/review.md` | Report-only code review (no rewriting) |
| `.claude/commands/plan.md` | Draft a short implementation plan before a multi-file change |
| `.claude/commands/issue.md` | File or update a `docs/ISSUES.md` entry |
| `.claude/commands/roadmap.md` | View or add to `docs/ROADMAP.md` |
| `.claude/commands/release.md` | Walk the `docs/RELEASE.md` checklist, report done/blocked |
| `.claude/commands/session.md` | Write today's entry in `docs/SESSION.md` |
