Draft a short implementation plan for the task described as this command's argument
(or the most recent request in conversation, if none given).

Only worth a plan when the task involves one of: multiple files across different
layers (widget + provider + repository, not just "two widgets"), an architecture
change, a state-management change, a database/model change, or a routing change.
Otherwise skip this and just implement.

Output at most 6 bullets: what changes, in which files, in what order, and the one or
two decisions that could go either way (flag those explicitly rather than picking
silently).

Don't start implementing until the plan is confirmed.
