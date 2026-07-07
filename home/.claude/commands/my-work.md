---
description: A hub of your open work (PRs, reviews, Jira) with one-word dispatch into your agents
argument-hint: "[optional gh/jira scope]"
---

Show me my open work for the day as a dispatch hub. Gather, then present an
actionable, numbered list. NEVER auto-dispatch — dispatching always goes through
the preview gate in step 3.

## 1. Gather (fan out to `scout`, in parallel)

Spawn `scout` calls concurrently so the token-fat raw output stays isolated:

- **My open PRs** (`gh search prs --author=@me --state=open`) — and for each, its
  CI state (`gh pr checks`) and whether there are review comments waiting on me.
- **Review requests** (`gh search prs --review-requested=@me --state=open`).
- **My assigned Jira tickets** that are open/in-progress (via the Atlassian MCP).

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

I reply with a terse selector: `all`, `go`, specific numbers (`1 3 5`), or
`all but 2`. Then:

- **Resolve the selection.** Bare `go`/`all` means the **safe-to-auto set only**:
  ready Jira tickets + CI-red PRs. Deliberately EXCLUDE anything flagged **needs
  you** (design-input tickets, review-comment PRs) — those I dispatch only when I
  name their numbers explicitly.
- **Show the dispatch plan and STOP for one confirmation.** Print a one-screen
  plan grouped by action: each selected item → the label/command it'll run → a
  one-line intent. This is the only thing I see before it runs.
- On my `go`, act on each selected item in parallel and report back as each returns:
  - **Ready Jira ticket** → `/dispatch <KEY> <verdict>`, passing the per-project
    Boba verdict from step 2 (`boba` / `no-boba`) so it doesn't re-probe. `/dispatch`
    owns the mechanism: label for the Boba pipeline or scaffold via `/start` +
    `worker`, then offer the opt-in `/watch-boba` and Jira transition.
  - **CI-red PR** → `/babysit-pr <n>`; etc.

Keep the common case frictionless: `/my-work` → glance → `go` → glance at plan →
`go`. But the plan preview is a hard gate — never skip it, never dispatch without
it.
