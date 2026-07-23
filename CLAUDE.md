# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A declarative, YAML-driven dotfiles manager for a WSL2 (Ubuntu) development environment. It manages Neovim, Zsh, Tmux, Windows Terminal, Git identities, and language toolchain installations.

## How Dotfiles Are Applied

There is no Makefile or shell install script. The system is orchestrated via `machine_setup.yaml` (and `personal_repositories.yaml`), interpreted by an external tool from the `timopruesse/machine_setup` repo. Supported operations in YAML tasks:

- `run`: Execute shell commands
- `symlink`: Create symlinks (the `home/` directory is symlinked to `~`)
- `clone`: Git clone via SSH
- `copy`: Copy files (supports `sudo`)
- `machine_setup`: Recursively invoke another YAML config

To apply dotfiles changes: the `home/` directory contents are symlinked to `~`, so edits here take effect immediately. For `etc/wsl.conf` or `terminal/settings.json`, those are **copied** (not symlinked) by the setup tool.

## Repository Structure

```
home/             # Symlinked to ~ — contains all user config files
  agents/         # Shared subagent sources (tier + prompts); run sync-agents
  commands/       # Shared slash-command sources; run sync-commands
  skills/         # Orchestrator skills (route-agents, …); live-install
  protocols/      # Shared HANDOFF + LOOP protocols (→ ~/protocols)
  sync/           # Deep sync module + live-install (Claude/Cursor pins)
  session_log/    # Shared session JSONL core (hooks are adapters)
  .claude/        # Claude Code config (generated agents/ + commands/, protocol symlinks)
  .cursor/        # Cursor pins (agents/, commands/, rules/, protocols/, cli-config.json) — NOT bulk-symlinked; live-install into ~/.cursor
  .config/nvim/   # Neovim config (Lua, Lazy.nvim-based)
  .zshrc          # Zsh shell config (claude/agent wrappers: keep-awake + worktrees)
  .tmux.conf      # Tmux config (coding-agent binds resolve Claude vs Cursor)
  .tmux/scripts/  # coding_agent_resolve/launch + session picker/sidebar helpers
  .gitconfig*     # Git config with conditional includes per directory / remote
  *.sh            # Utility scripts (lazygit installer, tmux starter, etc.)
terminal/         # Windows Terminal settings (copied, not symlinked)
etc/              # System config (wsl.conf — requires copy with sudo)
fonts/            # MesloLGS NF fonts for Powerlevel10k
CONTEXT.md                   # Domain glossary (agents, tiers, spine, sync)
machine_setup.yaml           # Main setup orchestration
personal_repositories.yaml   # Clones personal repos after setup
```

## Neovim Configuration

The Neovim config lives under `home/.config/nvim/` (Lazy.nvim-based). Its
architecture, formatting-on-save setup, and LSP conventions are documented in
[`home/.config/nvim/CLAUDE.md`](home/.config/nvim/CLAUDE.md), which loads only when
working in that directory.

## Git Identity Setup

`.gitconfig` uses conditional includes to switch identities. Path rules cover the
common clone layouts; remote-URL rules win for worktrees / odd checkout paths:

- `gitdir:~/` → `.gitconfig_personal`
- `gitdir:~/github/chewielabs/` → `.gitconfig_mill`
- remote `github.com/chewielabs/**` → `.gitconfig_mill`
- remote `github.com/timopruesse/**` → `.gitconfig_personal`

When adding new work contexts, add matching `includeIf` blocks and an identity file.

## Coding agent routing (Claude vs Cursor)

Shell aliases (`c`/`ch`/`cv`/`cr`/`cpi`), tmux binds (`prefix H`/`V`/`R`/`S`),
Neovim `<leader>z*`, and 99 (`<leader>9*`) share one resolver:
[`home/.tmux/scripts/coding_agent_resolve.sh`](home/.tmux/scripts/coding_agent_resolve.sh).
(Neovim also exposes it as `timopruesse.coding_agent`.)

Precedence: `CODING_AGENT=claude|agent` → git remote org → path
(`~/github/chewielabs` → Claude Code; everything else → Cursor `agent`).
Per-call overrides: `--claude` / `--agent` on the launchers.

Both `claude` and `agent` wrappers in `.zshrc` default to an isolated git
worktree inside a repo (`--worktree` / `-w`); pass `--here` to stay on the
current branch. Dotfiles itself is excluded so symlink edits take effect
immediately. Session listing (`clist`/`cj`, `prefix C`/`a`, status `[ai: N]`)
tracks both CLIs.

Canonical docs: [`ALIASES.md`](ALIASES.md), [`KEYBINDS.md`](KEYBINDS.md).

## Keybinds Reference

All Tmux and Neovim keybindings are documented in [`KEYBINDS.md`](KEYBINDS.md). This is the canonical reference for shortcuts across the environment.

## Aliases Reference

All ZSH aliases and functions are documented in [`ALIASES.md`](ALIASES.md), grouped by source file (git, system, tmux, coding agent, …).

## Workflows Reference

Domain glossary: [`CONTEXT.md`](CONTEXT.md). The slash commands and subagents
are mapped as a flow graph in [`WORKFLOWS.md`](WORKFLOWS.md). Host routing prose
lives in [`home/.claude/CLAUDE.md`](home/.claude/CLAUDE.md). Shared spine/loop
contracts are in [`home/protocols/`](home/protocols/).

## Session cost logging

Per-session JSONL logs (Claude estimated USD + tokens; Cursor duration / status /
subagents) are documented in [`SESSION-COST-LOGGING.md`](SESSION-COST-LOGGING.md).

## Key Behaviors

- **WSL-specific**: `.zshrc` sets `DISPLAY`, `BROWSER=wslview`, and D3D12 GPU acceleration for WSL2.
- **Session persistence**: Tmux uses `tmux-resurrect` + `tmux-continuum` to auto-restore sessions.
- **SSH via keychain**: `.zshrc` loads SSH keys through `keychain` on shell start.
- **Keep-awake CLI sessions**: `claude` / `agent` wrappers hold idle sleep (macOS `caffeinate` / WSL `ES_SYSTEM_REQUIRED`).
- **Neovim plugins auto-install**: Lazy.nvim installs missing plugins on first launch; Treesitter parsers via `:TSUpdate`.
