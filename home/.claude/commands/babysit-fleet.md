---
description: Babysit ALL your open PRs on one self-paced fleet loop until each is mergeable
argument-hint: "[optional gh search qualifiers, e.g. repo:owner/name]"
---

Babysit every open PR I authored, as a single fleet loop over the existing
`pr-babysitter` agent.

The `STATUS:` vocabulary and the `ScheduleWakeup` cadence are defined once in
`~/.claude/LOOP-PROTOCOL.md`. This command applies that protocol to the fleet as a
whole rather than to a single PR.

## Mode

Launched as part of a mode-B fleet run (e.g. a hub's `ship <nums>`), this
command inherits mode **B** (pre-authorized) from session context per
[`HANDOFF-PROTOCOL.md`](../HANDOFF-PROTOCOL.md) — every fanned `pr-babysitter`
sweep may then **conditionally auto-merge** its PR. Invoked standalone, it's
mode **A**: no sweep auto-merges.

Each iteration:

1. Find my open PRs: `gh search prs --author=@me --state=open $ARGUMENTS`. If
   none, say so and stop.
2. Fan out ONE `pr-babysitter` sweep per PR, in parallel (a single message with
   multiple Agent calls), passing each PR's number and which mode is active —
   only under mode B may a sweep consider the conditional auto-merge. Each sweep
   is stateless and self-contained: it auto-fixes+pushes deterministic failures,
   self-verifies its own code fixes via the `verifier`, trips its own anti-flail
   guard, and surfaces review comments / real conflicts as `WAITING`.
3. Collect every sweep's terminal `STATUS:` line and show me a compact per-PR
   roll-up (what each did / is waiting on). For any PR reporting `STATUS: MERGED`
   (mode B only — the sweep merged it because every condition in
   HANDOFF-PROTOCOL's conditional auto-merge held), fire that ticket's
   post-merge Jira transition (In Review → Ready for Release) per the protocol's
   lifecycle mapping (resolve by intent at runtime, idempotent + forward-only,
   skip gracefully if unavailable) before moving on — the command layer, not the
   agent, owns this write.
4. Decide the loop **as a whole** (this is the fleet's one deviation from the
   per-target protocol): treat `MERGED` as terminal, same as `DONE`/`WAITING` — a
   merged PR is done, not something to keep sweeping. If ANY PR is `WORKING`,
   reschedule the next fleet iteration (`prompt` = `/babysit-fleet $ARGUMENTS`) at
   the protocol cadence, then stop the turn. If EVERY PR is `DONE`/`WAITING`/
   `MERGED` (none `WORKING`), do NOT schedule — give me the final roll-up, calling
   out every PR that needs my attention (and confirming which ones merged).

One loop, one wakeup — not one loop per PR. A fast-moving PR waits at most one
tick behind the others, which is fine at this cadence.
