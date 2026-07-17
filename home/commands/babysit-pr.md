---
description: Babysit a PR on a self-paced loop until it's mergeable (CI, base drift, reviews, body)
argument-hint: "[pr number | url | branch] (defaults to current branch's PR)"
---

Babysit the pull request identified by `$ARGUMENTS` (if empty, the PR for the
current branch) by running the `pr-babysitter` agent on a self-paced loop.

The loop control — the `STATUS:` vocabulary and the `ScheduleWakeup` cadence — is
defined once in `~/protocols/LOOP-PROTOCOL.md`. Follow it; the specifics below are
just this command's bindings.

## Mode

Launched inside a `/ship` / `--auto` chain, this command inherits mode **B**
(pre-authorized) from session context per
[`~/protocols/HANDOFF-PROTOCOL.md`](../protocols/HANDOFF-PROTOCOL.md) — `pr-babysitter` may then
**conditionally auto-merge**. Invoked standalone (typed directly), it's mode
**A**: no auto-merge, ever, regardless of how clean the PR looks.

Each iteration:

1. Spawn the `pr-babysitter` agent for ONE sweep of the PR. Pass `$ARGUMENTS`
   through as the target; if it's empty, tell the agent to resolve the PR for the
   current branch. Tell it which mode is active — only under mode B may it
   consider the conditional auto-merge.
2. Relay the agent's status summary back to me concisely — what it fixed/pushed,
   and anything it's surfacing for me to decide. If the agent returned a
   **non-blocking pick-list** (optional human suggestions + bot nitpicks that
   aren't gating merge), present it to me as a numbered menu and invite me to
   pick which — if any — to address (reply with numbers, or `none`). On my pick,
   apply only the selected items via `worker` behind a preview gate (with the
   `verifier` gate for any behavior-changing fix per the model-routing rules),
   push, and keep the loop going; unpicked items are dropped. Never fix them
   unprompted — the point of the list is that I choose.
   Then, **for each picked item whose fix actually landed** (committed + pushed;
   `verifier` did not return `BREAKS`), post a short acknowledgement reply to
   that item's review thread — "Done in `<sha>` — <one line>", using the thread
   reference the agent carried on the item — and resolve the thread. Post +
   resolve **only** on the applied fix: if `verifier` returned `BREAKS` and you
   held the push, or the reply wouldn't make sense for that comment, leave the
   thread untouched and surface it instead. This is the one place the PR path
   posts on my behalf, and it's scoped to work I objectively completed.
3. Read the agent's terminal `STATUS:` line and act on it:

   - **`STATUS: WORKING`** — reschedule per the loop protocol (`prompt` =
     `/babysit-pr $ARGUMENTS`).
   - **`STATUS: DONE`** (mergeable + approved) — tell me it's ready to merge and
     stop. Mode A never auto-merges here; this is the offer, not the act. If I
     confirm I've merged it — now, or on a later sweep that observes the PR's
     GitHub state as `MERGED` — offer the Ready-for-Release Jira transition per
     HANDOFF-PROTOCOL's lifecycle mapping, one line, only fired on my `go`.
   - **`STATUS: MERGED`** (mode B only — `pr-babysitter` merged the PR because
     every condition in HANDOFF-PROTOCOL's conditional auto-merge held) — fire
     the post-merge Jira transition (In Review → Ready for Release) per the
     protocol's lifecycle mapping (resolve the target status by intent at
     runtime, idempotent + forward-only, skip gracefully if it's unavailable),
     then stop the loop. Merged is terminal success; don't reschedule.
   - **`STATUS: WAITING`** — stop and say exactly what needs me.
   - Anything else (no target found, MCP/`gh`/auth error, agent failed) — stop
     and report the problem. Never reschedule on an error.
