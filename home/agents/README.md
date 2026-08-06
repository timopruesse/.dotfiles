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
- `home/.cursor/rules/agent-routing.mdc` — hard locate/commit/contract rules (generated)
- marked tables + agent-routing section in `home/.claude/CLAUDE.md` and `home/commands/README.md`

## Agents (sources)

| Agent | Tier | Job |
| --- | --- | --- |
| `scout` | cheap | LOCATE / gather |
| `researcher` | cheap | RESEARCH / spike prep (`ADVANCE → parent`) |
| `committer` | cheap | git commit plumbing |
| `scout-explain` | mid | EXPLAIN subsystem |
| `worker` | mid | implement (never commit; `ADVANCE → /land`) |
| `sweep` | mid | lint/tsc loops (`ADVANCE → /land` \| `done`) |
| `pr-babysitter` | mid | shepherd one PR |
| `pr-reviewer` | mid | draft-only PR review |
| `boba-watcher` | mid | classify Boba ticket signal |
| `verifier` | strong | adversarial `VERDICT:` |

`live-install` installs live symlinks into `~/.cursor/agents/`,
`~/.cursor/rules/`, `~/.cursor/hooks{,.json}`, `~/.cursor/skills/`,
`~/.claude/skills/`, and merges
`home/.cursor/cli-config.json` prefs into `~/.cursor/cli-config.json`
(Cursor owns `~/.cursor/` — auth/caches stay local; we never replace the whole
tree or symlink the live CLI config).

Orchestrator routing heuristics live in [`home/skills/route-agents/`](../skills/route-agents/)
(not in agent prompts). Hard must-nots: generated **agent-routing** rule.
Flow graph: [`WORKFLOWS.md`](../../WORKFLOWS.md).

Shared sync logic lives in [`home/sync/`](../sync/). Do **not** hand-edit the
generated trees; they are overwritten on sync. `machine_setup` runs the sync
after the home symlink.

Session cost logging (Claude + Cursor hooks) is documented in
[`SESSION-COST-LOGGING.md`](../../SESSION-COST-LOGGING.md).
