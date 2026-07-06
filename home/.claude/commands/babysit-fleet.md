---
description: Babysit ALL your open PRs on one self-paced fleet loop until each is mergeable
argument-hint: "[optional gh search qualifiers, e.g. repo:owner/name]"
---

Babysit every open PR I authored, as a single fleet loop over the existing
`pr-babysitter` agent.

Each iteration:

1. Find my open PRs: `gh search prs --author=@me --state=open $ARGUMENTS`. If
   none, say so and stop.
2. Fan out ONE `pr-babysitter` sweep per PR, in parallel (a single message with
   multiple Agent calls), passing each PR's number. Each sweep is stateless and
   self-contained: it auto-fixes+pushes deterministic failures, self-verifies its
   own code fixes via the `verifier`, trips its own anti-flail guard, and surfaces
   review comments / real conflicts as `WAITING`.
3. Collect every sweep's terminal `STATUS:` line and show me a compact per-PR
   roll-up (what each did / is waiting on).
4. Decide the loop as a whole:
   - If ANY PR returned `STATUS: WORKING`, schedule the next fleet iteration with
     `ScheduleWakeup`, re-firing this same command: set `prompt` to
     `/babysit-fleet $ARGUMENTS`. Pick a delay under 300s (default ~270s) to keep
     the prompt cache warm. Then stop this turn — the wakeup resumes the fleet.
   - If EVERY PR is `DONE` or `WAITING` (none `WORKING`), do NOT schedule. Stop
     and give me the final roll-up, calling out every PR that needs my attention.

One loop, one wakeup — not one loop per PR. A fast-moving PR waits at most one
tick behind the others, which is fine at this cadence.
