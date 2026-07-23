---
name: route-agents
description: >-
  Picks which pinned subagent (or slash command) to use in this environment.
  Use when choosing among scout, scout-explain, worker, sweep, verifier,
  committer, pr-babysitter, pr-reviewer, boba-watcher, or when unsure whether
  to spawn a pinned agent vs do the work in the parent.
---

# Route agents

Decision table for the parent / orchestrator. Agent prompts own *how*; this
skill owns *whom*. Prefer spawning a named agent over re-doing its job here.

## Read / research

| Need | Agent |
| --- | --- |
| Find X, compact gather (`gh`, JQL, ripgrep), `file:line` pin | `scout` (cheap) |
| Understand a subsystem (data flow, entry points, "start here") | `scout-explain` (mid) |
| Critique architecture / design judgment | parent (strong) — not `scout*` |

## Write / fix

| Need | Agent |
| --- | --- |
| Concrete spec, known files/behavior, low ambiguity | `worker` (mid) |
| tsc / lint / formatter loop with a clear signal | `sweep` (mid) |
| Open design mid-change, or spec turns out wrong | stay in parent — do not spawn `worker` |

## Trust / land

| Need | Agent |
| --- | --- |
| Behavior change with a runtime surface | `verifier` (strong) before trust |
| Docs / comments / types / renames / formatting only | skip `verifier` |
| Green tests alone on behavior-changing code | still spawn `verifier` |
| Stage + commit (+ push only if asked) | `committer` (cheap) |

After `worker` lands a behavior change outside `/land`, the parent risk-gates
and spawns `verifier` itself. Prefer `/land` when on the current-branch conveyor
(verifier → commit preview → `committer` → PR handoff).

## PR / Jira — prefer the command

These commands already wire the right agents and gates. Do not hand-roll them:

| Need | Command |
| --- | --- |
| Ticket intake (Boba label vs `/start` + `worker`) | `/dispatch` |
| Mode-B unattended spine | `/ship` |
| Worktree + branch scaffold | `/start` |
| Post-`worker` verify → commit → handoff | `/land` |
| Open PR from current branch | `/open-pr` |
| Shepherd one / many PRs | `/babysit-pr`, `/babysit-fleet` |
| Draft reviews for your review queue | `/review-requests` |
| Apply review threads | `/address-reviews` |
| Boba ticket watch loop | `/watch-boba` |

## Default: spawn, don't impersonate

If a pinned agent matches, spawn it by name. Impersonating `committer` /
`scout` / `verifier` in the parent burns the wrong tier and skips their
contracts (`STATUS:`, `ADVANCE`/`HALT`, `VERDICT:`).

## Model fallback

Pinned-model rate-limit / quota / unavailable → retry **once** with `auto`.
Ordinary task failure → do not fall back. See
`~/.cursor/rules/subagent-model-fallback.mdc`.
