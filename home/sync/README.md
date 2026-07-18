# Sync module

Deep module for generating Claude/Cursor agent + command pins from shared
sources. Domain terms: see [`CONTEXT.md`](../../CONTEXT.md).

| Path | Role |
| --- | --- |
| `common.py` | `parse_model_map`, `link_into`, pin-token expand, marked-section rewrite |
| `catalog.py` | Emit tier catalog (`subagent-model-fallback.mdc` + doc tables) |
| `agents.py` / `commands.py` | Platform writers (thin adapters over common) |
| `live_cursor.py` / `live-install` | Cursor live-install adapter (`~/.cursor`) |

Entry points (also invoked from `machine_setup.yaml`):

```bash
./home/agents/sync-agents          # generate agents + catalog (+ live agents/rule/hooks)
./home/commands/sync-commands      # generate commands + protocols (+ live commands)
./home/sync/live-install           # full ~/.cursor install (hooks, cli merge, …)

# machine_setup uses --no-live on the generators, then live-install once:
./home/agents/sync-agents --no-live
./home/commands/sync-commands --no-live
./home/sync/live-install
```
