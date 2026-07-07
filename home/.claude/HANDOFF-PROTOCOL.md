# Handoff protocol

The canonical contract for **auto-chaining the PR-lifecycle spine** — the
synchronous sibling of [`LOOP-PROTOCOL.md`](LOOP-PROTOCOL.md) (which governs the
async self-looping commands). One definition of the spine, the `ADVANCE`/`HALT`
terminal contract, the auto-approve taxonomy, and the Jira lifecycle mapping — so
the spine commands and agents don't each re-derive them and drift.

> **Why the split (same as LOOP-PROTOCOL).** Agents run in isolated context and
> can't read this file at spawn time, so each spine agent still states the
> `ADVANCE`/`HALT` line it emits in its own prompt. This doc is the authoritative
> definition they emit *against*, and it owns the **orchestrator-side dispatch** —
> the part that runs in the main session (read the terminal line → advance or
> halt). Change the spine, the vocabulary, or the taxonomy here.

## Two modes

Auto-chaining always applies; the mode only decides what happens *at a gate*.

| Mode | How you get it | Behavior |
|---|---|---|
| **A** — auto-chain (default) | the normal flow | Each step auto-invokes its successor, but **pauses at every preview gate** for a one-word `go`. You never navigate or re-type the next command; you still confirm each gate. |
| **B** — pre-authorized (opt-in) | `--auto` / `/ship` / hub `ship <nums>` | Runs the spine through, **auto-approving AUTO gates** (below) and **stopping only at STOP gates**. |

Mode is set once at the spine entry (`/dispatch`) and carried in the session
context; every auto-advanced successor inherits it.

## The spine

The auto-chain unit is **one ticket, `/dispatch` → mergeable (→ merged)**.
Selection (`/my-work` · `/open-work` picking numbers) sits **above** the spine and
is always manual — it is never auto-advanced.

```
/dispatch <KEY>
   ├─ boba-enabled  → label 'boba' ─────────────▶ /watch-boba   (async loop)
   └─ local         → /start → worker → /land → /open-pr → /babysit-pr  (async loop)
```

**Branch points** (where "advance" is not a single fixed successor — the step
resolves and names it):

- `/dispatch` — boba-enabled vs local.
- `/land` — a PR already exists (→ `/babysit-pr`) vs none yet (→ `/open-pr`).

## Terminal contract — `ADVANCE` / `HALT`

Every spine step (commands **and** the spine agents — `worker`, and `/land`'s use
of `verifier`) ends with exactly one terminal line the orchestrator reads:

- **`ADVANCE → <next>`** — this stage succeeded; proceed. Linear stages may write
  just `ADVANCE` (the successor is the spine default above); the two branch stages
  resolve and name it (e.g. `ADVANCE → /open-pr`, `ADVANCE → /babysit-pr 123`).
- **`HALT: <reason>`** — a STOP gate tripped (design snag, `verifier` BREAKS,
  error, or any always-STOP row below). Nothing advances without you.

**Orchestrator dispatch:**

| Terminal line | Mode A | Mode B |
|---|---|---|
| `ADVANCE → X` | invoke `X`, run it **up to its next preview gate, and wait** for `go` | invoke `X`, run it **through**, auto-approving only its AUTO gates |
| `HALT: <reason>` | **stop**, surface the reason (the notify hook pings) | same — B never overrides a STOP |

The async tail (`/babysit-pr`, `/watch-boba`) is a self-scheduling loop governed
by `LOOP-PROTOCOL.md`. A spine run **ends by launching that loop and returning** —
it does not block on CI. `ship` is "ticket → open PR under babysitting" (plus the
conditional auto-merge below), not a blocking "ticket → merged".

## Auto-approve taxonomy — AUTO vs STOP

A gate is **AUTO** only if its artifact is machine-generated with no judgment call
*and* it's reversible/internal or the explicit goal you pre-authorized. It's
**STOP** if it needs a human decision, disputes correctness, or fabricates content
you'd want to see before it leaves the machine. **When unsure, STOP.**

