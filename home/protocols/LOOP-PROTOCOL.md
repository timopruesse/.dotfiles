# Loop protocol

The canonical contract shared by the self-looping commands (`/babysit-pr`,
`/babysit-fleet`, `/watch-boba`, `/my-work watch`) and the classifier agents they
drive (`pr-babysitter`, `boba-watcher`). One definition of the `STATUS:`
vocabulary and the `ScheduleWakeup` cadence, so the loop files don't each
re-derive it.

> **Why the split.** Agents run in isolated context and can't read this file at
> spawn time, so each classifier agent still states the `STATUS:` line it emits in
> its own prompt. This doc is the authoritative definition they emit *against*, and
> it owns the **command-side control loop** — the part that runs in the main
> session (read STATUS → reschedule or stop). Change the cadence or the enum here.

## Loop shapes

All loopers share the underlying **mechanism** — schedule a wakeup that re-fires
the *same slash command* (with its exact arguments) after `delaySeconds`, then
stop the turn; the wakeup resumes the loop. Use the host tool's
`ScheduleWakeup` (Claude Code and Cursor both expose it; Antigravity uses `schedule`). But they come in two
shapes, and only one uses the `STATUS:` contract:

| Shape | Commands | Converges? | Terminal signal | Cadence |
|---|---|---|---|---|
| **Shepherd** | `/babysit-pr`, `/babysit-fleet`, `/watch-boba` | Yes — drives one target to a terminal state | `STATUS:` enum (below); self-terminates on `DONE`/`WAITING`/`MERGED` | minutes, paced by the target's expected time-to-change |
| **Hub** | `/my-work watch` | No — the queue refills; there is no "done" | A per-tick roll-up (`CHANGES` / `AUTO-ACTED`), **not** `STATUS:`; terminates on your action or an empty queue | idle-tick, ~15–30 min |

The **shepherd** sections below (`STATUS:`, cadence, self-termination) apply to
shepherd loops. A **hub** loop borrows only the re-fire mechanism: it would be a
lie for it to emit a `STATUS:` line — every tick is perpetually "working" because
the hub never arrives. With no terminal-state race, hub state moves on a
minutes-to-hours scale, so it uses the idle-tick regime (`delaySeconds` ≈ 1200).
The hub's own vocabulary and control flow live in its command file (`/my-work watch`).

## The `STATUS:` contract

Every loop sweep (one agent invocation) ends with exactly one terminal line the
driving command reads:

| STATUS | Meaning | Command does |
|---|---|---|
| `WORKING` | Progress to wait on. The agent marks one of two flavors: **progress** (a fix/rebase/body update was pushed *this* sweep) or **pending** (nothing to do — checks/analysis still running, no failure to fix). | **Reschedule** — but the cadence depends on the flavor (see below). |
| `DONE` | Terminal success — the loop's goal is reached (PR mergeable, or Boba opened a PR). | **Stop.** Hand off if the flow specifies one (e.g. `boba-watcher` DONE → `/babysit-pr`). |
| `WAITING` | Blocked on a human — review comments, a real conflict, anti-flail tripped, or a human took the ticket over. | **Stop.** Say exactly what needs the human. |
| `BLOCKED` | *(Boba only)* Boba bailed for more info. | Run the command's gated unblock path; do **not** treat as WORKING. |

Anything else (no target found, MCP/`gh`/auth error, agent failed) → **stop** and
report the problem. Never reschedule on an error.

## The `ScheduleWakeup` cadence

On `WORKING` (and after a confirmed Boba unblock), schedule the next sweep by
re-firing the **same command** — set `prompt` to the exact invocation
(`/babysit-pr …`, `/babysit-fleet …`, `/watch-boba …` with the same args the
current run received).

> **What actually costs tokens per tick.** The dominant cost is the **sweep
> agent** — a fresh `pr-babysitter` (mid) / `boba-watcher` (cheap) invocation
> whose context is not cached; the wakeup turn itself is cheap. So a tight cadence
> is worth paying only when a terminal-state race is live (something changed, or a
> flip is imminent); while purely idle-waiting it just burns sweeps. Never
> schedule a wakeup to keep a prompt cache warm — pace by how fast the target
> actually changes. Hence the flavor split:

- **Match the delay to the target's expected time-to-change.** A CI run that takes
  ~8 minutes deserves one check around then, not several short ones.
- **`WORKING — progress`, or near-terminal** (a fix/rebase just landed, or the PR
  looked nearly green): keep it **tight** — a few minutes (~180–300s). Something
  moved; check back soon.
- **`WORKING — pending`** (nothing to do — checks/analysis still running): **back
  off.** Double the delay on each *consecutive* pending sweep, capping at ~15–20
  minutes. Re-sweeping while nothing can have changed spends a babysitter/watcher
  sweep to re-learn "still running." **Snap back** to the tight cadence the
  instant a sweep reports `progress`, goes near-terminal, or shows any state
  change. Track the consecutive-pending count in the main session — its context
  survives each wakeup, so the current delay carries across wakeups.
- Boba's transitions land on a minutes timescale (analysis/bail in a minute or two,
  a PR in several); a `boba-watcher` sweep is read-only and does no work, so treat
  its `WORKING` as `pending` and let the backoff apply — except snap back to the
  tight cadence on a freshly-observed "retrying" (a real state change worth
  catching promptly).
- After scheduling, **stop the turn** — the wakeup resumes the loop.

## Self-termination

The loop is self-terminating: it continues **only** on `WORKING` (and after a
confirmed unblock), and stops itself on `DONE`, `WAITING`, `BLOCKED`-unconfirmed,
or error. None of these commands need wrapping in the `/loop` skill.
