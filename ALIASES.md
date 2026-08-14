# Aliases

All ZSH aliases and functions, grouped by source file.

## Git (`git_aliases.zsh`)

| Alias | Command | Description |
|-------|---------|-------------|
| `gd` | `git diff` | Show diff |
| `gc` | `git checkout` | Checkout branch |
| `gb` | `git branch` | List branches |
| `new` | `git checkout -b` | Create new branch |
| `pull` | `git pull` | Pull changes |
| `push` | `git push` | Push changes |
| `gs` | `git status` | Show status |
| `commit` | `git commit -m` | Commit with message |
| `add` | `git add . && git commit --amend` | Stage all and amend last commit |
| `gx` | `git update-index --chmod=+x` | Make file executable in git |
| `rs` | `git reset --hard` | Hard reset |
| `branch_prune` | `git branch --merged \| egrep -v ... \| xargs -r git branch -d` | Delete merged branches (except main/master/dev) |
| `patch` | `git add --patch` | Interactive partial staging |
| `gl` | `git log --graph --abbrev-commit ...` | Pretty git log graph |
| `gr` | `cd` to primary checkout | Jump to the repo's main working tree (leaves linked worktrees) |

## System (`system_aliases.zsh`)

| Alias | Command | Description |
|-------|---------|-------------|
| `trim_vdisk` | `sudo fstrim -av` | Trim virtual disk (WSL2) |
| `clean_snaps` | `sudo ~/clean_snaps.sh` | Clean up old snap packages |
| `upgrade` | `sudo apt update && apt upgrade ...` | Full system upgrade with autoremove |
| `vim` | `nvim` | Use Neovim as default |
| `python` | `python3` | Use Python 3 as default |
| `ms` | `machine_setup -c $DOTFILES/machine_setup.yaml` | Run dotfiles setup |
| `cd` | `z` | Use zoxide for navigation |
| `ls` | `eza` | Use eza for file listing |
| `l` | `eza -la` | Long listing with hidden files |
| `pn` | `pnpm` | Shorthand for pnpm |
| `lg` | `lazygit` | Open lazygit |
| `claude` | wrapper in `~/.zshrc` | Claude Code CLI; keep-awake + defaults to `--worktree` inside a repo — pass `--here` to stay on the current branch. Skips this dotfiles repo and subcommands like `auth` / `mcp` / `update`. |
| `agent` | wrapper in `~/.zshrc` | Cursor Agent CLI; keep-awake + defaults to `-w` (isolated git worktree) inside a repo — pass `--here` to stay on the current branch. Skips this dotfiles repo and subcommands like `login` / `mcp` / `update`. |
| `zmv` | `autoload zmv` | Batch rename using zsh glob patterns (use `-n` to preview) |
| `zcp` | `zmv -C` | Same as `zmv` but copies instead of renames |
| `zln` | `zmv -L` | Same as `zmv` but creates symlinks instead of renames |

### Linux-only (`linux.zsh`)

| Alias | Command | Description |
|-------|---------|-------------|
| `fd` | `fdfind` | Ubuntu's fd-find package installs as `fdfind` |
| `bat` | `batcat` | Ubuntu's bat package installs as `batcat` (aliased only when present) |

## Global aliases (`global_aliases.zsh`)

Global aliases expand anywhere on the command line, not just at the start. Handy for redirection shortcuts.

| Alias | Expands to | Description |
|-------|------------|-------------|
| `NE` | `2>/dev/null` | Discard stderr |
| `DN` | `>/dev/null` | Discard stdout |
| `NUL` | `>/dev/null 2>&1` | Discard both stdout and stderr |

## Suffix aliases (`suffix_aliases.zsh`)

Typing a bare `path/to/file.ext` opens it in `$EDITOR` (Neovim). Useful when you've copied a path and just want to look at it.

| Extensions | Opens with |
|------------|------------|
| `ts`, `tsx`, `js`, `jsx`, `mjs`, `cjs` | `$EDITOR` |
| `lua`, `rs`, `go`, `py`, `rb` | `$EDITOR` |
| `sh`, `zsh`, `bash` | `$EDITOR` |
| `svelte`, `vue`, `astro` | `$EDITOR` |
| `sql`, `gd`, `gdshader`, `vim` | `$EDITOR` |
| `json`, `jsonc`, `yaml`, `yml`, `toml` | `$EDITOR` |
| `md`, `mdx`, `txt`, `log` | `$EDITOR` |
| `html`, `htm`, `css`, `scss`, `sass` | `$EDITOR` |
| `conf`, `cfg`, `ini`, `env` | `$EDITOR` |

## AWS (`aws_aliases.zsh`)

