# Shared skills (orchestrator)

Edit skill packs here (`*/SKILL.md`), then run:

```bash
./home/sync/live-install
```

That links each skill into:

- `~/.cursor/skills/<name>/` — Cursor personal skills
- `~/.claude/skills/<name>/` — Claude Code skills

Skills are for the **parent / orchestrator** (routing, env workflows). Do not
rely on them inside pinned subagents — those get an isolated spawn context;
put always-on procedure in the agent prompt (or sync-time includes) instead.

## Packs in this tree

| Skill | Role |
| --- | --- |
| [`route-agents`](route-agents/) | Whom-table — which pinned agent / command to spawn |
| [`improve-codebase-architecture`](improve-codebase-architecture/) | Architecture review HTML report + grill loop; fans out via `scout` / `scout-explain` (never Explore) |

Hard rules: generated **agent-routing** (see [`CONTEXT.md`](../../CONTEXT.md)).
Flow graph: [`WORKFLOWS.md`](../../WORKFLOWS.md).

`machine_setup` runs live-install after sync. Sources under `home/skills/` also
land at `~/skills/` via the home symlink (same pattern as `agents/`).
