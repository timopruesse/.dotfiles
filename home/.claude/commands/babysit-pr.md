---
description: Run one pr-babysitter sweep on a PR (CI, base drift, reviews, body)
argument-hint: "[pr number | url | branch] (defaults to current branch's PR)"
---

Spawn the `pr-babysitter` agent to do ONE sweep of the pull request identified by
`$ARGUMENTS`. If `$ARGUMENTS` is empty, tell the agent to resolve the PR for the
current branch.

The agent auto-fixes and pushes deterministic failures (CI, lint, type, clean
rebase, stale PR body) and surfaces judgment calls (human review comments, real
merge conflicts) without acting on them. It ends with a `STATUS: DONE/WORKING/
WAITING` line.

Relay the agent's status summary back to me. Do not loop on your own — for
continuous babysitting I'll wrap this in the /loop skill, e.g.
`/loop 5m /babysit-pr $ARGUMENTS` (stop when the sweep reports `STATUS: DONE`).
