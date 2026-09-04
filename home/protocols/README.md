# Shared workflow protocols

Canonical contracts used by slash commands on Claude Code, Cursor, and Antigravity (agy):

- [`HANDOFF-PROTOCOL.md`](HANDOFF-PROTOCOL.md) — PR-lifecycle spine, `ADVANCE`/`HALT`, AUTO vs STOP, **land path**
- [`LOOP-PROTOCOL.md`](LOOP-PROTOCOL.md) — shepherd/hub loops, `STATUS:`, `ScheduleWakeup` cadence
- [`AGENT-ROUTING.md`](AGENT-ROUTING.md) — hard must-nots (locate/commit/intake); sync emits Cursor rules + Claude host prose
- [`MODEL-FALLBACK.md`](MODEL-FALLBACK.md) — Cursor pin retry / boba escalate; sync emits `subagent-model-fallback.mdc`

Symlinked into `~/protocols/` (and linked under `.claude` / `.cursor/protocols/` /
`.agents/` for HANDOFF/LOOP) by **sync**. Edit here; do not maintain
separate copies under `.claude/` or `.cursor/`. For AGENT-ROUTING and
MODEL-FALLBACK, edit these sources — never the generated mdc / CLAUDE blocks.

Flow graph: [`WORKFLOWS.md`](../../WORKFLOWS.md). Session cost logging:
[`SESSION-COST-LOGGING.md`](../../SESSION-COST-LOGGING.md). Glossary:
[`CONTEXT.md`](../../CONTEXT.md).
