---
description: Babysit a PR on a self-paced loop until it's mergeable (CI, base drift, reviews, body)
argument-hint: "[pr number | url | branch] (defaults to current branch's PR)"
---

Babysit the pull request identified by `$ARGUMENTS` (if empty, the PR for the
current branch) by running the `pr-babysitter` agent on a self-paced loop.

Do this each iteration:

1. Spawn the `pr-babysitter` agent for ONE sweep of the PR. Pass `$ARGUMENTS`
   through as the target; if it's empty, tell the agent to resolve the PR for the
   current branch.
2. Relay the agent's status summary back to me concisely — what it fixed/pushed,
   and anything it's surfacing for me to decide.
3. Read the agent's terminal `STATUS:` line and act on it:
   - **`STATUS: WORKING`** — a fix/update was pushed or checks are still running.
     Schedule the next sweep with `ScheduleWakeup`, re-firing this same command:
     set `prompt` to `/babysit-pr $ARGUMENTS`. Pick a delay that keeps the prompt
     cache warm (under 300s): default ~270s, or shorter (~180s) if the PR looked
     close to green. Then stop this turn — the wakeup will resume the loop.
   - **`STATUS: WAITING`** — blocked on me (review comments, a real conflict, or
     the anti-flail guard tripped). Do NOT schedule another sweep. Stop and tell
     me exactly what needs my attention.
   - **`STATUS: DONE`** — green, approved, mergeable. Do NOT schedule another
     sweep. Tell me the PR is ready and stop.
   - Anything else (no PR found, `gh`/auth error, agent failed) — do NOT schedule.
     Stop and report the problem.

The loop is self-terminating: it only continues on `WORKING`, and stops itself on
`DONE`, `WAITING`, or error. You do not need to wrap this in the /loop skill.
