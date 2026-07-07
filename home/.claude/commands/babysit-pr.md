---
description: Babysit a PR on a self-paced loop until it's mergeable (CI, base drift, reviews, body)
argument-hint: "[pr number | url | branch] (defaults to current branch's PR)"
---

Babysit the pull request identified by `$ARGUMENTS` (if empty, the PR for the
current branch) by running the `pr-babysitter` agent on a self-paced loop.

The loop control — the `STATUS:` vocabulary and the `ScheduleWakeup` cadence — is
defined once in `~/.claude/LOOP-PROTOCOL.md`. Follow it; the specifics below are
just this command's bindings.

Each iteration:

1. Spawn the `pr-babysitter` agent for ONE sweep of the PR. Pass `$ARGUMENTS`
   through as the target; if it's empty, tell the agent to resolve the PR for the
   current branch.
2. Relay the agent's status summary back to me concisely — what it fixed/pushed,
   and anything it's surfacing for me to decide.
3. Read the agent's terminal `STATUS:` line and act on it per the loop protocol:
   `WORKING` → reschedule (`prompt` = `/babysit-pr $ARGUMENTS`); `DONE` → tell me
   it's ready and stop; `WAITING` → stop and say exactly what needs me; error → stop
   and report. (`pr-babysitter` emits only DONE/WORKING/WAITING — no BLOCKED.)
