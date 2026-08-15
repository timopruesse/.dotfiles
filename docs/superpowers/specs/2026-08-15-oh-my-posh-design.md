# Replace Powerlevel10k with Oh My Posh

Date: 2026-08-15  
Status: approved  
Approach: vendored catppuccin palette + extended segments (design approach 1, amended)

## Context

This dotfiles repo manages Mac + WSL2 (Ubuntu) via `machine_setup.yaml`. The
interactive zsh prompt today is Powerlevel10k (lean, 2-line, transient), loaded
through zcomet from `.zshrc`, with config in `home/.p10k.zsh`. MesloLGS NF is
installed via Brewfile cask (macOS) and a Meslo zip + `fc-cache` task (Linux),
and selected in Ghostty + Windows Terminal.

Oh My Posh replaces p10k as the cross-platform prompt engine. The stack already
uses Catppuccin elsewhere (Herdr, Ghostty); stock Oh My Posh catppuccin supplies
the **palette and diamond/powerline chrome**, extended with the segment set
below.

## Goals

- Install Oh My Posh on macOS (Homebrew) and WSL (official curl installer).
- Drive zsh from a vendored catppuccin-based theme with the locked segment set,
  `transient_prompt`, and auto-upgrade enabled.
- Switch Claude Code statusline to `oh-my-posh claude --config` (same theme).
- Install Meslo via `oh-my-posh font install meslo`; drop prior Meslo zip/cask
  paths; point terminals at `MesloLGM Nerd Font`.
- Show AWS profile/region in the prompt via the Oh My Posh `aws` segment
  (replaces gated p10k AWS prompt display).
- Remove Powerlevel10k load/config from the repo.

## Non-goals

- Full lean-p10k parity (no kube/terraform/asdf/time unless listed below).
- Migrating Cursor Agent statusline (`~/.cursor/statusline.sh`).
- Automating Windows-host font install for Windows Terminal (document only).
- Removing herdr pane-context / `awsp` / `$aws` sidebar (those **set**
  `AWS_PROFILE`; OMP only **displays** it). Confirm if you want that ripped
  out separately.

## Decisions (locked)

| Topic | Choice |
| --- | --- |
| Theme base | Stock catppuccin palette/chrome; **not** stock segment list |
| Segments | bun, claude, svelte, aws, node, rust, git, executiontime, path, project, status |
| Claude statusline | `oh-my-posh claude --config ~/.config/ohmyposh/catppuccin.omp.json` |
| Install | A — brew on macOS; curl script on WSL |
| Fonts | C — `oh-my-posh font install meslo`; drop Meslo cask/zip tasks |
| Wiring approach | 1 — vendored theme + declarative `machine_setup` |
| AWS prompt | OMP `aws` segment; keep pane-context/`awsp` unless overruled |

## Architecture

```
machine_setup.yaml
  ├─ tools_macos / Brewfile: add oh-my-posh; remove font-meslo-lg-nerd-font
  ├─ ohmyposh_linux: curl install.sh | bash -s
  ├─ ohmyposh_post (both): enable upgrade + font install meslo
  └─ remove font_linux Meslo zip task

home/.config/ohmyposh/catppuccin.omp.json
  └─ catppuccin palette + segment layout below + transient + upgrade.auto

home/.zshrc
  ├─ remove p10k instant prompt / zcomet powerlevel10k / source .p10k.zsh
  └─ eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/catppuccin.omp.json)"
     (optionally via _dotfiles_cache_source)

home/.claude/settings.json
  └─ statusLine → oh-my-posh claude --config …/catppuccin.omp.json

Terminals
  ├─ Ghostty font-family → MesloLGM Nerd Font
  └─ Windows Terminal font.face → MesloLGM Nerd Font

Delete
  ├─ home/.p10k.zsh
  └─ home/.claude/statusline-command.sh

Keep (AWS set, not display)
  └─ pane_context.sh / awsp / herdr $aws / agent AWS hooks
```

## §1 Prompt theme & shell init

- Start from stock
  [catppuccin.omp.json](https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/themes/catppuccin.omp.json)
  at `home/.config/ohmyposh/catppuccin.omp.json` (keep palette + diamond/
  powerline styling).
- Replace the stock segment list (`os`, `session`, …) with the layout below.
- Add `transient_prompt` (e.g. `❯`, green/red by last status when easy).
- Add theme `upgrade` block with `auto: true` (complements CLI enable).
- `.zshrc`: drop p10k instant-prompt block, `zcomet load romkatv/powerlevel10k`,
  and `[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh`.
- Init after PATH includes Homebrew / `~/.local/bin`:

  ```zsh
  eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/catppuccin.omp.json)"
  ```

  Prefer caching via existing `_dotfiles_cache_source` if it fits cleanly.
- Keep early `CURSOR_AGENT` return (no Oh My Posh in agent tool shells).
- Delete `home/.p10k.zsh`.

### Segment layout (how they display)

Two-line prompt (closer to former lean p10k; keeps the line readable):

