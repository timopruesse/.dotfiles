---
name: route-agents
description: >-
  Picks which pinned subagent (or slash command) to use in this environment.
  Use when choosing among scout, scout-explain, researcher, security-triage, worker, sweep,
  review, verifier, planner, committer, pr-babysitter, boba-watcher, or when unsure
  whether to spawn a pinned agent vs do the work in the parent.
---

# Route agents

Decision table for the parent / orchestrator. Agent prompts own *how*; this
skill owns *whom*. Prefer spawning a named agent over re-doing its job here.

Hard must-nots (locate / commit / terminal contracts) also live in the
**agent-routing** protocol (`~/protocols/AGENT-ROUTING.md`, emitted to Cursor
rules + Claude host prose) — follow both.

## Read / research

| Need | Agent |
| --- | --- |
| Find X, compact gather (`gh`, JQL, ripgrep), `file:line` pin | `scout` (cheap) |
| Understand a subsystem (data flow, entry points, "start here") | `scout-explain` (mid) |
| Spike / research ticket prep (web, ticket comments, hypotheses) | `researcher` (cheap) |
| Classify push-time security / Bugbot findings on open PRs | `security-triage` (cheap) — via `/triage-security` |
| Critique architecture / design judgment | parent (strong) — not `scout*` / `researcher` |

Execution, failures, and terminal contracts are defined in
[`AGENT-ROUTING.md`](../../protocols/AGENT-ROUTING.md).

## Write / fix

| Need | Agent |
| --- | --- |
| Explicit implementation planning, risks, validation | `planner` (strong, read-only) |
| Concrete spec, known files/behavior, low ambiguity | `worker` (mid) |
| tsc / lint / formatter loop with a clear signal | `sweep` (mid) |
| Open design mid-change, or spec turns out wrong | stay in parent — do not spawn `worker` |

`worker` must not commit. Keep spawn prompts thin (spec + paths); do not embed
"commit when done."

## Trust / land

| Need | Agent / command |
| --- | --- |
| Local diff / branch review / pre-land code review (standards + spec) | `review` (strong) |
| Behavior change with a runtime surface | `/land` (verifier → committer; obvious BREAKS auto-fix ≤3) |
| Docs / comments / types / renames / formatting only | `committer` (cheap) directly |
| Green tests alone on behavior-changing code | still `/land` / `verifier` |
| Parent-run `git commit` | `committer` preferred; protocol permits unavailable-specialist fallback |

After `worker` lands a behavior change outside `/land`, the parent risk-gates
and spawns `verifier` itself — but prefer `/land` on the current-branch conveyor.
Obvious `verifier` BREAKS (concrete repro + mechanical/live-install fix, no
design fork) are auto-repaired and re-verified per HANDOFF land path; do not
`HALT` those for `go`.

## PR / Jira — prefer the command

| Need | Command |
| --- | --- |
| Ticket intake (Boba label vs `/start` + `worker`) | `/dispatch` |
| Research/spike prep before intake | spawn `researcher`, then `/dispatch` when buildable |
| Mode-B unattended spine | `/ship` |
| Worktree + branch scaffold | `/start` |
| Post-`worker` verify → commit → handoff | `/land` |
| Open PR from current branch | `/open-pr` |
| Shepherd one / many PRs | `/babysit-pr`, `/babysit-fleet` |
| Draft reviews for your review queue | `/review-requests` → `review` (strong) |
| Apply review threads | `/address-reviews` |
| Push-time Bugbot / security findings on open PRs | `/triage-security` → `security-triage` |
| Session spend / duration rollup | `/session-cost` |
| Boba ticket watch loop | `/watch-boba` |
