---
name: route-agents
description: >-
  Picks which pinned subagent (or slash command) to use in this environment.
  Use when choosing among scout, scout-explain, researcher, security-triage, worker, sweep,
  review, verifier, committer, pr-babysitter, boba-watcher, or when unsure
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

## Default: spawn via Herdr, don't impersonate

If a pinned agent matches, spawn it by name. Impersonating `committer` /
`scout` / `verifier` / `researcher` / `sweep` / `review` in the parent burns the wrong
tier and skips their contracts (`STATUS:`, `ADVANCE`/`HALT`, `VERDICT:`).

**Parent Orchestrator ONLY:** This routing and spawning procedure is strictly for the
root parent orchestrator. **Leaf agents (`worker`, `verifier`, `scout`, etc.) are
forbidden from spawning subagents or delegating work** — they must execute directly.

**Never invoke the CLI's default/internal subagent tools** (`Task`, `Agent`, `invoke_subagent`).
Instead, use the `/herdr` skill to spawn the subagent in a visible Herdr pane or tab:
1. **Topology**: Split pane (`herdr pane split --current --direction right|down --cwd "$PWD" --focus`)
   for focused work (`scout`, `worker`, `verifier`, `review`, `committer`, `sweep`); new tab
   (`herdr tab create --cwd "$PWD" --label "<name>" --focus`) for separate worktrees or loops.
2. **Start in Auto Mode**: Always pass the host CLI's auto-approval flags:
   - Claude Code: `herdr agent start <name> --kind claude --pane <id> -- --agent <agent-name> --permission-mode auto`
   - Agy: `herdr agent start <name> --kind agy --pane <id> -- --agent <agent-name> --dangerously-skip-permissions`
   - Cursor: `herdr agent start <name> --kind cursor --pane <id> -- -f --approve-mcps --trust --model <model>`
   (or `$HOME/.config/herdr/scripts/coding_agent_subagent.sh run --agent <name> ...` which applies auto mode by default).
3. **Prompt & Wait**: `herdr agent prompt <name> "<spec>" --wait --timeout 300000`.
   Explicitly instruct the subagent to report its findings and end with its required terminal contract line.
4. **Read Results & Cleanup**: `herdr agent read <name> --source recent-unwrapped --lines 120`.
   Extract the subagent's report and terminal line.
   **Close `committer` immediately**: close its pane/tab (`herdr pane close "$pane_id"`);
   leave `worker`, `verifier`, `review`, and `sweep` open for user review.

If an agent reply is missing its required terminal line, treat it as
`HALT: missing terminal contract` — do not continue the spine.

## Model fallback

Pinned-model rate-limit / quota / unavailable → retry **once** with `auto`.
Ordinary task failure → do not fall back. See
`~/.cursor/rules/subagent-model-fallback.mdc`.
