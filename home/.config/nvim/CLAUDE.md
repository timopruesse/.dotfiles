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
- `keymaps/` — keybindings split by context (lsp, rust, node, navigation, coding-agent, etc.)
- `coding_agent_herdr.lua` — herdr panes for Pi (with legacy CLI overrides) (`<leader>z*`); calls `coding_agent_herdr.sh`
- `coding_agent.lua` exposes `resolve_cli()` through the shared shell resolver.
- `plugins/ai.lua` configures pi-nvim-context. Keep its Git tag in sync with the npm package in `machine_setup.yaml`.
- `snippets/` — LuaSnip snippets per language (js, rust, lua, svelte)
- `autocommands/` — filetype-specific auto-commands
- `helpers/` — shared utilities (keymap helper, run_on_save)

`<leader>i*` links to a running interactive Pi session. Context goes into Pi's draft without
submitting it. Completion and rewrite require explicit requests and accept actions.
`<leader>z*` still launches coding agents through Herdr and accepts CLI overrides.
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
