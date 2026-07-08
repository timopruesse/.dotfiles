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
| `WORKING` | Progress to wait on — a fix/update was pushed, or checks/analysis are still running. Nothing to decide. | **Reschedule** the next sweep (see cadence). |
| `DONE` | Terminal success — the loop's goal is reached (PR mergeable, or Boba opened a PR). | **Stop.** Hand off if the flow specifies one (e.g. `boba-watcher` DONE → `/babysit-pr`). |
| `WAITING` | Blocked on a human — review comments, a real conflict, anti-flail tripped, or a human took the ticket over. | **Stop.** Say exactly what needs the human. |
| `BLOCKED` | *(Boba only)* Boba bailed for more info. | Run the command's gated unblock path; do **not** treat as WORKING. |

Anything else (no target found, MCP/`gh`/auth error, agent failed) → **stop** and
report the problem. Never reschedule on an error.

## The `ScheduleWakeup` cadence

On `WORKING` (and after a confirmed Boba unblock), schedule the next sweep by
re-firing the **same command** — set `prompt` to the exact invocation
(`/babysit-pr $ARGUMENTS`, `/babysit-fleet $ARGUMENTS`, `/watch-boba $ARGUMENTS`).

- **Delay ~270s by default.** Keep it **under 300s** so the Anthropic prompt cache
  (5-minute TTL) stays warm — a longer sleep reads the whole loop context uncached,
  slower and costlier.
- Go **shorter (~180s)** when the target looked close to a terminal state (a PR
  nearly green). Boba's transitions land on a minutes timescale (analysis/bail in a
  minute or two, a PR in several), so ~270s fits it too.
- After scheduling, **stop the turn** — the wakeup resumes the loop.

## Self-termination

The loop is self-terminating: it continues **only** on `WORKING` (and after a
confirmed unblock), and stops itself on `DONE`, `WAITING`, `BLOCKED`-unconfirmed,
or error. None of these commands need wrapping in the `/loop` skill.
