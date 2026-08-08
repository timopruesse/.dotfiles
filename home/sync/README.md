# Sync module

Deep module for generating Claude/Cursor agent + command pins from shared
sources. Domain terms: see [`CONTEXT.md`](../../CONTEXT.md).

| Path | Role |
| --- | --- |
| `common.py` | `parse_model_map`, `link_into`, pin-token expand, marked-section rewrite |
| `catalog.py` | Emit tier catalog (`subagent-model-fallback.mdc` + `agent-routing.mdc` + doc tables) |
| `agents.py` / `commands.py` | Platform writers (thin adapters over common) |
| `live_cursor.py` / `live-install` | Cursor live-install adapter (`~/.cursor`) + Claude skills |
| `project_agents.py` / `ensure-project-agents` | **project-agents** — link pinned agents into `<git-root>/.cursor/agents/` so Cursor Task/CLI can spawn them |

Entry points (also invoked from `machine_setup.yaml`):

```bash
./home/agents/sync-agents          # generate agents + catalog (+ live agents/rule/hooks/skills)
./home/commands/sync-commands      # generate commands + protocols (+ live commands/skills)
./home/sync/live-install           # full ~/.cursor install (hooks, cli merge, skills, …)
./home/sync/ensure-project-agents  # link agents into this repo’s .cursor/agents/ (Task enum)

# machine_setup uses --no-live on the generators, then live-install once:
./home/agents/sync-agents --no-live
./home/commands/sync-commands --no-live
./home/sync/live-install
./home/sync/ensure-project-agents  # after generate, for this dotfiles checkout
```

Skills are authored under [`home/skills/`](../skills/) (no generate step) and
linked by live-install into `~/.cursor/skills/` and `~/.claude/skills/`.

**project-agents:** Cursor’s Task tool often only discovers agents under the
project’s `.cursor/agents/`, not `~/.cursor/agents/`. This repo commits those
links to `home/.cursor/agents/`. Other repos get them best-effort when a
coding-agent launcher runs (or via `ensure-project-agents` manually); foreign
repos also get `.cursor/agents/` added to `.git/info/exclude`. After linking,
start a **new** Agent session so the Task enum reloads.

Flow graph: [`WORKFLOWS.md`](../../WORKFLOWS.md).
