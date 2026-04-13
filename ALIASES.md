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
| `flutter` | `fvm flutter` | Use Flutter via FVM |

## Tmux (`tmux_aliases.zsh`)

| Alias | Command | Description |
|-------|---------|-------------|
| `ss` | `$HOME/start_tmux.sh` | Start/attach tmux session |
| `timo` | `ss timo` | Start personal session |
| `work` | `ss mill` | Start work session |
| `ks` | `tmux kill-session -t` | Kill a tmux session |

## Browser (`browser_aliases.zsh`)

| Alias | Command | Description |
|-------|---------|-------------|
| `nocors` | `chromium --disable-web-security ...` | Launch Chromium with CORS disabled |

## Claude (`claude_aliases.zsh`)

| Function | Command | Description |
|----------|---------|-------------|
| `c` | `tmux new-window "claude"` | Open Claude Code in a new tmux window |
| `c <prompt>` | `tmux new-window "claude -p \"...\""` | Open Claude Code with a prompt in a new tmux window |
| `ch` | `tmux split-window -h "claude"` | Open Claude Code in a horizontal split |
| `ch <prompt>` | `tmux split-window -h "claude -p \"...\""` | Open Claude Code with a prompt in a horizontal split |
| `cv` | `tmux split-window -v "claude"` | Open Claude Code in a vertical split |
| `cv <prompt>` | `tmux split-window -v "claude -p \"...\""` | Open Claude Code with a prompt in a vertical split |
| `cr` | `tmux new-window "claude --continue"` | Resume last Claude Code session in a new tmux window |