Pane-scoped via `pane_context.sh` (see `docs/adr/0001-pane-context-per-pane.md`). Inside herdr, profiles are stored per pane (`HERDR_PANE_ID`), mirrored to the sidebar `$aws` token, and pre-injected into agent shell commands when no explicit `--profile` is set.

| Function | Command | Description |
|----------|---------|-------------|
| `awsp` | — | fzf picker; in-pane applies to this pane; `prefix+shift+A` popup sets `PANE_CONTEXT_TARGET=focused` so the picker updates the UI-focused pane |
| `awsc` | — | Print pane file profile, else `$AWS_PROFILE`, else `default` |
| `awsu` | — | Clear pane profile file, herdr `$aws` token, and shell exports |

## Coding agent (`claude_aliases.zsh`)

`c` / `ch` / `cv` / `cr` / `cpi` pick **Claude Code** vs **Cursor Agent** from the cwd
(same rules as git identity — see `~/.config/herdr/scripts/coding_agent_resolve.sh`):

1. `CODING_AGENT=claude|agent` env override
2. Git remote org: `chewielabs` → `claude`, `timopruesse` → `agent`
3. Path: `~/github/chewielabs/*` → `claude`, everything else → `agent`

Per-invocation override: pass `--claude` or `--agent` / `--cursor` to any of the
launchers (e.g. `c --claude`, `ch --agent "fix the flaky test"`).

Launchers run inside herdr (`HERDR_ENV=1`): they call
`coding_agent_herdr.sh` (split/tab + `coding_agent_launch.sh`), so keep-awake and
default worktree apply the same as typing `claude` / `agent`. Herdr
`prefix+shift+H`/`V`/`R`/`S` use the same path.

| Function | Command | Description |
|----------|---------|-------------|
| `c` | new herdr tab with resolved CLI | Open coding agent in a new tab |
| `c <prompt>` | … with positional prompt | Open with an initial prompt |
| `ch` / `cv` | vertical / horizontal split | Same, in a split |
| `cr` | `… --continue` | Continue the last session for that CLI |
| `cpi` | `… -p "…"` | Pipe stdin / instruction in print mode |
| `clist` | `herdr agent list` | List detected coding agents |
| `cj` | — | Reminder: jump agents via goto (`prefix+g`/`prefix+C`) or sidebar; spaces via `prefix+w` (lists agents) |
| `agents-link [dir]` | `ln -s CLAUDE.md AGENTS.md` | Symlink `AGENTS.md` → `CLAUDE.md` so Cursor reads the same instructions as Claude (one source of bytes) |
| `agents-link --all` | — | Do it for every `CLAUDE.md` in the repo (skips `.git`/`node_modules`) |
| `agents-link -f …` | — | Replace an existing `AGENTS.md` **symlink** (never clobbers a real file) |

## Mermaid (`mermaid.zsh`)

| Function | Command | Description |
|----------|---------|-------------|
| `mermaid <file.mmd>` | — | Render a raw `.mmd`/`.mermaid` file in the browser |
| `mermaid <file.md>` | — | Render every ` ```mermaid ` block in a markdown file |
| `… \| mermaid` | — | Render from stdin (also `mermaid -`) |

Renders diagrams with the same `mermaid.js` engine GitHub uses (loaded from a CDN), so the preview matches what GitHub will show — handy for eyeballing a diagram before pushing. Opens in the default browser (`open` on macOS, `$BROWSER`/`wslview` on WSL, `xdg-open` on Linux). Needs a browser + internet on first load.

## Shell tooling

Interactive enhancements wired into the shell (not aliases, but worth knowing):

| Tool | Where | What it does |
|------|-------|--------------|
| **atuin** | `Ctrl-R` / `↑` | SQLite-backed shell history with fuzzy search. `Ctrl-R` searches **all** history; `↑` searches history scoped to the **current directory**. `Enter` runs the selected command; press `Tab` to drop it on the prompt for editing. E2E-encrypted sync via `atuin sync` (config: `~/.config/atuin/config.toml`). |
| **fzf-tab** | `Tab` | Replaces zsh's completion menu with an fzf picker. Previews dirs with `eza` and files with `bat`. Switch completion groups with `<` / `>`. |
| **delta** | `git diff`, `gd`, lazygit | Syntax-highlighted, line-numbered diff pager (Catppuccin Mocha). Press `n` / `N` to jump between files. |
| **bat** | `bat <file>` | Syntax-highlighted `cat` (Catppuccin Mocha). `cat` itself is left untouched. |

### Atuin first-run

On a new machine, after install: `atuin register -u <user> -e <email>` (or `atuin login`), then `atuin import auto` and `atuin sync`.
