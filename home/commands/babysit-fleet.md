---
description: Babysit ALL your open PRs on one self-paced fleet loop until each is mergeable
argument-hint: "[optional gh search qualifiers, e.g. repo:owner/name]"
tier: mid
---

Babysit every open PR I authored, as a single fleet loop over the existing
`pr-babysitter` agent.

The `STATUS:` vocabulary and the `ScheduleWakeup` cadence are defined once in
`~/protocols/LOOP-PROTOCOL.md`. This command applies that protocol to the fleet as a
whole rather than to a single PR.

## Mode

Launched as part of a mode-B fleet run (e.g. a hub's `ship <nums>`), this
command inherits mode **B** (pre-authorized) from session context per
[`~/protocols/HANDOFF-PROTOCOL.md`](../protocols/HANDOFF-PROTOCOL.md) — every fanned `pr-babysitter`
sweep may then **conditionally auto-merge** its PR. Invoked standalone, it's
mode **A**: no sweep auto-merges.

Each iteration:

1. Find my open PRs: `gh search prs --author=@me --state=open $ARGUMENTS`. If
   none, say so and stop. **The active set is the PRs still worth sweeping** — on
   the first iteration that's all of them; on a reschedule it's only the ones that
   were `WORKING` last tick (see step 4). Carry the active set across wakeups in the
   session context.
2. Fan out ONE `pr-babysitter` sweep per PR **in the active set**, in parallel (a
   single message with multiple Agent calls), passing each PR's number and which
   mode is active — only under mode B may a sweep consider the conditional
   auto-merge. Each sweep is stateless and self-contained: it auto-fixes+pushes
   deterministic failures, self-verifies its own code fixes via the `verifier`,
   trips its own anti-flail guard, and surfaces review comments / real conflicts as
   `WAITING`. Do NOT re-sweep PRs that went terminal (`DONE`/`WAITING`/`MERGED`) on
   a prior tick — they're off the loop, exactly as a single `/babysit-pr` self-
   terminates on those; re-checking a human-blocked PR every tick just burns sweeps.
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
   merged PR is done, not something to keep sweeping. Drop every terminal PR
   (`DONE`/`WAITING`/`MERGED`) from the active set; the next tick's active set is
   just the PRs that came back `WORKING`. If ANY PR is `WORKING`, reschedule the
   next fleet iteration (`prompt` = `/babysit-fleet $ARGUMENTS`), then stop the
   turn. **Pace the reschedule by the fleet's aggregate flavor** (per
   `LOOP-PROTOCOL.md`): keep the tight cadence if any surviving `WORKING` PR is
   `progress` or near-terminal; back off (270 → 540 → 900) only when *every*
   surviving `WORKING` PR is `pending`. If EVERY PR is `DONE`/`WAITING`/`MERGED`
   (none `WORKING`), do NOT schedule — give me the final roll-up, calling out every
   PR that needs my attention (and confirming which ones merged).

One loop, one wakeup — not one loop per PR. A fast-moving PR waits at most one
tick behind the others, which is fine at this cadence. Because terminal PRs leave
the active set, a long-running fleet narrows to just the PRs still in motion
instead of re-sweeping the whole set every tick.
