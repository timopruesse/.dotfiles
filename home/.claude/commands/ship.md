---
description: Ship one ticket end-to-end unattended (pre-authorized) — /dispatch --auto, stops only at judgment calls
argument-hint: "<JIRA-KEY> (e.g. ECW-1061)"
---

Ship the Jira ticket `$ARGUMENTS` end-to-end in **pre-authorized (mode B)**: run
the whole PR-lifecycle spine unattended, auto-approving the deterministic gates and
stopping only when something genuinely needs you. `/ship <KEY>` is exactly
`/dispatch <KEY> --auto` — a memorable single-command entry for "take this ticket to
a PR (and merge it if it comes back clean)."

If no key is given, say so and stop — there's nothing to ship without one.

## What this is

The mode-B counterpart to plain `/dispatch`. The spine, the `ADVANCE`/`HALT`
handoff contract, the AUTO-vs-STOP taxonomy, the conditional auto-merge, and the
Jira lifecycle transitions are all defined once in
[`~/.claude/HANDOFF-PROTOCOL.md`](../HANDOFF-PROTOCOL.md). This command just enters
the spine with auto-mode set; the protocol governs everything downstream.

## Run

1. Invoke `/dispatch <KEY> --auto`. That carries auto-mode into the session context;
   every auto-advanced successor inherits it.
2. Let the spine run per the handoff protocol:
   - **local branch:** `/start` → `worker` → `/land` → `/open-pr` (ready-for-review)
     → launch `/babysit-pr` (which, in auto-mode, conditionally auto-merges).
   - **boba branch:** label `boba` → launch `/watch-boba`.
   - At each **AUTO** gate, approve and proceed without asking. At each **STOP** gate
     (design snag, `verifier` BREAKS, `WAITING`, Boba `BLOCKED`, external-blocker on
     a merge candidate, repeated-bail, any error), **`HALT`** — stop, surface exactly
     what needs me, and let the notify hook ping. Never override a STOP.
   - Fire the Jira transitions from the protocol's lifecycle mapping automatically
     (In Progress → In Review → Ready for Release).
3. The synchronous run **ends by launching the async loop** (`/babysit-pr` or
   `/watch-boba`) and returning — it does not block on CI. The loop drives to
   mergeable / merged and pulls me back on `WAITING` / a STOP.

Report what ran, where it landed (open PR + babysitter running, merged, or halted),
and — on any `HALT` — exactly what needs me and how to resume. This is the one place
that acts without per-step confirmation, so state honestly what was done vs. what it
stopped short of.
