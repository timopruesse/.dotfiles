# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A declarative, YAML-driven dotfiles manager for WSL2 (Ubuntu) and macOS (Apple Silicon) development environments. It manages Neovim, Zsh, Herdr, the terminal (Windows Terminal on WSL, Ghostty on macOS), Git identities, and language toolchain installations (apt/curl on WSL, Homebrew on macOS).

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
  .pi/agent/      # Active Pi instructions + prompt templates (resources only)
  setup_pi.py     # Links resources + merges managed defaults; preserves other state
  skills/         # Portable Herdr and architecture skills
  .claude/        # Independent client preferences + Herdr/AWS hooks
  .cursor/        # Independent client preferences, MCP + Herdr/AWS hooks
  .gemini/        # Independent client preferences, MCP + Herdr hooks
  .config/nvim/   # Neovim config (Lua, Lazy.nvim-based)
  .config/herdr/  # Herdr config + coding_agent_resolve/herdr/launch scripts
  .config/ohmyposh/ # Oh My Posh theme (Catppuccin); Meslo via `oh-my-posh font install meslo`
  .zshrc          # Zsh shell config
  .gitconfig*     # Git config with conditional includes per directory / remote
  *.sh            # Utility scripts (lazygit installer, etc.)
terminal/         # Windows Terminal settings (copied, not symlinked)
etc/              # System config (wsl.conf — requires copy with sudo)
CONTEXT.md                   # Active configuration and workflow glossary
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

## Coding agent routing

Shell aliases (`c`/`ch`/`cv`/`cr`/`cpi`), herdr binds (`prefix+shift+H`/`V`/`R`/`S`),
Neovim `<leader>z*`, and 99 (`<leader>9*`) share one resolver:
[`home/.config/herdr/scripts/coding_agent_resolve.sh`](home/.config/herdr/scripts/coding_agent_resolve.sh).
(Neovim also exposes it as `timopruesse.coding_agent`.) Herdr launches go through
[`coding_agent_herdr.sh`](home/.config/herdr/scripts/coding_agent_herdr.sh) →
[`coding_agent_launch.sh`](home/.config/herdr/scripts/coding_agent_launch.sh)
(direct CLI launch).

Pi is the default everywhere. `CODING_AGENT=pi|claude|codex|agy|agent|cursor`
overrides it (cursor normalizes to agent). Per-call overrides: `--pi` / `--claude` /
`--codex` / `--agy` / `--agent` / `--cursor`. Git identity routing is independent.
The `dotfiles` task runs `python3 $HOME/setup_pi.py` to link Pi resources and apply
GPT 6.1 Sol (`openai/gpt-6.1-sol`) with medium thinking as the startup default.
All approved Pi plugins must be declared in `machine_setup.yaml`'s `pi_packages`
task for both install and update. Workflow migration decisions are tracked in
[`docs/PI-WORKFLOW-MIGRATION.md`](docs/PI-WORKFLOW-MIGRATION.md).
See [`docs/PI.md`](docs/PI.md) for native workflow commands and ownership.
Use available Pi tools directly, or native `pi-subagents` delegation for the approved
workflow commands. There is no generated specialist roster, tier-routing layer,
or custom subagent runtime. The local [`home/pi-workbench/`](home/pi-workbench/)
package adds verification contracts, artifact-first handoffs, and explicit Herdr
visibility/navigation around native `pi-subagents`; it never launches workers.

The `claude`, `codex`, `agy`, and `agent` binaries (and herdr/nvim launches) run in
the current checkout; pass `--worktree` for an isolated git worktree (`-w` is CLI-specific).
Spaces: picker `prefix+w`, new `prefix+shift+N`. Agents: goto
(`prefix+g` / `prefix+C`) or sidebar (`prefix+a`); `clist` wraps
`herdr agent list`. Last pane: `prefix+Tab`.

## Where to read

- Aliases: [`ALIASES.md`](ALIASES.md)
- Keybinds: [`KEYBINDS.md`](KEYBINDS.md)
- Glossary: [`CONTEXT.md`](CONTEXT.md)
- Active Pi setup: [`docs/PI.md`](docs/PI.md)
- Personal Pi instructions: [`home/.pi/agent/AGENTS.md`](home/.pi/agent/AGENTS.md)
- Portable skills: [`home/skills/`](home/skills/)

## Key Behaviors

- **WSL-specific**: `home/.config/zsh/wsl.zsh` sets `DISPLAY` and D3D12 GPU acceleration. It defaults `XDG_CURRENT_DESKTOP` to `X-Generic` so `xdg-open` uses Linux MIME associations instead of the failing WSL/Explorer handler. `BROWSER` points to `home/.config/zsh/wsl_browser.py`, which opens installed WSL Chrome first, otherwise the default Windows browser via PowerShell. Local paths/file URIs are converted with `wslpath`; explicit desktop preferences are preserved.
- **WSLg X11 socket**: Ubuntu 26.04's `tmp.mount` hides WSL's `/tmp/.X11-unix` bind; `etc/wslg-x11-socket.service` (task `wslg_x11_socket`) re-binds `/wslg/.X11-unix` read-only so `DISPLAY=:0` clipboard works.
- **Session persistence**: Herdr keeps pane processes on detach; layout + native agent resume after server restart (with integrations installed).
- **SSH via keychain**: `.zshrc` loads SSH keys through `keychain` on shell start.
- **Sleep prevention**: Configured in the respective CLIs; shell and editor launchers invoke the binaries directly.
- **Neovim plugins auto-install**: Lazy.nvim installs missing plugins on first launch; Treesitter parsers via `:TSUpdate`.
