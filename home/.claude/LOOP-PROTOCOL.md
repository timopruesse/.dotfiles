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

All loopers share the underlying **mechanism** — `ScheduleWakeup` re-fires the
*same command* (with its exact arguments), then the turn stops; the wakeup resumes
the loop. But they come in two shapes, and only one uses the `STATUS:` contract:

| Shape | Commands | Converges? | Terminal signal | Cadence |
|---|---|---|---|---|
| **Shepherd** | `/babysit-pr`, `/babysit-fleet`, `/watch-boba` | Yes — drives one target to a terminal state | `STATUS:` enum (below); self-terminates on `DONE`/`WAITING`/`MERGED` | ~270s, cache-warm |
| **Hub** | `/my-work watch` | No — the queue refills; there is no "done" | A per-tick roll-up (`CHANGES` / `AUTO-ACTED`), **not** `STATUS:`; terminates on your action or an empty queue | idle-tick, ~15–30 min |

The **shepherd** sections below (`STATUS:`, cache-warm cadence, self-termination)
apply to shepherd loops. A **hub** loop borrows only the re-fire mechanism: it
would be a lie for it to emit a `STATUS:` line — every tick is perpetually
"working" because the hub never arrives. Its cadence inverts the cache-warm rule:
with no terminal-state race, checking under 5 minutes buys nothing, so it uses the
idle-tick regime (`delaySeconds` ≈ 1200) and accepts the cache miss. The hub's own
vocabulary and control flow live in its command file (`/my-work watch`).

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
(`/babysit-pr $ARGUMENTS`, `/babysit-fleet $ARGUMENTS`, `/watch-boba $ARGUMENTS`).

> **What actually costs tokens per tick.** The ~270s "cache-warm" window below
> keeps the *wakeup turn* cheap (the main-session context stays within the 5-minute
> cache TTL). But the dominant cost per tick is the **sweep agent** — a fresh
> Sonnet `pr-babysitter`/`boba-watcher` invocation whose context is *not* covered by
> that cache. So a tight cadence is worth paying only when a terminal-state race is
> live (something changed, or a flip is imminent); while purely idle-waiting it just
> burns sweeps. Hence the flavor split:

- **Baseline ~270s, kept under 300s** so the Anthropic prompt cache (5-minute TTL)
  stays warm for the wakeup turn.
- **`WORKING — progress`, or near-terminal** (a fix/rebase just landed, or the PR
  looked nearly green): keep it **tight** — ~270s, or **~180s** when a terminal
  state looks close. Something moved; check back soon.
- **`WORKING — pending`** (nothing to do — checks/analysis still running): **back
  off.** Double the delay on each *consecutive* pending sweep — 270 → 540 → 900 —
  capping at ~900s. Idling at 270s spends a Sonnet sweep every 4.5 min to re-learn
  "still running." **Snap back** to the tight cadence the instant a sweep reports
  `progress`, goes near-terminal, or shows any state change. Track the
  consecutive-pending count in the main session — its context survives each
  `ScheduleWakeup`, so the current delay carries across wakeups.
- Boba's transitions land on a minutes timescale (analysis/bail in a minute or two,
  a PR in several); a `boba-watcher` sweep is read-only and does no work, so treat
  its `WORKING` as `pending` and let the backoff apply — except reset to ~270s on a
  freshly-observed "retrying" (a real state change worth catching promptly).
- After scheduling, **stop the turn** — the wakeup resumes the loop.

## Self-termination

The loop is self-terminating: it continues **only** on `WORKING` (and after a
confirmed unblock), and stops itself on `DONE`, `WAITING`, `BLOCKED`-unconfirmed,
or error. None of these commands need wrapping in the `/loop` skill.
