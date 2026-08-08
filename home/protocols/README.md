# Shared workflow protocols

Canonical contracts used by slash commands on both Claude Code and Cursor:

- [`HANDOFF-PROTOCOL.md`](HANDOFF-PROTOCOL.md) — PR-lifecycle spine, `ADVANCE`/`HALT`, AUTO vs STOP, **land path**
- [`LOOP-PROTOCOL.md`](LOOP-PROTOCOL.md) — shepherd/hub loops, `STATUS:`, `ScheduleWakeup` cadence
- [`AGENT-ROUTING.md`](AGENT-ROUTING.md) — hard must-nots (locate/commit/intake); sync emits Cursor rules + Claude host prose

Symlinked into `~/protocols/` (and linked under `.claude` / `.cursor/protocols/`
for HANDOFF/LOOP) by `home/commands/sync-commands`. Edit here; do not maintain
separate copies under `.claude/` or `.cursor/`. For AGENT-ROUTING, edit this
source — never the generated `agent-routing.mdc` / CLAUDE block.

Flow graph: [`WORKFLOWS.md`](../../WORKFLOWS.md). Session cost logging:
[`SESSION-COST-LOGGING.md`](../../SESSION-COST-LOGGING.md). Glossary:
[`CONTEXT.md`](../../CONTEXT.md).
