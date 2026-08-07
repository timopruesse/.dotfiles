# Replace tmux with Herdr

Date: 2026-08-07  
Status: approved  
Approach: native-first cutover (design approach 3)

## Context

This dotfiles repo manages a Mac + WSL2 (Ubuntu) development environment via
`machine_setup.yaml`. Tmux is deeply integrated: package install, TPM plugins
(resurrect/continuum/catppuccin), `.tmux.conf`, coding-agent launch/picker/
sidebar/harpoon scripts, zsh aliases, Neovim `vim-tmux-navigator` +
`<leader>z*`, and docs.

Herdr is the replacement multiplexer. It runs **inside WSL on Windows**
(Windows Terminal is only the outer terminal) and natively on macOS. Native
Windows `herdr.exe` is out of scope (preview-only; we chose WSL).

## Goals

- Install herdr (not tmux) on Mac and WSL via `machine_setup.yaml`.
- Prefer **native herdr** features over custom scripts whenever herdr already
  covers the workflow.
- Keep Claude-vs-Cursor coding-agent routing (`coding_agent_resolve` /
  `coding_agent_launch`) — herdr has no opinion on that.
- Preserve muscle memory: prefix `Ctrl+Space`, split chords, coding-agent
  `H`/`V`/`S`/`R`, `Alt+h/j/k/l` Neovim seamless nav.
- Drop harpoon; use herdr sidebar / goto instead.

## Non-goals

- Native Windows Herdr install (`install.ps1` / `herdr.exe`).
- Rebuilding harpoon, custom agent sidebar, fzf agent picker, or status-bar
  agent counts.
- Keeping tmux installed “just in case.”

## Decisions (locked)

| Topic | Choice |
| --- | --- |
| Windows runtime | A — Herdr in WSL; Windows Terminal outer only |
| Depth | Mix of full cutover + native-first: migrate capability-by-capability |
| Prefix | A — keep `ctrl+space` |
| Harpoon | A — drop; use sidebar / `goto` |
| Approach | 3 — native-first cutover in one cohesive change |

## Architecture

```
machine_setup.yaml
  ├─ tools_macos / tools_linux: remove tmux
  ├─ herdr_macos: brew install herdr
  ├─ herdr_linux: curl install.sh | sh ; update via herdr update
  └─ remove tpm clone task

home/.config/herdr/
  ├─ config.toml          # keys, theme, terminal, custom commands
  └─ scripts/
      ├─ coding_agent_resolve.sh   # relocated from .tmux/scripts/
      └─ coding_agent_launch.sh

home/.config/zsh/
  ├─ herdr_aliases.zsh    # ss / timo / work / ks
  └─ claude_aliases.zsh   # herdr splits instead of tmux

Neovim
  ├─ willfish/herdr-navigator.nvim  (replaces vim-tmux-navigator)
  └─ claude.lua / coding_agent.lua  retargeted to herdr CLI + new script paths
```

## §1 Install (`machine_setup.yaml`)

### Mac

- Remove `tmux` from `tools_macos` brew package list.
- Add `herdr_macos` with install/update/uninstall via Homebrew
  (`brew install|upgrade|uninstall herdr`).

### WSL / Linux

- Remove `tmux` from `tools_linux` apt package list.
- Add `herdr_linux`:
  - install: `curl -fsSL https://herdr.dev/install.sh | sh`
  - update: `herdr update`
  - (optional uninstall: document manual remove of install dir; official
    uninstall if documented at implement time)

### Remove

- Entire `tpm` task (clone of `tmux-plugins/tpm`).

### Post-install (both OSes)

- Run `herdr integration install claude` (and Cursor Agent integration if the
  id exists at implement time) so sidebar state is stronger than screen
  detection alone.

### Not doing

- Native Windows PowerShell installer.

## §2 Config & keybinds

### Location

- Checked in: `home/.config/herdr/config.toml`
- Applied via existing `home/` → `~` symlink → `~/.config/herdr/config.toml`

### Core settings

```toml
onboarding = false   # after first interactive setup, or set once in repo

[keys]
prefix = "ctrl+space"

[theme]
name = "catppuccin"

[terminal]
default_shell = "zsh"
new_cwd = "follow"
```

Rely on herdr defaults for mouse and scrollback. No resurrect/continuum —
herdr’s detach + snapshot restore + native agent resume replace them.

### Muscle-memory remaps

| Habit | Herdr |
| --- | --- |
| `prefix \` vertical split | `split_vertical` bound to `prefix+\` (keep or also keep default `prefix+v`) |
| `prefix -` horizontal split | default `prefix+minus` |
| `prefix r` reload | `reload_config = "prefix+r"` |
| `prefix Tab` last window/tab | bind last-tab if available; else drop |
| `` prefix ` `` scratch popup | `[[keys.command]]` `type = "popup"`, `exec "$SHELL"`, ~75%/80% |
| `prefix a` agent sidebar | `toggle_sidebar = "prefix+a"` |
| `prefix C` agent picker | drop fzf picker; use sidebar + `goto` (`prefix+g`); optionally alias `prefix+C` to `goto` |
| Harpoon / `Alt+1`–`4` | removed |

### Coding-agent binds (custom resolve kept)

`[[keys.command]]` entries that invoke relocated launch scripts (exact split
API chosen at implement time via herdr CLI / wrappers):

