# Shared subagent sources

Edit agent prompts here (`*.md` + `model-map.yaml`), then run:

```bash
./home/agents/sync-agents
```

That regenerates:

- `home/.claude/agents/` — Claude Code pins (`haiku` / `sonnet` / `opus`)
- `home/.cursor/agents/` — Cursor pins (Kimi / Composer fast / Grok fast)

and installs live symlinks into `~/.cursor/agents/` +
`~/.cursor/rules/subagent-model-fallback.mdc` (Cursor owns `~/.cursor/`; we only
link individual agent/rule files).

Do **not** hand-edit the generated trees; they are overwritten on sync.
`machine_setup` runs the sync after the home symlink.
