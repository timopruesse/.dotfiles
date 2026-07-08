---
description: A hub of your open work (PRs, reviews, Jira) with one-word dispatch into your agents
argument-hint: "[watch [--auto]] [optional gh/jira scope]"
---

Show me my open work for the day as a dispatch hub. Gather, then present an
actionable, numbered list. NEVER auto-dispatch — dispatching always goes through
the preview gate in step 3.

**Two shapes.** Bare `/my-work` (and `/my-work <scope>`) is the **one-shot hub**
below — gather, present, dispatch on a selector, done. `/my-work watch` promotes
it into an **ambient loop** (the "hub" loop shape in
[`~/.claude/LOOP-PROTOCOL.md`](../LOOP-PROTOCOL.md)) that re-gathers on an
interval and reports what changed — see [Watch mode](#watch-mode) at the end. Any
trailing `gh`/`jira` scope applies to either shape.

## 1. Gather (fan out to `scout`, in parallel)

Spawn `scout` calls concurrently so the token-fat raw output stays isolated:

- **My open PRs** (`gh search prs --author=@me --state=open --archived=false`) —
  and for each, its CI state (`gh pr checks`) and whether there are review
  comments waiting on me.
- **Review requests** (`gh search prs --review-requested=@me --state=open --archived=false`).
- **My assigned Jira tickets** that are open/in-progress (via the Atlassian MCP).

Always pass `--archived=false` on both `gh search prs` calls: a PR (or review
request) in an archived repo is un-actionable — the repo is read-only, so it can
never merge — and surfacing it just adds dead noise to the hub.

## 2. Present a numbered, actionable list

One line per item, each PRE-BOUND to a dispatch action and tagged for safety:

- `PR #12 — CI red` → `/babysit-pr 12`
- `PR #34 — 3 review comments waiting on you` → surfaced; **needs you**
- `JIRA-451 "add rate limit" — assigned, spec concrete, Boba board` → label `boba` ✅ ready
- `JIRA-455 "fix parser" — assigned, spec concrete, non-Boba board` → `/start` + `worker` ✅ ready
- `JIRA-460 "rework billing" — assigned, needs design input` → **needs you**
- `2 PRs need your review` → `/review-requests`

For each Jira ticket, judge two things: (a) whether it's **ready** (concrete,
low-ambiguity spec) or **needs your design input** — be honest; a half-baked
ticket handed off unattended wastes a run; and (b) whether its board/repo is
**Boba-enabled**, which decides the dispatch mechanism (below).

**Detecting Boba-enabled** (per distinct **project**, at gather time): the Boba
pipeline stamps the `boba` label on the tickets it works, so a project that already
uses it will have prior `boba`-labeled issues. Probe with JQL `project = <KEY> AND
labels = boba` (via the Atlassian MCP) — a non-empty result means the project is
Boba-enabled. The verdict is a property of the **project**, not the ticket, so
probe each project **once** and reuse it for every ticket that shares it — don't
re-probe per ticket. Treat absence of the signal (or an inconclusive probe) as
**not** Boba-enabled; `worker` is always the safe default. Hold each project's
verdict (`boba` / `no-boba`) to pass down to `/dispatch` at step 3.

## 3. Dispatch (the easy path)

I reply with a terse selector: `all`, `go`, `ship <nums>`, specific numbers
(`1 3 5`), or `all but 2`. Then:

- **Resolve the selection.** Bare `go`/`all` means the **safe-to-auto set only**:
  ready Jira tickets + CI-red PRs. Deliberately EXCLUDE anything flagged **needs
  you** (design-input tickets, review-comment PRs) — those I dispatch only when I
  name their numbers explicitly.
- **`ship <nums>` is mode B** (pre-authorized) per
  [`~/.claude/HANDOFF-PROTOCOL.md`](../HANDOFF-PROTOCOL.md) — the named items run
  through, auto-approving downstream AUTO gates instead of pausing at each.
  **Explicit numbers are required; there is no bare `ship`** — a whole-queue
  unattended run is deliberately not offered. `go`/`all`/numbers stay mode A:
  normal per-gate confirm.
- **Show the dispatch plan and STOP for one confirmation** — for `go` and `ship`
  alike. Print a one-screen plan grouped by action: each selected item → the
  label/command it'll run → a one-line intent. This is the only thing I see
  before it runs; for a `ship` selection this one confirmation IS the
  pre-authorization — only the per-step gates downstream are skipped, not this
  batch gate.
- On my `go`, act on each selected item in parallel and report back as each returns:
  - **Ready Jira ticket** → `/dispatch <KEY> <verdict>` (append `--auto` if it was
    selected via `ship`), passing the per-project Boba verdict from step 2
    (`boba` / `no-boba`) so it doesn't re-probe. `/dispatch` owns the mechanism:
    label for the Boba pipeline or scaffold via `/start` + `worker`, then offer
    the opt-in `/watch-boba` and Jira transition.
  - **CI-red PR** → `/babysit-pr <n>`; etc.