```
path  git  project  [node|rust|bun|svelte]  [aws]  [claude]
❯                          status  executiontime
```

| Segment | Placement | When / notes |
| --- | --- | --- |
| `path` | Left L1 | Always; keep stock-ish `agnoster_short` + home `~` |
| `git` | Left L1 | In repo; `fetch_status: true` (stock had `false`) so dirty/ahead show |
| `project` | Left L1 | When a project file exists (`package.json` / `Cargo.toml` / …) — name@version |
| `node` | Left L1 | `display_mode: context` (project/files); omit in `$HOME` |
| `rust` | Left L1 | `display_mode: context`; omit in `$HOME` |
| `bun` | Left L1 | `display_mode: context` (bun.lock / bun.lockb); omit in `$HOME` |
| `svelte` | Left L1 | `display_mode: files` (default); omit in `$HOME` |
| `aws` | Left L1 | When profile active; `display_default: false` so quiet on bare `default` |
| `claude` | Left L1 | Only when Claude statusline data is present (`oh-my-posh claude`); no-op in normal zsh |
| `status` | Right L2 | Exit code / error (hide on success if segment allows) |
| `executiontime` | Right L2 | After slow commands (threshold ~3s, matching former p10k) |

Drop stock always-on `os` + `session` (user@host) — noise; not in the requested set.

Palette: reuse catppuccin `blue` / `pink` / `lavender` (+ one accent for aws/status) so chrome stays consistent with Herdr/Ghostty.

### AWS vs custom scripting

- **Prompt display:** Oh My Posh `aws` replaces gated p10k AWS (ADR soft seam).
- **Profile selection / pane scope:** keep `awsp` / `pane_context.sh` / herdr `$aws` /
  Claude+Cursor inject hooks — they export `AWS_PROFILE`, which the segment reads.
- Update ADR note from “gated p10k AWS” → “OMP aws segment + pane-context setter”.

## §2 Install, fonts, upgrades

### macOS

- Brewfile: `brew "jandedobbeleer/oh-my-posh/oh-my-posh"` (or equivalent tap
  formula entry accepted by `brew bundle`).
- Remove `cask "font-meslo-lg-nerd-font"`.
- Post-install (machine_setup or tools_macos follow-up):  
  `oh-my-posh enable upgrade` and `oh-my-posh font install meslo`.

### WSL / Linux

- New `ohmyposh_linux` task:  
  `curl -s https://ohmyposh.dev/install.sh | bash -s`  
  (default install dir `~/bin` or `~/.local/bin`; PATH already covers the latter).
- Replace `font_linux` Meslo zip + `fc-cache` with OMP font install (same
  post-steps as macOS).
- Document: Windows Terminal renders fonts from the **Windows** host; WSL
  `font install` alone does not update WT. User may need to install Meslo on
  Windows once (or re-run OMP font install from a Windows-side shell).

### Terminals

- `home/.config/ghostty/config`: `font-family = MesloLGM Nerd Font`
- `terminal/settings.json`: `"face": "MesloLGM Nerd Font"`

## §3 Claude statusline & cleanup

- `home/.claude/settings.json`:

  ```json
  "statusLine": {
    "type": "command",
    "command": "oh-my-posh claude --config ~/.config/ohmyposh/catppuccin.omp.json",
    "padding": 0
  }
  ```

  Same theme as zsh so `claude` + `path` / `git` / etc. render in the TUI
  statusline (built-in default alone would ignore our segment set).

- Delete `home/.claude/statusline-command.sh`.
- Do not change session-cost hooks (`log-session` / JSONL).
- Do not change Cursor `cli-config.json` statusline.
- Docs: README shell line; CLAUDE.md fonts/p10k notes; ADR 0001 soft-seam
  wording; other p10k mentions only if clearly stale for this cutover.

## Testing (manual)

1. Fresh shell: catppuccin chrome; path + git in a repo; icons with new font.
2. In a Node/Bun/Svelte/Rust project: matching language/cli segments appear;
   absent outside context.
3. `awsp` → profile shows on prompt; `awsu` / default-hidden when
   `display_default: false`.
4. Slow command (≥3s) → executiontime; failing command → status.
5. Enter → transient prompt replaces full prompt.
6. Claude Code statusline uses OMP theme (model/ctx via `claude` segment), not
   the old bash script.
7. `CURSOR_AGENT=1 zsh -i -c 'echo ok'` still skips heavy rc / OMP.
8. macOS + WSL: binary on PATH after machine_setup install path.

## Open notes

- Brew-managed binary on macOS vs CDN auto-upgrade: follow upstream behavior;
  `enable upgrade` still requested. If brew and auto-upgrade fight, prefer brew
  upgrades on macOS and keep auto-upgrade effective on the curl-installed WSL
  binary (adjust in implementation if conflict is confirmed).
- Non-interactive `oh-my-posh font install meslo`: confirm CLI flags during
  implementation; if a TTY confirm is required, use whatever non-interactive
  flag exists or document a one-shot manual step in machine_setup comments.
