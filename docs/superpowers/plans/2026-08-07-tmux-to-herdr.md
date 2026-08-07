# Tmux → Herdr Implementation Plan

> **For agentic workers:** Execute inline in this session (user requested implement).

**Goal:** Replace tmux with herdr on Mac + WSL (Windows Terminal outer only), native-first.

**Architecture:** Install herdr via brew/curl; checked-in `config.toml` + relocated coding-agent scripts; herdr sidebar/goto replace custom picker/harpoon; keep resolve/launch; Neovim herdr-navigator.

**Tech Stack:** herdr 0.8+, zsh, Neovim Lazy, machine_setup.yaml

## Global Constraints

- Herdr runs in WSL on Windows (not native Windows binary)
- Prefix: `ctrl+space`
- Drop harpoon; drop custom agent sidebar/picker
- Keep Claude-vs-Cursor routing scripts
- Prefer native herdr over custom glue

---

### Task 1: machine_setup + herdr config + scripts

**Files:**
- Modify: `machine_setup.yaml`
- Create: `home/.config/herdr/config.toml`
- Create: `home/.config/herdr/scripts/coding_agent_resolve.sh`
- Create: `home/.config/herdr/scripts/coding_agent_launch.sh`
- Create: `home/.config/herdr/scripts/coding_agent_bind.sh`

### Task 2: Shell aliases

**Files:**
- Create: `home/.config/zsh/herdr_aliases.zsh`
- Modify: `home/.config/zsh/claude_aliases.zsh`
- Modify: `home/.config/zsh/fzf.zsh`, `aws_aliases.zsh`
- Delete: `tmux_aliases.zsh`, `start_tmux.sh`

### Task 3: Neovim

**Files:**
- Modify: `plugins/navigation.lua`, `keymaps/navigation.lua`, `claude.lua`, `coding_agent.lua`, nvim CLAUDE.md

### Task 4: Delete tmux + docs

**Files:**
- Delete: `home/.tmux.conf`, `home/.tmux/`
- Update: KEYBINDS.md, ALIASES.md, CLAUDE.md, CONTEXT.md, WORKFLOWS.md, README.md
