# Shared workflow protocols

Canonical contracts used by slash commands on both Claude Code and Cursor:

- [`HANDOFF-PROTOCOL.md`](HANDOFF-PROTOCOL.md) — PR-lifecycle spine (incl.
  optional `researcher` prep above `/dispatch`), `ADVANCE`/`HALT` (missing line
  ⇒ `HALT: missing terminal contract`), AUTO vs STOP, land path
- [`LOOP-PROTOCOL.md`](LOOP-PROTOCOL.md) — shepherd/hub loops, `STATUS:`, `ScheduleWakeup` cadence

Symlinked into `~/.claude/` (and `home/.cursor/protocols/`) by
`home/commands/sync-commands`. Edit here; do not maintain separate copies under
`.claude/` or `.cursor/`.

Visual map + hard **agent-routing** summary: [`WORKFLOWS.md`](../../WORKFLOWS.md).
Session cost / debug logging (separate from these contracts) lives in
[`SESSION-COST-LOGGING.md`](../../SESSION-COST-LOGGING.md). Domain glossary:
[`CONTEXT.md`](../../CONTEXT.md).
