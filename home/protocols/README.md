# Shared workflow protocols

Canonical contracts used by slash commands on both Claude Code and Cursor:

- [`HANDOFF-PROTOCOL.md`](HANDOFF-PROTOCOL.md) — PR-lifecycle spine, `ADVANCE`/`HALT`, AUTO vs STOP
- [`LOOP-PROTOCOL.md`](LOOP-PROTOCOL.md) — shepherd/hub loops, `STATUS:`, `ScheduleWakeup` cadence

Symlinked into `~/.claude/` (and `home/.cursor/protocols/`) by
`home/commands/sync-commands`. Edit here; do not maintain separate copies under
`.claude/` or `.cursor/`.

Flow graph: [`WORKFLOWS.md`](../../WORKFLOWS.md). Session cost logging:
[`SESSION-COST-LOGGING.md`](../../SESSION-COST-LOGGING.md). Glossary:
[`CONTEXT.md`](../../CONTEXT.md).
