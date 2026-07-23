# Domain context

Glossary for the agent/command/protocol spine in this dotfiles repo. Architecture
reviews and sync tooling should use these names.

## Core modules

| Term | Meaning |
| --- | --- |
| **agent** (subagent) | A pinned specialist prompt under `home/agents/`, generated into Claude + Cursor trees. Abstract `tier:` only in sources. |
| **command** (slash command / orchestrator) | A protocol router under `home/commands/` that gathers, gates, spawns agents, and hands off. |
| **skill** | Orchestrator-facing procedure pack under `home/skills/` (`*/SKILL.md`). Live-installed into `~/.cursor/skills/` and `~/.claude/skills/`. For parent routing / env workflows — not a substitute for agent prompts. |
| **protocol** | Shared contract in `home/protocols/` — `HANDOFF-PROTOCOL` (spine) and `LOOP-PROTOCOL` (shepherd/hub loops). |
| **tier** | Abstract cost/capability band: `cheap` \| `mid` \| `strong`. Mapped to host model slugs by `model-map.yaml`. |
| **model-map** | `home/agents/model-map.yaml` — single source of truth for tier → Claude/Cursor pins. |
| **sync** | `home/sync/` — deep module that parses the map, generates platform trees, emits the tier catalog. Entry points: `home/agents/sync-agents`, `home/commands/sync-commands`. |
| **live-install** | `home/sync/live-install` — Cursor adapter that installs agents/commands/skills/hooks/rules and merges CLI prefs into `~/.cursor` (plus Claude skills) without replacing that tree. |
| **session-log** | `home/session_log/` — shared JSONL append/error core; Claude and Cursor hooks are adapters. |
| **coding-agent resolve** | `home/.tmux/scripts/coding_agent_resolve.sh` — picks `claude` vs `agent` for shared zsh/tmux/Neovim launchers (env → remote org → path). Same work/personal split as git identity. |

## Workflow vocabulary

| Term | Meaning |
| --- | --- |
| **spine** | Auto-chaining PR lifecycle from `/dispatch` through mergeable/merged (`HANDOFF-PROTOCOL`). |
| **Mode A / Mode B** | Mode A pauses at preview gates; Mode B (`/ship` / `--auto`) auto-approves deterministic gates. |
| **shepherd** | Converging loop (`/babysit-pr`, `/babysit-fleet`, `/watch-boba`) driven by `STATUS:` + `ScheduleWakeup`. |
| **hub** | Non-converging ambient loop (`/my-work watch`) — re-fire only, no `STATUS:`. |
| **Boba** | External Jira→PR pipeline (`boba_fetch`); `/dispatch` may label, `/watch-boba` shepherds until a PR opens. |
| **ADVANCE / HALT** | Terminal line every spine step emits for the handoff contract. |

## Authoring rules

- Edit **sources** under `home/agents/`, `home/commands/`, `home/protocols/`,
  `home/skills/` — never the generated `.claude`/`.cursor` trees.
- Prefer **tier** language in shared prose; use `{{pin:cheap|mid|strong}}` in command bodies when a concrete slug must appear — sync expands it per host.
- Classifier agents still embed the `STATUS:` enum in their own prompts (isolated spawn context); `LOOP-PROTOCOL.md` remains authoritative.
- Domain names here trump file nicknames when discussing seams and deepening.

## Where to read next

- Flow graph: [`WORKFLOWS.md`](WORKFLOWS.md)
- Host routing prose: [`home/.claude/CLAUDE.md`](home/.claude/CLAUDE.md)
- Session cost logging: [`SESSION-COST-LOGGING.md`](SESSION-COST-LOGGING.md)
- Shell / tmux / Neovim launchers: [`ALIASES.md`](ALIASES.md), [`KEYBINDS.md`](KEYBINDS.md)
- Repo setup: [`CLAUDE.md`](CLAUDE.md)
