# Shared subagent sources

Edit agent prompts here (`*.md` + `model-map.yaml`), then run:

```bash
./home/agents/sync-agents
./home/sync/live-install   # if you used --no-live on sync
```

That regenerates:

- `home/.claude/agents/` — Claude Code pins (from `model-map.yaml`)
- `home/.cursor/agents/` — Cursor pins (from `model-map.yaml`)
- `home/.cursor/rules/subagent-model-fallback.mdc` — tier catalog (generated)
- marked tables in `home/.claude/CLAUDE.md` and `home/commands/README.md`

`live-install` installs live symlinks into `~/.cursor/agents/`,
`~/.cursor/rules/`, `~/.cursor/hooks{,.json}`, and merges
`home/.cursor/cli-config.json` prefs into `~/.cursor/cli-config.json`
(Cursor owns `~/.cursor/` — auth/caches stay local; we never replace the whole
tree or symlink the live CLI config).

Shared sync logic lives in [`home/sync/`](../sync/). Do **not** hand-edit the
generated trees; they are overwritten on sync. `machine_setup` runs the sync
after the home symlink.

Session cost logging (Claude + Cursor hooks) is documented in
[`SESSION-COST-LOGGING.md`](../../SESSION-COST-LOGGING.md).
