# Cursor Agent tool shells: skip interactive config (keychain, p10k, plugins).
# Heavy rc loading breaks command-completion detection and can leave the CLI
# unable to exit cleanly.
# https://forum.cursor.com/t/guide-fix-cursor-agent-terminal-hangs-caused-by-zshrc/107260
if [[ -n "$CURSOR_AGENT" ]]; then
  return
fi

# load identity — --quick skips when the agent already holds a key;
# --eval points this shell at keychain's agent (not e.g. macOS launchd's empty sock)
eval "$(keychain --quiet add --eval --quick ~/.ssh/id_rsa)"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# history (replaces oh-my-zsh defaults)
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

# command auto-correction (was OMZ ENABLE_CORRECTION="true")
setopt correct
alias bun='nocorrect bun'

# zcomet plugin manager
if [[ ! -f ~/.zcomet/bin/zcomet.zsh ]]; then
  command git clone https://github.com/agkozak/zcomet.git ~/.zcomet/bin
fi
source ~/.zcomet/bin/zcomet.zsh

# theme
zcomet load romkatv/powerlevel10k

# plugins
# order matters: completions feed compinit; fzf-tab must load after compinit but
# before the widget-wrapping plugins; zsh-syntax-highlighting must come last.
zcomet load zsh-users/zsh-completions

zcomet compinit

zcomet load Aloxaf/fzf-tab
zcomet load zsh-users/zsh-autosuggestions
zcomet load zsh-users/zsh-syntax-highlighting

# user aliases / functions / environment
for f in ~/.config/zsh/*.zsh(N); do
  source "$f"
done

# customize auto suggestions
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#82909b"

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
export VISUAL=nvim
export EDITOR=$VISUAL

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.

# added by pipx (https://github.com/cs01/pipx)
export PATH="$HOME/.local/bin:$PATH"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# atuin binary (official installer → ~/.atuin/bin; shell init is below)
export PATH="$HOME/.atuin/bin:$PATH"

# Cache `cmd` stdout and source it. Regenerate when $bin is newer than the
# cache (or the cache is missing). Avoids re-running init generators every
# interactive shell.
_dotfiles_cache_source() {
  local cache=$1 bin=$2
  shift 2
  [[ -n $bin && -x $bin ]] || return 0
  if [[ ! -s $cache || $bin -nt $cache ]]; then
    mkdir -p "${cache:h}"
    "$@" >|"$cache" || {
      rm -f "$cache"
      return 1
    }
  fi
  source "$cache"
}

# fnm (replaces nvm). `fnm env` mints a unique FNM_MULTISHELL_PATH per shell,
# so the full eval cannot be cached. Recreate the symlink here (cheap) and
# cache only the static exports + use-on-cd hook.
if (( $+commands[fnm] )); then
  () {
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
    local cache="$cache_dir/fnm_static.zsh"
    local fnm_bin=${commands[fnm]}
    local fnm_dir="${FNM_DIR:-$HOME/.local/share/fnm}"
    local default="$fnm_dir/aliases/default"
    local state="${XDG_STATE_HOME:-$HOME/.local/state}/fnm_multishells"
    local multi="$state/$$_${EPOCHREALTIME//./}"

    mkdir -p "$state"
    if [[ -e $default || -L $default ]]; then
      ln -sfn "$default" "$multi"
    else
      # Fall back to full fnm env when no default alias exists yet.
      eval "$(fnm env --use-on-cd --shell zsh)"
      return
    fi
    export FNM_MULTISHELL_PATH=$multi
    path=("$multi/bin" $path)

    if [[ ! -s $cache || $fnm_bin -nt $cache ]]; then
      mkdir -p "$cache_dir"
      # Drop PATH / MULTISHELL lines — we set those above. Cache-miss still
      # runs fnm once (and leaves one orphan multishell); hits are free.
      fnm env --use-on-cd --shell zsh \
        | grep -Ev '^(export PATH=|export FNM_MULTISHELL_PATH=)' >|"$cache" \
        || {
          rm -f "$cache"
          eval "$(fnm env --use-on-cd --shell zsh)"
          return
        }
    fi
    source "$cache"
  }
fi

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# deno
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="/home/timo/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Coding-agent launch policy (keep-awake + default worktree) — shared with
# herdr keybinds via ~/.config/herdr/scripts/coding_agent_launch.sh
source "${HOME}/.config/herdr/scripts/coding_agent_policy.zsh"

# Thin wrappers: real binary via whence -p inside coding_agent_keep_awake_run.
# Pass --here to stay on the current branch (skip default worktree).
claude() {
  coding_agent_with_policy claude "$@"
}

agent() {
  coding_agent_with_policy agent "$@"
}

# open buffer line in editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

# zoxide / atuin: cache generated init (safe — output is static per binary)
export _ZO_DOCTOR=0
if (( $+commands[zoxide] )); then
  _dotfiles_cache_source \
    "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/zoxide_init.zsh" \
    "${commands[zoxide]}" \
    zoxide init zsh
fi

if (( $+commands[atuin] )); then
  _dotfiles_cache_source \
    "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/atuin_init.zsh" \
    "${commands[atuin]}" \
    atuin init zsh
fi

unfunction _dotfiles_cache_source
