# Cursor Agent tool shells: skip interactive config (keychain, p10k, plugins).
# Heavy rc loading breaks command-completion detection and can leave the CLI
# unable to exit cleanly.
# https://forum.cursor.com/t/guide-fix-cursor-agent-terminal-hangs-caused-by-zshrc/107260
if [[ -n "$CURSOR_AGENT" ]]; then
  return
fi

# load identity
keychain ~/.ssh/id_rsa

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

# fnm (replaces nvm; ~50× faster shell startup)
eval "$(fnm env --use-on-cd --shell zsh)"

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

# claude code: use worktree when inside a git repo with commits (pass --here to opt out)
claude() {
  # --here: skip worktree, run on current branch
  local args=()
  local force_here=false
  for arg in "$@"; do
    if [[ "$arg" == "--here" ]]; then
      force_here=true
      continue
    fi
    args+=("$arg")
  done

  # keep the machine awake for the duration of the run:
  #   macOS -> caffeinate -i prefix (blocks system idle sleep, lets display off)
  #   WSL   -> background powershell.exe holding an ES_SYSTEM_REQUIRED assertion
  #            (the Windows equivalent), killed on return via the EXIT trap
  # On bare Linux neither exists, so this stays a plain `command claude`.
  local run=(command claude)
  if command -v caffeinate &>/dev/null; then
    local claude_bin
    claude_bin=$(whence -p claude 2>/dev/null)
    [[ -n "$claude_bin" ]] && run=(caffeinate -i "$claude_bin")
  elif [[ -n "$WSL_DISTRO_NAME" ]]; then
    local pwsh
    pwsh=$(command -v powershell.exe 2>/dev/null || command -v pwsh.exe 2>/dev/null)
    if [[ -n "$pwsh" ]]; then
      # 2147483649 = ES_CONTINUOUS (0x80000000) | ES_SYSTEM_REQUIRED (0x1)
      "$pwsh" -NoProfile -Command '$s = Add-Type -MemberDefinition "[DllImport(`"kernel32.dll`")] public static extern uint SetThreadExecutionState(uint e);" -Name Power -Namespace Win32 -PassThru; $s::SetThreadExecutionState(2147483649); while ($true) { Start-Sleep 3600 }' &>/dev/null &
      local keepawake_pid=$!
      disown 2>/dev/null
      trap "kill $keepawake_pid 2>/dev/null" EXIT
    fi
  fi

  if $force_here; then
    "${run[@]}" "${args[@]}"
    return
  fi

  local use_worktree=false
  if git rev-parse --is-inside-work-tree &>/dev/null && git rev-parse HEAD &>/dev/null; then
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)

    # skip worktree for dotfiles repo (symlinks need to take effect immediately)
    if [[ "$repo_root" != "$DOTFILES" ]]; then
      use_worktree=true

      # don't append --worktree to subcommands that don't support it
      local subcommands="agents|auth|auto-mode|doctor|install|mcp|plugin|plugins|setup-token|update|upgrade"
      for arg in "${args[@]}"; do
        [[ "$arg" == -* ]] && continue
        [[ "$arg" =~ ^($subcommands)$ ]] && use_worktree=false
        break
      done
    fi
  fi

  if $use_worktree; then
    "${run[@]}" "${args[@]}" --worktree
  else
    "${run[@]}" "${args[@]}"
  fi
}

# open buffer line in editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

# zoxide
export _ZO_DOCTOR=0
eval "$(zoxide init zsh)"

# atuin (shell history; binds Up + Ctrl-R, so keep near the end)
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi
