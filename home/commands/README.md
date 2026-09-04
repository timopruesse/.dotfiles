# Shared slash-command sources

Edit command prompts here (`*.md`), plus protocols in `home/protocols/`, then run:

```bash
./home/sync/sync
```

That regenerates:

- `home/.claude/commands/` — Claude Code (frontmatter + `$ARGUMENTS` + `model:` pin)
- `home/.cursor/commands/` — Cursor (plain markdown + `$1`/`$2`/… + preferred-model note)

**sync** links generated commands into `~/.cursor/commands/`. Protocols are
linked from `home/protocols/` into `home/.claude/` and `home/.cursor/protocols/`.

Shared sources stay platform-neutral for model pins: write `{{pin:strong}}` (or
`cheap`/`mid`) where a concrete slug is needed; sync expands it per host.

## Orchestrator model tiers

Sources declare an abstract `tier: cheap|mid|strong` (same vocabulary as
`home/agents/`). **sync** maps it through
[`home/agents/model-map.yaml`](../agents/model-map.yaml):

<!-- BEGIN GENERATED MODEL MAP TABLE -->
| Tier | Claude Code (`model:`) | Cursor (preferred session model) | Agy (`--model`) |
| --- | --- | --- | --- |
| cheap | `haiku` | `composer-2.5` | `flash_lite` |
| mid | `sonnet` | `composer-2.5-fast` | `flash` |
| strong | `opus` | `cursor-grok-4.6-high-fast` | `pro` |
<!-- END GENERATED MODEL MAP TABLE -->

Claude Code honors the frontmatter `model:` pin for the command turn. Cursor
slash commands inherit the chat model picker — the generated note asks you to
switch to the mapped pin when the session is on a stronger tier. Subagents keep
their own pins either way.

Current pins (orchestrator only — hard reasoning stays on `verifier` / escalate):

<!-- BEGIN GENERATED COMMAND TIER TABLE -->
| Tier | Commands |
| --- | --- |
| cheap | `/dispatch`, `/session-cost`, `/ship-digest`, `/triage-security` |
| mid | `/address-reviews`, `/babysit-fleet`, `/babysit-pr`, `/land`, `/my-work`, `/open-pr`, `/open-work`, `/review-requests`, `/ship`, `/start`, `/watch-boba`, `/wrap-up` |
<!-- END GENERATED COMMAND TIER TABLE -->

**Exception — `/watch-boba`:** mid orchestrator by default; `boba-watcher`
routine ticks stay cheap. Escalate individual spawns to strong when
`boba-watcher` returns `ESCALATE` (one re-classify) or when drafting a
scope/approach unblock. Do not pin the whole command to strong.

Do **not** hand-edit the generated trees; they are overwritten on sync.
`machine_setup` runs `home/sync/sync`.

Flow graph: [`WORKFLOWS.md`](../../WORKFLOWS.md). Whom-table:
[`home/skills/route-agents/`](../skills/route-agents/). Glossary:
[`CONTEXT.md`](../../CONTEXT.md).
