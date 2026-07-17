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
  protocols/      # Shared HANDOFF + LOOP protocols (→ ~/protocols)
  .claude/        # Claude Code config (generated agents/ + commands/, protocol symlinks)
  .cursor/        # Cursor pins (agents/, commands/, rules/, protocols/) — NOT bulk-symlinked; sync scripts install into ~/.cursor
  .config/nvim/   # Neovim config (Lua, Lazy.nvim-based)
  .zshrc          # Zsh shell config
  .tmux.conf      # Tmux config
  .gitconfig*     # Git config with conditional includes per directory
  *.sh            # Utility scripts (lazygit installer, tmux starter, etc.)
terminal/         # Windows Terminal settings (copied, not symlinked)
etc/              # System config (wsl.conf — requires copy with sudo)
fonts/            # MesloLGS NF fonts for Powerlevel10k
machine_setup.yaml           # Main setup orchestration
personal_repositories.yaml   # Clones personal repos after setup
```

## Neovim Configuration

The Neovim config lives under `home/.config/nvim/` (Lazy.nvim-based). Its
architecture, formatting-on-save setup, and LSP conventions are documented in
[`home/.config/nvim/CLAUDE.md`](home/.config/nvim/CLAUDE.md), which loads only when
working in that directory.

## Git Identity Setup

`.gitconfig` uses conditional includes to switch identities based on working directory:

- `~/` → `.gitconfig_personal`
- `~/github/chewielabs/` → `.gitconfig_mill`

When adding new work contexts, add an `includeIf "gitdir:..."` block to `.gitconfig` and create a corresponding identity file.

## Keybinds Reference

All Tmux and Neovim keybindings are documented in [`KEYBINDS.md`](KEYBINDS.md). This is the canonical reference for shortcuts across the environment.

## Aliases Reference

All ZSH aliases and functions are documented in [`ALIASES.md`](ALIASES.md), grouped by source file (git, system, tmux, browser, claude).

## Workflows Reference

The slash commands (authored in `home/commands/`, generated to
`home/.claude/commands/` and `home/.cursor/commands/`) and the subagents they
orchestrate (authored in `home/agents/`, generated to `home/.claude/agents/` and
`home/.cursor/agents/`) are mapped as a flow graph in [`WORKFLOWS.md`](WORKFLOWS.md)
— roughly the PR lifecycle, front to back. The prose reference lives in
[`home/.claude/CLAUDE.md`](home/.claude/CLAUDE.md). Shared spine/loop contracts are
in [`home/protocols/`](home/protocols/).

## Session cost logging

Per-session JSONL logs (Claude estimated USD + tokens; Cursor duration / status /
subagents) are documented in [`SESSION-COST-LOGGING.md`](SESSION-COST-LOGGING.md).

## Key Behaviors

- **WSL-specific**: `.zshrc` sets `DISPLAY`, `BROWSER=wslview`, and D3D12 GPU acceleration for WSL2.
- **Session persistence**: Tmux uses `tmux-resurrect` + `tmux-continuum` to auto-restore sessions.
- **SSH via keychain**: `.zshrc` loads SSH keys through `keychain` on shell start.
- **Neovim plugins auto-install**: Lazy.nvim installs missing plugins on first launch; Treesitter parsers via `:TSUpdate`.
