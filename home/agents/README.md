# Shared subagent sources

Edit agent prompts here (`*.md` + `model-map.yaml`), then run:

```bash
./home/agents/sync-agents
```

That regenerates:

- `home/.claude/agents/` — Claude Code pins (`haiku` / `sonnet` / `opus`)
- `home/.cursor/agents/` — Cursor pins (Kimi / Composer fast / Grok fast)

and installs live symlinks into `~/.cursor/agents/`,
`~/.cursor/rules/subagent-model-fallback.mdc`, and
`~/.cursor/hooks{,.json}`, plus merges
`home/.cursor/cli-config.json` prefs into `~/.cursor/cli-config.json`
(Cursor owns `~/.cursor/` — auth/caches stay local; we never replace the whole
tree or symlink the live CLI config).

Do **not** hand-edit the generated trees; they are overwritten on sync.
`machine_setup` runs the sync after the home symlink.

Session cost logging (Claude + Cursor hooks) is documented in
[`SESSION-COST-LOGGING.md`](../../SESSION-COST-LOGGING.md).