| Gate | Bucket |
|---|---|
| `/my-work` · `/open-work` selection (pick numbers) | **STOP** always (above the spine) |
| `worker` hits a design decision / ambiguity / wrong spec | **STOP** always |
| `verifier` returns `BREAKS` | **STOP** always |
| `/babysit-pr` `WAITING` (review comments, real conflict, anti-flail) | **STOP** always |
| `/watch-boba` `BLOCKED` unblock draft (writes generated spec to Jira) | **STOP** always |
| `REPEATED-BAIL` | **STOP** always |
| external-blocker detected on a merge candidate (see auto-merge) | **STOP** always |
| any error / MCP-auth / `gh` failure | **STOP** always |
| `/land` commit preview | **AUTO** under B |
| `/open-pr` body preview (opens **ready-for-review**) | **AUTO** under B |
| Jira transition (see mapping) | **AUTO** under B |
| conditional auto-merge, all conditions met | **AUTO** under B |
| handoff offers (`/land`→`/open-pr`→`/babysit-pr`, etc.) | **AUTO** — under A they become auto-advance-to-next-gate; under B, no pause |

## Triggers (mode B)

- **Primitive:** `--auto` on `/dispatch` (`/dispatch ECW-1061 --auto`). The one
  place mode enters the spine; everything downstream inherits it.
- **Direct alias:** `/ship <KEY>` ≡ `/dispatch <KEY> --auto`.
- **From the hubs:** `/my-work` · `/open-work` accept a `ship <nums>` selector next
  to `go` — same safe-set resolution, dispatched with `--auto`. **Explicit numbers
  are required** for `ship`; there is no bare `ship` (a whole-queue unattended run
  is the furthest thing from a gate).

The STOP taxonomy **is** the bail-out — a B run yanks you back the moment it hits
any judgment call, and the notify hook pings. No separate pause/kill switch.

## Conditional auto-merge (mode B only)

`pr-babysitter`, under auto-mode, may merge a PR — the one outward-facing,
effectively irreversible step, so it **fails closed**. Merge only if **all** hold:

- `reviewDecision == APPROVED`, every check green, `mergeable` (no conflicts),
  zero unresolved human review threads, not a draft, **and**
- **no external-blocker signal.** A conservative free-text read of the PR body,
  the approving review, threads, and labels for external-dependency language
  ("needs backend deploy", "blocked on", "after X ships", a `blocked` /
  `do-not-merge` label). **Any hint, or any uncertainty → do NOT merge; `HALT`.**

Merge with the repo's configured merge method. On success emit **`MERGED`** (a
babysitter terminal signal) so the orchestrator fires the post-merge Jira
transition. Under mode A, a mergeable+approved PR stays a STOP that **offers** the
merge — never silent.

## Jira lifecycle mapping

Fired by the **command/orchestrator layer** (which already owns every Jira write);
the post-merge one triggers on the babysitter's `MERGED` signal, keeping
`pr-babysitter` GitHub-only.

| Pipeline event | Transition |
|---|---|
| Work starts (`/start`, or `/dispatch` labels `boba`) | To Do → **In Progress** |
| PR opened (`/open-pr`, or Boba opens one) | In Progress → **In Review** |
| PR merged (auto-merge, or observed merged) | In Review → **Ready for Release** |

Rules:

- **Resolve by intent at runtime** — status names vary by project. Call
  `getTransitionsForJiraIssue`, match the target by intent; if that status isn't in
  the project's workflow, **skip gracefully** and say so, don't error.
- **Idempotent + forward-only** — only transition if the ticket isn't already at or
  past the target; never move it backward; never fail the pipeline on an
  unavailable/already-applied transition.
- **Mode:** AUTO under B (fires automatically at each event, including post-merge);
  under A, a one-line **offer** present at *every* event — the mapping guarantees
  the offer is correct and never forgotten, including the post-merge one after a
  manual merge.
