# Sync module

Deep module for generating Codex/Claude/Cursor/Antigravity agent pins and supported command pins from shared
sources. Domain terms: see [`CONTEXT.md`](../../CONTEXT.md).

| Path | Role |
| --- | --- |
| `sync` | **Conveyor CLI** — generate agents+commands → catalog → live-install → project-agents |
| `conveyor.py` | Orchestrates the conveyor |
| `common.py` | `parse_model_map`, `parse_frontmatter`, `link_into`, pin-token expand, marked-section rewrite |
| `catalog.py` | Emit tier catalog (`subagent-model-fallback.mdc` + `agent-routing.mdc` + doc tables + WORKFLOWS roster) |
| `agents.py` / `commands.py` | Platform writers (thin adapters over common) |
| `live_cursor.py` | Internal live-install adapter (`~/.cursor` + Claude + Antigravity) |
| `live_codex.py` | Install managed native Codex agent TOML files without replacing personal agents or session config |
| `codex_instructions.py` | Generate Codex host instructions from shared routing and tier sources; preserve unrelated live instructions |
| `codex_hooks.py` | Repair the known security-guidance async-handshake incompatibility in Codex's plugin cache |
| `normalize_herdr_hooks.py` / `normalize-herdr-hooks` | Dedupe herdr integration SessionStart hooks (portable `$HOME` paths) |
| `project_agents.py` / `ensure-project-agents` | **project-agents** — also callable from coding-agent launchers for foreign repos |

Entry point (also invoked from `machine_setup.yaml`):

```bash
./home/sync/sync
```

Codex agents are generated in `home/.codex/agents/` and linked into
`~/.codex/agents/`. Their model and reasoning effort come from
`home/agents/model-map.yaml`. The generated `home/.codex/AGENTS.md` is also linked
when no independent user instructions exist; sync preserves existing regular
files and unrelated symlinks. Codex's session `config.toml` remains user-owned.

The security-guidance compatibility repair only removes the known Claude async
handshake from Codex's cached plugin script, preserving its final JSON response.
Run sync after a plugin update if it restores the affected script. Other plugin
versions and unrelated hooks are left alone unless the exact known pattern matches.

Skills are authored under [`home/skills/`](../skills/) (no generate step) and
linked by the conveyor into `~/.cursor/skills/`, `~/.claude/skills/`, and `~/.agents/skills/`.

**project-agents:** Cursor’s Task tool often only discovers agents under the
project’s `.cursor/agents/`, not `~/.cursor/agents/`. This repo commits those
links to `home/.cursor/agents/`. Other repos get them best-effort when a
coding-agent launcher runs (or via `ensure-project-agents` manually); foreign
repos also get `.cursor/agents/` added to `.git/info/exclude`. After linking,
start a **new** Agent session so the Task enum reloads.

Flow graph: [`WORKFLOWS.md`](../../WORKFLOWS.md).
