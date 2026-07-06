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
- `JIRA-451 "add rate limit" — assigned, spec concrete` → hand to `worker` ✅ ready
- `JIRA-460 "rework billing" — assigned, needs design input` → **needs you**
- `2 PRs need your review` → `/review-requests`

For each Jira ticket, judge and flag whether it's **`worker`-ready** (concrete,
low-ambiguity spec) or **needs your design input** — be honest; a half-baked
ticket handed to `worker` wastes tokens.

## 3. Dispatch (the easy path)

I reply with a terse selector: `all`, `go`, specific numbers (`1 3 5`), or
`all but 2`. Then:

- **Resolve the selection.** Bare `go`/`all` means the **safe-to-auto set only**:
  `worker`-ready Jira tickets + CI-red PRs. Deliberately EXCLUDE anything flagged
  **needs you** (design-input tickets, review-comment PRs) — those I dispatch only
  when I name their numbers explicitly.
- **Show the dispatch plan and STOP for one confirmation.** Print a one-screen
  plan grouped by agent: each selected item → the agent/command it'll run → a
  one-line intent/prompt. This is the only thing I see before it runs.
- On my `go`, fan them out in parallel — spawn `worker` per ready ticket (with a
  concrete prompt derived from the ticket), fire `/babysit-pr` per red PR, etc. —
  and report back as each returns.

Keep the common case frictionless: `/my-work` → glance → `go` → glance at plan →
`go`. But the plan preview is a hard gate — never skip it, never dispatch without
it.
