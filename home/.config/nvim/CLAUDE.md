# CLAUDE.md — Neovim

Guidance for working in the Neovim config (`home/.config/nvim/`). Loads only when
editing files under this directory.

## Configuration Architecture

The Neovim config uses **Lazy.nvim** and is organized under `lua/timopruesse/`:

- `init.lua` — top-level entry, bootstraps Lazy.nvim and loads plugin specs
- `sets.lua` — editor options
- `theme.lua` — Catppuccin theme setup
- `lsp.lua` — LSP server configuration (via mason.nvim + nvim-lspconfig)
- `telescope.lua` — fuzzy finder setup
- `keymaps/` — keybindings split by context (lsp, rust, node, navigation, claude/coding-agent, etc.)
- `claude.lua` — tmux integration for Claude Code / Cursor Agent (`<leader>z*`); resolves via `timopruesse.coding_agent` (same script as shell/tmux)
- `coding_agent.lua` — shared `resolve_cli()` used by `claude.lua` and 99
- `plugins/ai.lua` — ThePrimeagen/99; provider auto-picks Claude vs Cursor from cwd
- `snippets/` — LuaSnip snippets per language (js, rust, lua, svelte)
- `autocommands/` — filetype-specific auto-commands
- `helpers/` — shared utilities (keymap helper, run_on_save)

`<leader>9*` (99) and `<leader>z*` (tmux panes) both follow coding-agent routing.
Full keybind table: [`KEYBINDS.md`](../../../KEYBINDS.md).

Formatting on save is handled by **conform.nvim**:

- JS/TS/JSON/YAML/HTML/CSS/GraphQL/Markdown → Prettier
- Rust → rustfmt
- Lua → stylua
- Python → black
- Shell → shfmt
- Go → goimports + gofmt

LSP servers are managed by **mason.nvim** and configured individually in `lsp.lua`.

Neovim plugins auto-install: Lazy.nvim installs missing plugins on first launch;
Treesitter parsers via `:TSUpdate`.
