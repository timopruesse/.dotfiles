# fzf-tab: replace zsh's completion menu with an fzf picker (with previews).
# Loaded via zcomet in .zshrc; this file only configures it.

# group completions and colorize, which fzf-tab relies on
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# don't reorder git checkout candidates (keep branch/tag ordering)
zstyle ':completion:*:git-checkout:*' sort false

# switch completion groups with < and >
zstyle ':fzf-tab:*' switch-group '<' '>'

# render the picker in a tmux popup when inside tmux
if [[ -n $TMUX ]]; then
  zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
  zstyle ':fzf-tab:*' popup-min-size 80 12
fi

# preview directory contents when completing cd / zoxide
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'
zstyle ':fzf-tab:complete:z:*'  fzf-preview 'eza -1 --color=always --icons $realpath'

# generic preview: directories via eza, files via bat (Ubuntu: batcat) -> cat.
# ${commands[...]} is resolved fresh in the preview shell, so this is portable
# across the WSL (batcat) and macOS (bat) machines.
zstyle ':fzf-tab:complete:*:*' fzf-preview '
  if [[ -d $realpath ]]; then
    eza -1 --color=always --icons $realpath
  elif [[ -f $realpath ]]; then
    ${commands[bat]:-${commands[batcat]:-cat}} --color=always --style=numbers --line-range=:200 $realpath 2>/dev/null || cat $realpath
  fi'
