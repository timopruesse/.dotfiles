# Agent routing (hard)

Pinned agents: {{PINNED_AGENTS}}.

Whom-table detail: `route-agents` skill. These rules are **must-nots** — treat
violations as errors, not style nits.

> **Source of truth.** Edit this file under `home/protocols/`. Sync emits
> Cursor `agent-routing.mdc` and the generated block in `home/.claude/CLAUDE.md`.
> Do not hand-edit those outputs. Soft whom-table stays in `route-agents`; this
> protocol is the must-not layer.

## Free-form prompt intake

A free-form request that names a Jira ticket (URL, key, or phrasing like
"investigate/fix this issue") is **not** an invitation for the parent to absorb
all the work. It is a prompt to enter the spine.

- Extract the Jira key and route to `/dispatch <KEY>` (default mode A) or
  `/ship <KEY>` (mode B) when the user asks to investigate, fix, or implement a
  ticket. Do not run a manual code search, edit, or PR opening in the parent.
- If you are already on a `<KEY>-...` branch with uncommitted or unpushed work
  and the user says they are done, route to `/wrap-up` to close the spine and
  open the PR — do not make them re-enter `/open-pr` manually.
- Only stay in the parent for genuine ad-hoc questions (no ticket, no
  implementation intent, no branch context) or explicit "explain" requests.

This keeps the parent interface thin and puts the deep work behind the spine's
pinned, tiered agents.

## Locate / explain / research

- Repo locate or compact gather → spawn **`scout`** (cheap).
- Subsystem walkthrough / architecture map → spawn **`scout-explain`** (mid).
- Spike / research-ticket prep (web, ticket comments, hypotheses) → spawn
  **`researcher`** (cheap).
- **Never** spawn builtin `Explore`, `generalPurpose`, `general-purpose`, or an
  untyped Task/Agent for those jobs. If the pinned agent fails to start, surface
  the error — do not silently fall back to a builtin explorer (model `auto`
  retry once still uses the **same** pinned agent name).
- Cursor Task/`subagent_type` often only lists **project-agents** under
  `<git-root>/.cursor/agents/` (not `~/.cursor/agents/`). If a pinned name is
  rejected as an invalid enum value: run `home/sync/ensure-project-agents` (or
  open a coding-agent launcher, which ensures best-effort), confirm the
  symlinks exist, then start a **new** Agent session so the Task enum reloads.
  **Fail closed:** missing pin in the Task enum is an error — still never fall
  back to Explore/`generalPurpose`.

## Commit / land

- Parent **must not** run `git commit` (or equivalent staging+commit plumbing).
- Behavior-changing / runtime-surface work → **`/land`** (verifier → committer →
  handoff).
- Docs / comments / types / renames / formatting only → spawn **`committer`**
  directly.
- **`worker` must not commit.** Keep worker spawn prompts thin (spec + paths);
  never instruct the worker to commit.
- On `/land` (or any parent-run verifier gate): apply the **land path** risk-gate
  and obvious-BREAKS taxonomy in
  [`HANDOFF-PROTOCOL.md`](HANDOFF-PROTOCOL.md) — auto-repair obvious BREAKS and
  re-verify (≤3 cycles) without waiting for `go`. Non-obvious or budget-exhausted
  BREAKS still `HALT`.

## Mechanical cleanup + review

- Clear tsc/lint/formatter loops → spawn **`sweep`** (not parent/strong).
- PRs awaiting *your* review → **`/review-requests`** → **`pr-reviewer`**.
  Ad-hoc diff critique in a coding session may use the `code-review` skill.

## Terminal contracts

- Require each agent's terminal line (`ADVANCE` / `HALT` / `VERDICT:` /
  `STATUS:` as defined in that agent).
- If the reply is missing the required terminal line, treat it as
  `HALT: missing terminal contract` and do **not** continue the spine.
- `sweep`: `ADVANCE → /land` when on the pre-land conveyor; `ADVANCE → done`
  when the parent only asked to clean the tree; else `HALT:`.

## Security-review triage

Push-time security review findings (e.g. from the security-guidance plugin,
Bugbot, Dependabot security, GitHub code scanning) are not a parent
context-switch. The parent already opened the PR; deeper investigation of
out-of-scope or pre-existing code belongs in the async tail.

- If the finding is for code this work did not touch, acknowledge it briefly and
  route to **`/triage-security`** (hub lane + cheap `security-triage` agent) or
  `/babysit-pr <number>` when already classified — do not investigate, blame, or
  propose fixes in the parent session.
- If the finding is for code this work touched, surface it as a `HALT:` (and
  **signal egress** `halt`) and hand the fix back to `worker` through the normal
  spine.
- Never let a post-push security notification re-open the PR opening gate.
- Local `/review-bugbot` / `/review-security` skills are a different seam
  (pre-PR local diff) — do not conflate them with `/triage-security`.
