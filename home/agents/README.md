# Shared subagent sources

Edit agent prompts here (`*.md` + `model-map.yaml`), then run:

```bash
./home/sync/sync
```

That regenerates:

- `home/.claude/agents/` — Claude Code pins (from `model-map.yaml`)
- `home/.cursor/agents/` — Cursor pins (from `model-map.yaml`)
- `home/.cursor/rules/subagent-model-fallback.mdc` — tier catalog (from `MODEL-FALLBACK.md`)
- `home/.cursor/rules/agent-routing.mdc` — hard locate/commit/contract rules (from `AGENT-ROUTING.md`)
- marked tables + agent-routing section in `home/.claude/CLAUDE.md` and `home/commands/README.md`
- WORKFLOWS agent roster

Agent roster + jobs: [`WORKFLOWS.md`](../../WORKFLOWS.md) (Agents at a glance).
Tier pins: generated table in [`home/.claude/CLAUDE.md`](../.claude/CLAUDE.md).
Whom / hard must-nots: [`route-agents`](../skills/route-agents/), generated
**agent-routing**.

Live-install (via **sync**) installs into `~/.cursor/agents/`,
`~/.cursor/rules/`, `~/.cursor/hooks{,.json}`, `~/.cursor/skills/`,
`~/.claude/skills/`, and merges
`home/.cursor/cli-config.json` prefs into `~/.cursor/cli-config.json`
(Cursor owns `~/.cursor/` — auth/caches stay local; we never replace the whole
tree or symlink the live CLI config).

Shared sync logic lives in [`home/sync/`](../sync/). Do **not** hand-edit the
generated trees; they are overwritten on sync. `machine_setup` runs **sync**
after the home symlink.

Session cost logging (Claude + Cursor hooks) is documented in
[`SESSION-COST-LOGGING.md`](../../SESSION-COST-LOGGING.md).
