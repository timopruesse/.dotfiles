# .dotfiles

Declarative, YAML-driven dotfiles for a cross-platform development environment (WSL2 Ubuntu and macOS). Managed by [machine_setup](https://github.com/timopruesse/machine_setup).

## Overview

- **Editor**: Neovim (Lua, [Lazy.nvim](https://github.com/folke/lazy.nvim)) with [Catppuccin Mocha](https://github.com/catppuccin/nvim) theme
- **Shell**: Zsh + [zcomet](https://github.com/agkozak/zcomet) + [Oh My Posh](https://ohmyposh.dev) (Catppuccin)
- **Terminal**: [Ghostty](https://ghostty.org) (macOS) / [Windows Terminal Preview](https://github.com/timopruesse/.dotfiles/blob/main/terminal/settings.json) (WSL) + [Herdr](https://herdr.dev) (Catppuccin)
- **OS**: WSL2 (Ubuntu) on Windows; macOS (Apple Silicon)
- **AI**: Claude Code (work) + Cursor Agent (personal / everywhere else), shared shortcuts in zsh, herdr, and Neovim — see [`ALIASES.md`](ALIASES.md) / [`KEYBINDS.md`](KEYBINDS.md). Spine + glossary: [Workflows & agent harness](#workflows--agent-harness).

Prompt fonts: install via `oh-my-posh font install meslo` (machine_setup). On WSL, also install that font on **Windows** so Windows Terminal can render icons.

## Setup

### macOS

1. Install the `machine_setup` tool:
   ```sh
   curl -fsSL https://raw.githubusercontent.com/timopruesse/machine_setup/main/install/install.sh | sh
   ```
2. Drop your SSH key into `~/.ssh/`:
   ```sh
   chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_rsa && chmod 644 ~/.ssh/id_rsa.pub
   ```
3. Clone this repo and run `ms`. The first task installs Homebrew, which auto-prompts for Xcode Command Line Tools on a fresh Mac.

### WSL2 (Ubuntu)

The SSH key is sourced from a Windows OneDrive path; see the `ssh:` task in `machine_setup.yaml`. Run `ms` after `machine_setup` is installed.

## Workflows & agent harness

- Flow graph: [`WORKFLOWS.md`](WORKFLOWS.md)
- Glossary: [`CONTEXT.md`](CONTEXT.md)
- Session cost / routing telemetry: [`SESSION-COST-LOGGING.md`](SESSION-COST-LOGGING.md)

## Keybinds

See [KEYBINDS.md](KEYBINDS.md) for a full reference of Tmux and Neovim keybindings.

## Aliases

See [ALIASES.md](ALIASES.md) for all ZSH aliases grouped by category.

## Neovim

The config is written in Lua and lives in [`home/.config/nvim/`](https://github.com/timopruesse/.dotfiles/tree/main/home/.config/nvim). Key features:

- LSP via mason.nvim + nvim-lspconfig
- Format on save via conform.nvim (Prettier, rustfmt, stylua, black, shfmt, goimports)
- Telescope for fuzzy finding
- LuaSnip snippets for JS, Rust, Lua, Svelte

## How It Works

The `home/` directory is symlinked to `~`, so edits take effect immediately. System-level files (`etc/wsl.conf`, `terminal/settings.json`) are copied by the setup tool. See `machine_setup.yaml` for the full task list.

Tasks suffixed with `_linux` or `_macos` use the YAML `os:` filter so each platform only runs the relevant ones. Cross-platform tasks (`rust`, `bun`, `nvim-npm`, `dotfiles`, `personal_repos`) have no filter.

Platform-specific shell config is split into `home/.config/zsh/{wsl,linux,macos}.zsh`, each self-guarded so the loader at the bottom of `.zshrc` picks up only the right one.

## Languages & Tools

Managed via [`machine_setup.yaml`](machine_setup.yaml) — macOS via [`Brewfile`](Brewfile), WSL/Ubuntu via apt and curl installers:

- **Languages:** Rust (nightly + rustfmt/clippy/rust-analyzer), Node.js (fnm), Bun, Python (pipx), Go
- **Dev environment:** Neovim (nightly on Linux, HEAD on macOS), Herdr, lazygit, Oh My Posh
- **CLI utilities:** ripgrep, fd, bat, git-delta, eza, zoxide, fzf, atuin, GitHub CLI
- **Containers & cloud:** Docker (Docker CE on WSL; Colima + Docker on macOS), AWS CLI
- **AI agents:** Claude Code, Cursor Agent CLI

Google Chrome is installed on both platforms for the Chrome DevTools MCP server. WSL adds win32yank for clipboard integration.