Keep the common case frictionless: `/my-work` → glance → `go` → glance at plan →
`go`. But the plan preview is a hard gate — never skip it, never dispatch without
it.

## Watch mode

`/my-work watch [--auto] [scope]` runs the hub as an **ambient loop** — the "hub"
loop shape defined in [`~/.claude/LOOP-PROTOCOL.md`](../LOOP-PROTOCOL.md). Unlike
the shepherd loops (`/babysit-pr`, `/watch-boba`), a work hub never converges to a
terminal state, so it does **not** emit the `STATUS:` enum; it borrows only the
`ScheduleWakeup` re-fire-same-command mechanism and reports a per-tick roll-up
instead. It terminates on your action or an empty queue, never on "done."

**State lives in a snapshot file**, not in context — do not assume in-context
memory survives across wakeups. Persist to the session scratchpad at
`<scratchpad>/my-work-watch.json` (the scratchpad path is in the system prompt),
keyed by stable id:

```json
{ "prs":  { "142": { "ci": "red", "reviewComments": 3, "mergeable": false } },
  "jira": { "ECW-88": { "status": "In Progress", "assignee": "me" } },
  "reviewRequests": ["owner/repo#77"],
  "dispatched": ["142", "ECW-88"] }
```

Each tick:

1. **Gather** — exactly step 1 above (the `scout` fan-out), honoring any `scope`.
2. **Diff against the prior snapshot** and print a `CHANGES SINCE LAST TICK` block
   *above* the hub. Compare field-by-field on stable keys (PR number, `KEY`,
   `repo#n`):
   - 🆕 new assigned ticket / new review request
   - 🔴→🟢 · 🟢→🔴 CI transition on your PR
   - 💬 new review comments waiting on you (count delta)
   - ✅ Boba landed a PR / a PR became mergeable
   - ➖ item left the queue (merged, closed, reassigned)
   On the **first tick** print `baseline — N items` (no diff).
3. **Render the numbered hub** — byte-for-byte the step 2 output, so every
   dispatch selector (`go`, `ship <nums>`, `1 3 5`, `all but 2`) works unchanged.
   You can type a selector at any tick; it drops straight into step 3's gated
   dispatch path.
4. **Persist the snapshot** (including `dispatched`), then `ScheduleWakeup`
   re-firing `/my-work watch [--auto] [scope]` and **stop the turn**.

**Cadence — idle-tick, not cache-warm.** A hub has no terminal-state race, so the
~270s shepherd cadence does not apply; use the idle-tick regime (~15–30 min,
`delaySeconds` ≈ 1200) per `LOOP-PROTOCOL.md`'s hub-shape rule. Checking sooner
buys nothing because hub state moves on a minutes-to-hours scale.

**Termination.** Stop the loop (don't reschedule) when: you say stop, you dispatch
a selection (hand off, then offer to resume watching), or the queue is empty.
Never stop on convergence — there isn't any.

### Mode A vs B (the `--auto` flag)

- **`/my-work watch` → mode A (default): notify only.** The `CHANGES` block is
  informational; you still type a selector to act. The `NEVER auto-dispatch`
  invariant at the top of this file holds exactly.
- **`/my-work watch --auto` → mode B: auto-act on the safe set.** Entering
  `--auto` **is** the pre-authorization, identical in spirit to `ship <nums>` per
  [`~/.claude/HANDOFF-PROTOCOL.md`](../HANDOFF-PROTOCOL.md) — it is not the hub
  dispatching behind your back. Under it, each tick runs an auto-act pass bound by
  three load-bearing constraints:
  1. **Safe set only** — the *same* set bare `go` resolves to in step 3: ready
     Jira tickets + CI-red PRs. Needs-you items (design-input tickets,
     review-comment PRs) **only notify**, never auto-act, even here.
  2. **Dispatch-once, tracked in `dispatched`** — auto-act fires on an item only
     the *first* time it enters the safe set, then records its key. `/babysit-pr`
     and `/watch-boba` are themselves self-looping; re-dispatching a still-red PR
     every tick would stack duplicate loops on one target. An already-dispatched
     item renders as *in flight*, not re-dispatched.
  3. **Report before rescheduling** — lead the tick with an `AUTO-ACTED THIS TICK`
     block (each item → the command it ran) above `CHANGES`, so an unattended loop
     is never silently acting.
  Auto-act uses the mode-B dispatch forms: CI-red PR → `/babysit-pr <n>`; ready
  Jira → `/dispatch <KEY> --auto` with the per-project Boba verdict from step 2.