| Key | Action |
| --- | --- |
| `prefix+H` | vertical split + `coding_agent_launch.sh` |
| `prefix+V` | horizontal split + launch |
| `prefix+S` | new tab + resume |
| `prefix+R` | new tab + continue |

### Neovim seamless navigation

- Install Herdr plugin `willfish/herdr-navigator` (herdr side).
- Neovim: `willfish/herdr-navigator.nvim`.
- Bind `alt+h/j/k/l` to plugin actions in `config.toml`.

### AWS profile picker

- If still useful and not tmux-specific: `[[keys.command]]` popup.
- Else thin rewrite or drop from herdr binds.

## §3 Delete vs keep

### Delete

- `home/.tmux.conf`
- `home/.tmux/` (all scripts: harpoon_*, claude_panel*, claude_picker,
  claude_count, claude_sessions, resurrect_rewrite, etc.)
- `home/start_tmux.sh`
- `home/.config/zsh/tmux_aliases.zsh`
- TPM / `~/.tmux/plugins` (optional cleanup in setup update path)

### Keep, relocate, retarget

- `coding_agent_resolve.sh` + `coding_agent_launch.sh` →
  `home/.config/herdr/scripts/`
- AWS profile helper if kept → same scripts dir
- Session helpers: `ss` / `timo` / `work` / `ks` → herdr session attach/stop

### Neovim

- Remove day-to-day `vim-tmux-navigator` (no `$TMUX` dual path required after
  cutover).
- Add `herdr-navigator.nvim`.
- Retarget `<leader>z*` to herdr pane/tab CLI.

## §4 Shell & Neovim

### Shell

- Add `herdr_aliases.zsh`:
  - `ss` / `timo` / `work` → create-or-attach named herdr sessions
  - `ks` → stop/delete session
- Rewrite `claude_aliases.zsh` helpers to use herdr CLI instead of
  `tmux new-window` / `split-window` / `send-keys`.
- Drop `clist` / `cj` (and similar) that depend on deleted picker/sidebar
  scripts; document herdr sidebar / `herdr agent …` instead.
- `fzf.zsh`: remove `ftb-tmux-popup`.
- `aws_aliases.zsh`: stop using `tmux display-message`; use `HERDR_SESSION` /
  workspace env or a default label.
- Guard: when `HERDR_ENV=1`, wrappers must not nest another `herdr` client
  launch.

### Scripts

- New home: `home/.config/herdr/scripts/`
- Update all callers (zsh, nvim, herdr keybinds).

### Neovim

- `plugins/navigation.lua`: `willfish/herdr-navigator.nvim` with `Alt+h/j/k/l`.
- `claude.lua`: herdr CLI for split/tab/send; simplify paste-to-last-pane if
  herdr API differs.
- `coding_agent.lua`: resolve script path →
  `~/.config/herdr/scripts/coding_agent_resolve.sh`.
- `home/.config/nvim/CLAUDE.md`: tmux → herdr wording.

### Windows Terminal

- No settings change required (no tmux references today).

## §5 Docs & rollout

### Docs to update

- `KEYBINDS.md`
- `ALIASES.md`
- `CLAUDE.md`, `CONTEXT.md`, `WORKFLOWS.md`, `README.md`
- `home/.config/nvim/CLAUDE.md`

### Implementation order

1. `machine_setup.yaml`: add herdr tasks; remove tmux + TPM.
2. Add `config.toml` + relocate coding-agent scripts + keybinds.
3. Shell aliases / fzf / aws.
4. Neovim navigator + `claude.lua` / `coding_agent.lua`.
5. Delete `.tmux*` / `start_tmux.sh` / `tmux_aliases.zsh`.
6. Docs pass.
7. Per machine: apply setup (or install herdr), `herdr integration install
   claude`, then `herdr` from Mac Terminal / Windows Terminal → WSL.

### Success criteria

- Fresh Mac + WSL setup installs herdr, not tmux.
- Prefix is `Ctrl+Space`; sidebar on `prefix+a`; `H`/`V`/`S`/`R` still route
  Claude vs Cursor by cwd rules.
- Daily workflow does not require the `tmux` binary.
- Harpoon and custom agent picker/sidebar scripts are gone.

## Risks & mitigations

| Risk | Mitigation |
| --- | --- |
| Herdr CLI for split+run differs from tmux `-c` + command | Spike `herdr pane` / `keys.command` types during implement; thin wrapper if needed |
| `Alt+h/j/k/l` swallowed by macOS / Windows Terminal | Document terminal settings; herdr keyboard docs recommend verifying outer terminal |
| Cursor Agent integration name/version unclear | Check `herdr integration` list at implement time; Claude is required, Cursor best-effort |
| Named sessions (`timo` / `mill`) semantics differ | Map carefully to `herdr session attach`; verify create-or-attach |
| Nested herdr from shell wrappers | Always check `HERDR_ENV` |

## References

- Install: https://herdr.dev/docs/install/
- Agent guide: https://herdr.dev/agent-guide.md
- Configuration: https://herdr.dev/docs/configuration/
- Session state: https://herdr.dev/docs/session-state/
- Keyboard: https://herdr.dev/docs/keyboard/
- Neovim navigator: https://github.com/willfish/herdr-navigator.nvim
