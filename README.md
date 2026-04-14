# .dotfiles

Declarative, YAML-driven dotfiles for a WSL2 development environment. Managed by [machine_setup](https://github.com/timopruesse/machine_setup).

## Overview

- **Editor**: Neovim (Lua, [Lazy.nvim](https://github.com/folke/lazy.nvim)) with [Catppuccin Mocha](https://github.com/catppuccin/nvim) theme
- **Shell**: Zsh + [Oh My Zsh](https://ohmyz.sh/) + [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- **Terminal**: [Windows Terminal Preview](https://github.com/timopruesse/.dotfiles/blob/main/terminal/settings.json) + tmux (also Catppuccin themed)
- **OS**: WSL2 (Ubuntu) on Windows
- **AI**: Claude Code integration in both Neovim and tmux

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

## Languages & Tools

Managed via `machine_setup.yaml`: Rust (nightly), Node (nvm), Bun, Deno, Python, Go, Dart/Flutter, plus lazygit, ripgrep, eza, zoxide, and fzf.
