# Shared slash-command sources

Edit command prompts here (`*.md`), plus protocols in `home/protocols/`, then run:

```bash
./home/commands/sync-commands
./home/sync/live-install   # if you used --no-live on sync
```

That regenerates:

- `home/.claude/commands/` — Claude Code (frontmatter + `$ARGUMENTS` + `model:` pin)
- `home/.cursor/commands/` — Cursor (plain markdown + `$1`/`$2`/… + preferred-model note)

`live-install` links generated commands into `~/.cursor/commands/`. Protocols are
linked from `home/protocols/` into `home/.claude/` and `home/.cursor/protocols/`.

Shared sources stay platform-neutral for model pins: write `{{pin:strong}}` (or
`cheap`/`mid`) where a concrete slug is needed; sync expands it per host.

## Orchestrator model tiers

Sources declare an abstract `tier: cheap|mid|strong` (same vocabulary as
`home/agents/`). `sync-commands` maps it through
[`home/agents/model-map.yaml`](../agents/model-map.yaml):

<!-- BEGIN GENERATED MODEL MAP TABLE -->
| Tier | Claude Code (`model:`) | Cursor (preferred session model) |
| --- | --- | --- |
| cheap | `haiku` | `kimi-k2.7-code` |
| mid | `sonnet` | `composer-2.5-fast` |
| strong | `opus` | `cursor-grok-4.5-high-fast` |
<!-- END GENERATED MODEL MAP TABLE -->

Claude Code honors the frontmatter `model:` pin for the command turn. Cursor
slash commands inherit the chat model picker — the generated note asks you to
switch to the mapped pin when the session is on a stronger tier. Subagents keep
their own pins either way.

Current pins (orchestrator only — hard reasoning stays on `verifier` / escalate):

<!-- BEGIN GENERATED COMMAND TIER TABLE -->
| Tier | Commands |
| --- | --- |
| cheap | `/dispatch`, `/ship-digest` |
| mid | `/address-reviews`, `/babysit-fleet`, `/babysit-pr`, `/land`, `/my-work`, `/open-pr`, `/open-work`, `/review-requests`, `/ship`, `/start`, `/watch-boba` |
<!-- END GENERATED COMMAND TIER TABLE -->

**Exception — `/watch-boba`:** mid by default, but may escalate individual
spawns to strong when `boba-watcher` returns `ESCALATE` (one re-classify) or
when drafting a scope/approach unblock. Routine loop ticks stay mid; do not
pin the whole command to strong.

Do **not** hand-edit the generated trees; they are overwritten on sync.
`machine_setup` runs sync-agents → sync-commands → live-install.
