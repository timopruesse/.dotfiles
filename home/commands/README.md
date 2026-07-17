# Shared slash-command sources

Edit command prompts here (`*.md`), plus protocols in `home/protocols/`, then run:

```bash
./home/commands/sync-commands
```

That regenerates:

- `home/.claude/commands/` — Claude Code (frontmatter + `$ARGUMENTS` + `model:` pin)
- `home/.cursor/commands/` — Cursor (plain markdown + `$1`/`$2`/… + preferred-model note)

and installs live symlinks into `~/.cursor/commands/`. Protocols are linked from
`home/protocols/` into `home/.claude/` and `home/.cursor/protocols/`.

## Orchestrator model tiers

Sources declare an abstract `tier: cheap|mid|strong` (same vocabulary as
`home/agents/`). `sync-commands` maps it through
[`home/agents/model-map.yaml`](../agents/model-map.yaml):

| Tier | Claude Code (`model:`) | Cursor (preferred session model) |
| --- | --- | --- |
| cheap | `haiku` | `kimi-k2.7-code` |
| mid | `sonnet` | `composer-2.5-fast` |
| strong | `opus` | `cursor-grok-4.5-high-fast` |

Claude Code honors the frontmatter `model:` pin for the command turn. Cursor
slash commands inherit the chat model picker — the generated note asks you to
switch to the mapped pin when the session is on a stronger tier. Subagents keep
their own pins either way.

Current pins (orchestrator only — hard reasoning stays on `verifier` / escalate):

| Command | Tier |
| --- | --- |
| `/ship-digest`, `/dispatch` | cheap |
| `/my-work`, `/open-work`, `/start`, `/ship`, `/watch-boba`, `/land`, `/open-pr`, `/babysit-pr`, `/babysit-fleet`, `/review-requests`, `/address-reviews` | mid |

**Exception — `/watch-boba`:** mid by default, but may escalate individual
spawns to strong when `boba-watcher` returns `ESCALATE` (one re-classify) or
when drafting a scope/approach unblock. Routine loop ticks stay mid; do not
pin the whole command to strong.

Do **not** hand-edit the generated trees; they are overwritten on sync.
`machine_setup` runs the sync after `sync-agents`.
