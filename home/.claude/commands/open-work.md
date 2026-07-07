---
description: Browse open items in a board's active sprint (default ECW) and pick what to start
argument-hint: "[board/project key — defaults to ECW]"
---

Show me the unassigned, startable items in the active sprint so I can pick what to
grab. This is a free-to-take pool — deliberately unassigned so it doesn't overlap
`/my-work` (my own assigned work). Selection is explicit and NEVER auto-dispatched:
I start only the tickets I name, behind the preview gate in step 3. It's fine to
pick nothing.

## 1. Gather (fan to `scout` — the raw result is token-fat)

- **Board/project key:** use `$ARGUMENTS` if given, else default to `ECW`.
- The pool is **unassigned, startable** items in the active sprint: unassigned so
  it's genuinely grabbable and doesn't overlap `/my-work` (which covers your own
  assigned work); startable (`statusCategory = "To Do"`, i.e. NEW/Refine/To Do)
  because Review / In Progress / Ready for Release are in flight, not things to
  start fresh.
- **Do NOT run the JQL inline** — `searchJiraIssuesUsingJql` returns full
  descriptions + nested objects and blows the context even with a `fields` filter
  (the filter isn't honored). Spawn `scout` to run it and return **only** a compact
  list — one line per item: `key · status · summary`. The query:
  `project = <KEY> AND sprint in openSprints() AND statusCategory = "To Do" AND assignee IS EMPTY ORDER BY rank`.
  If Atlassian is unavailable, `scout` says so and I stop — nothing to browse without it.

## 2. Present a numbered, actionable list

One line per item, each PRE-BOUND to the start action and tagged for safety:

- `1. ECW-1061 "Customer Portal: subscription detail + edit" — NEW` → start ✅ ready
- `2. ECW-1135 "connect Overview page to backend" — Refine` → start ✅ ready
- `3. ECW-963 "Research: Shopify Promo Preview" — NEW` → **needs you** (research/spike)
- `4. ECW-1064 "replace payment method" — NEW` → **needs you** (blocked: confirm w/ Recharge)

Judge and flag each item as **ready** (concrete, low-ambiguity spec — clear AC,
buildable now) vs **needs your design input** — be honest; a half-baked ticket, a
research/spike, or one with unresolved "confirm with X / resolve at grooming"
blockers handed off unattended wastes a run.

## 3. Select + start (behind the preview gate)

I reply with the numbers I want (e.g. `1 3`). There is no bare `go`/`all` here —
a sprint pool isn't a safe-to-auto set, so nothing starts without explicit numbers.

- **Show the start plan and STOP for one confirmation.** Print a one-screen plan:
  each selected item → the label/command it'll run → a one-line intent. This is the
  only thing I see before it runs.
- On my `go`, start each selected ticket in parallel and report back as each returns.
  - **Detect Boba-enabled once for the board** — the whole pool is one project, so
    probe once (ideally fold this into the step-1 `scout` gather): JQL `project =
    <KEY> AND labels = boba`. Non-empty → Boba-enabled; absence, or an inconclusive
    probe → **not** (`worker` is the safe default). Hold the verdict for dispatch.
  - **Dispatch each ticket** → `/dispatch <KEY> <verdict>`, passing the board's
    verdict (`boba` / `no-boba`) so it doesn't re-probe. `/dispatch` owns the
    mechanism: label for the Boba pipeline (which owns branch/worktree/implementation)
    or scaffold via `/start` + `worker`, and offers the opt-in `/watch-boba` and the
    Jira transition (→ In Progress) — never silently.

Keep it frictionless: `/open-work` → glance → pick numbers → glance at plan → `go`.
The plan preview is a hard gate — never skip it, never start without it.
