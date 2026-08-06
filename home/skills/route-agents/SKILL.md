---
name: route-agents
description: >-
  Picks which pinned subagent (or slash command) to use in this environment.
  Use when choosing among scout, scout-explain, researcher, worker, sweep,
  verifier, committer, pr-babysitter, pr-reviewer, boba-watcher, or when unsure
  whether to spawn a pinned agent vs do the work in the parent.
---

# Route agents

Decision table for the parent / orchestrator. Agent prompts own *how*; this
skill owns *whom*. Prefer spawning a named agent over re-doing its job here.

Hard must-nots (locate / commit / terminal contracts) also live in the generated
**agent-routing** rule — follow both.

## Read / research

| Need | Agent |
| --- | --- |
| Find X, compact gather (`gh`, JQL, ripgrep), `file:line` pin | `scout` (cheap) |
| Understand a subsystem (data flow, entry points, "start here") | `scout-explain` (mid) |
| Spike / research ticket prep (web, ticket comments, hypotheses) | `researcher` (cheap) |
| Critique architecture / design judgment | parent (strong) — not `scout*` / `researcher` |

Never use builtin `Explore` / `generalPurpose` / untyped Task for locate,
explain, or research — spawn the pinned agent by name.

## Write / fix

| Need | Agent |
| --- | --- |
| Concrete spec, known files/behavior, low ambiguity | `worker` (mid) |
| tsc / lint / formatter loop with a clear signal | `sweep` (mid) |
| Open design mid-change, or spec turns out wrong | stay in parent — do not spawn `worker` |

`worker` must not commit. Keep spawn prompts thin (spec + paths); do not embed
"commit when done."

## Trust / land

| Need | Agent / command |
| --- | --- |
| Behavior change with a runtime surface | `/land` (verifier → committer) |
| Docs / comments / types / renames / formatting only | `committer` (cheap) directly |
| Green tests alone on behavior-changing code | still `/land` / `verifier` |
| Parent-run `git commit` | **forbidden** — always `committer` or `/land` |

After `worker` lands a behavior change outside `/land`, the parent risk-gates
and spawns `verifier` itself — but prefer `/land` on the current-branch conveyor.

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
| Draft reviews for your review queue | `/review-requests` → `pr-reviewer` |
| Apply review threads | `/address-reviews` |
| Boba ticket watch loop | `/watch-boba` |

## Default: spawn, don't impersonate

If a pinned agent matches, spawn it by name. Impersonating `committer` /
`scout` / `verifier` / `researcher` / `sweep` in the parent burns the wrong
tier and skips their contracts (`STATUS:`, `ADVANCE`/`HALT`, `VERDICT:`).

If an agent reply is missing its required terminal line, treat it as
`HALT: missing terminal contract` — do not continue the spine.

## Model fallback

Pinned-model rate-limit / quota / unavailable → retry **once** with `auto`.
Ordinary task failure → do not fall back. See
`~/.cursor/rules/subagent-model-fallback.mdc`.
