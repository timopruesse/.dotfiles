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
| `live_install.py` | Internal full live-install across hosts |
| `managed_links.py` | Shared ownership checks, link-set preflight and owned stale-link pruning |
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
Cursor launcher runs (or via `ensure-project-agents` manually); foreign
repos also get `.cursor/agents/` added to Git's resolved exclude file, including worktrees. After linking,
start a **new** Agent session so the Task enum reloads.

Flow graph: [`WORKFLOWS.md`](../../WORKFLOWS.md).

Managed agent/command/rule links preserve unrelated names and reject personal
collisions before changing that set. Managed skill names explicitly replace
conflicting files, directories, or symlinks without backups. Source directories
must exist before stale owned links can be pruned. Bulk setup excludes `.codex`;
sync alone installs its managed agents and instructions.

Generated files passing tests do not establish runtime agent availability. For a
runtime check, request a bounded read-only native specialist task in the affected
client, wait for completion, and record the exact error or result. If unavailable,
the parent continues within existing authorization under AGENT-ROUTING.

Observed 2026-09-18 in the active Codex chat: native launches of `scout-explain`,
`worker`, `verifier`, and `review` were advertised but rejected with
`agent type is currently not available`. All 12 installed agent TOMLs parsed and
linked to their generated sources. The local CLI reported 0.155.0; the chat
runtime version was not established. This is an unresolved runtime finding,
not proof that the generated format is incompatible. A fresh target-client/CLI
comparison remains the next diagnostic; sync does not launch agents to test it.

## Skill description budget

`skill_descriptions.json` stores concise discovery summaries for the installed
skills. Detailed triggers stay in each skill's Markdown body, which loads on use.
The two managed skills are edited at `home/skills/`; installed personal, system,
and plugin skills are edited in place. Plugin or Codex updates can restore their
upstream descriptions.

To reapply after an update, export a fresh Codex app-server `skills/list` response
(with `forceReload: true` and the current repository in `cwds`) to a JSON file:

```bash
python3 home/sync/compact_skill_descriptions.py --inventory /tmp/skills.json
python3 home/sync/compact_skill_descriptions.py --inventory /tmp/skills.json --apply
```

The helper only touches enabled skills in that explicit inventory with a curated
summary. Preview is the default; `--apply` preserves other frontmatter and moves
the previous description into the body. Reapplying the same summary is a no-op.
Use the target client's inventory: the CLI and desktop can advertise different
plugins. Reload `skills/list` afterward to check for parsing errors and compare
skill counts. Restart the target client if its existing session retains old metadata.

This is an opt-in maintenance command, not part of the general sync conveyor.
Descriptions should stay concise and distinguish neighboring skills; do not
remove important invocation boundaries merely to hit a character target.
