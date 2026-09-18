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

Never use builtin `Explore` / `generalPurpose` / untyped Task for locate,
explain, or research — spawn the pinned agent by name.

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
| Parent-run `git commit` | **forbidden** — always `committer` or `/land` |

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

## Default: spawn natively by name, don't impersonate

If a pinned agent matches, spawn it by name via the host's own native
subagent tool (`Task`/`Agent` in Claude Code, `Task`/`subagent_type` in
Cursor, native named agents in Codex, `invoke_subagent` in Antigravity) — full mechanics and the Cursor/Codex
notes live in `~/protocols/AGENT-ROUTING.md`. Impersonating `committer` /
`scout` / `verifier` / `researcher` / `sweep` / `review` in the parent burns the wrong
tier and skips their contracts (`STATUS:`, `ADVANCE`/`HALT`, `VERDICT:`).

**Parent Orchestrator ONLY:** This routing and spawning procedure is strictly for the
root parent orchestrator. **Leaf agents (`worker`, `verifier`, `scout`, etc.) are
forbidden from spawning subagents or delegating work** — they must execute directly.

Explicitly instruct the subagent to report its findings and end with its
required terminal contract line, then use the host's own native
completion/wait/result lifecycle for that call to get the reply — no Herdr
`agent read` step is needed. Validate the terminal line once the reply is in
hand; if it's missing, treat it as `HALT: missing terminal contract` — do not
continue the spine.

Reach for `/herdr` instead only on **explicit terminal-management intent** —
the user wants to watch a specialist in a visible pane, or wants an explicit
worktree/tab — not merely because the specialist is async or long-running.

## Model fallback

Pinned-model rate-limit / quota / unavailable → retry **once** with `auto`.
Ordinary task failure → do not fall back. See
`~/.cursor/rules/subagent-model-fallback.mdc`.
