# .dotfiles

Declarative, YAML-driven dotfiles for WSL2 Ubuntu and macOS. Applied by [machine_setup](https://github.com/timopruesse/machine_setup).

## What's in here

Neovim with [Lazy.nvim](https://github.com/folke/lazy.nvim) and [Catppuccin Mocha](https://github.com/catppuccin/nvim). Zsh, [zcomet](https://github.com/agkozak/zcomet), and [Oh My Posh](https://ohmyposh.dev). [Ghostty](https://ghostty.org) on macOS, [Windows Terminal Preview](https://github.com/timopruesse/.dotfiles/blob/main/terminal/settings.json) on WSL, [Herdr](https://herdr.dev) for multiplexing. Targets WSL2 on Windows and macOS on Apple Silicon.

Coding agents: Claude Code on work repos, Cursor Agent on personal ones (and anywhere else). Same entry points in zsh, Herdr, and Neovim — see [`ALIASES.md`](ALIASES.md), [`KEYBINDS.md`](KEYBINDS.md), and [workflows](#workflows--agent-harness) below for the spine and routing details.

For prompt icons, run `oh-my-posh font install meslo` (machine_setup handles this). On WSL you also need that font installed on Windows, or Windows Terminal shows broken glyphs.

## Setup

### macOS

1. Install machine_setup:
   ```sh
   curl -fsSL https://raw.githubusercontent.com/timopruesse/machine_setup/main/install/install.sh | sh
   ```
2. Put your SSH key in `~/.ssh/`:
   ```sh
   chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_rsa && chmod 644 ~/.ssh/id_rsa.pub
   ```
3. Clone this repo and run `ms`. The first run installs Homebrew, which on a fresh Mac pulls in Xcode Command Line Tools automatically.

### WSL2 (Ubuntu)

The SSH key comes from a Windows OneDrive path — check the `ssh:` task in `machine_setup.yaml`. Install machine_setup, then run `ms`.

## Workflows & agent harness

- [`WORKFLOWS.md`](WORKFLOWS.md) — flow graph
- [`CONTEXT.md`](CONTEXT.md) — glossary (agents, tiers, spine, sync)
- [`SESSION-COST-LOGGING.md`](SESSION-COST-LOGGING.md) — session cost and routing telemetry

## Keybinds

[KEYBINDS.md](KEYBINDS.md) covers Herdr and Neovim.

## Aliases

[ALIASES.md](ALIASES.md) lists zsh aliases and functions, grouped by source file.

## Neovim

Lua config under [`home/.config/nvim/`](https://github.com/timopruesse/.dotfiles/tree/main/home/.config/nvim). mason.nvim + nvim-lspconfig for LSP. conform.nvim formats on save (Prettier, rustfmt, stylua, black, shfmt, goimports). Telescope for fuzzy find. LuaSnip snippets for JS, Rust, Lua, and Svelte.

## How it works

Everything under `home/` symlinks to `~`, so edits here show up in your home directory right away. A few paths are copied instead of symlinked — `etc/wsl.conf` and `terminal/settings.json` — because they need to land outside `$HOME`. Full task list in `machine_setup.yaml`.

Tasks suffixed `_linux` or `_macos` use the YAML `os:` filter so each platform skips the rest. Cross-platform tasks (`rust`, `bun`, `nvim-npm`, `dotfiles`, `personal_repos`) have no filter.

Platform-specific shell bits live in `home/.config/zsh/{wsl,linux,macos}.zsh`. Each file guards itself; the loader at the bottom of `.zshrc` picks up whichever matches.

## Languages and tools

Installed via [`machine_setup.yaml`](machine_setup.yaml) — Homebrew on macOS ([`Brewfile`](Brewfile)), apt and curl on WSL:

Rust (nightly + rustfmt/clippy/rust-analyzer), Node.js (fnm), Bun, Python (pipx), Go. Neovim (nightly on Linux, HEAD on macOS), Herdr, lazygit, Oh My Posh. ripgrep, fd, bat, git-delta, eza, zoxide, fzf, atuin, GitHub CLI. Docker CE on WSL; Colima + Docker on macOS. AWS CLI. Claude Code and Cursor Agent CLI.

Google Chrome on both platforms for the Chrome DevTools MCP server. WSL also installs win32yank for clipboard integration.
