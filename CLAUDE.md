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

## Neovim Configuration Architecture

The Neovim config (`home/.config/nvim/`) uses **Lazy.nvim** and is organized under `lua/timopruesse/`:

- `init.lua` — top-level entry, bootstraps Lazy.nvim and loads plugin specs
- `sets.lua` — editor options
- `theme.lua` — Catppuccin theme setup
- `lsp.lua` — LSP server configuration (via mason.nvim + nvim-lspconfig)
- `telescope.lua` — fuzzy finder setup
- `keymaps/` — keybindings split by context (lsp, rust, node, navigation, etc.)
- `snippets/` — LuaSnip snippets per language (js, rust, lua, svelte)
- `autocommands/` — filetype-specific auto-commands
- `helpers/` — shared utilities (keymap helper, run_on_save)

Formatting on save is handled by **conform.nvim**:
- JS/TS/JSON/YAML/HTML/CSS/GraphQL/Markdown → Prettier
- Rust → rustfmt
- Lua → stylua
- Python → black
- Shell → shfmt
- Go → goimports + gofmt

LSP servers are managed by **mason.nvim** and configured individually in `lsp.lua`.

## Git Identity Setup

`.gitconfig` uses conditional includes to switch identities based on working directory:
- `~/` → `.gitconfig_personal`
- `~/github/chewielabs/` → `.gitconfig_mill`

When adding new work contexts, add an `includeIf "gitdir:..."` block to `.gitconfig` and create a corresponding identity file.

## Key Behaviors

- **WSL-specific**: `.zshrc` sets `DISPLAY`, `BROWSER=wslview`, and D3D12 GPU acceleration for WSL2.
- **Session persistence**: Tmux uses `tmux-resurrect` + `tmux-continuum` to auto-restore sessions.
- **SSH via keychain**: `.zshrc` loads SSH keys through `keychain` on shell start.
- **Neovim plugins auto-install**: Lazy.nvim installs missing plugins on first launch; Treesitter parsers via `:TSUpdate`.
