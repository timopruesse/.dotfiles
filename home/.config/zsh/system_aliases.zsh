alias vim=nvim

alias python=python3

alias ms="machine_setup -c $DOTFILES/machine_setup.yaml"

alias cd=z

alias ls=eza
alias l="eza -la"

alias pn=pnpm

alias lg=lazygit

# Cursor Agent CLI with Smart Auto by default.
# Named `agent` like the real ~/.local/bin/agent binary — call via whence -p so we
# never recurse through this function or the IDE `cursor agent` shim. Skip Smart
# Auto for --yolo/--force/--auto-review and for CLI subcommands (login, mcp, …).
# Agent tool shells should not load this (see CURSOR_AGENT guard in ~/.zshrc).
function agent() {
  local bin
  bin=$(whence -p agent) || {
    print -u2 "agent: Cursor Agent CLI not found in PATH"
    return 127
  }

  local -a skip_auto=(
    login logout mcp plugin about status whoami models update
    create-chat generate-rule rule worker help
    install-shell-integration uninstall-shell-integration
  )
  if (( ${@[(I)--yolo|--force|--auto-review]} )) || (( ${skip_auto[(Ie)${1:-}]} )); then
    "$bin" "$@"
  else
    "$bin" --auto-review "$@"
  fi
}

# batch rename via zsh patterns; zmv -n previews, zcp/zln copy/symlink instead
autoload -Uz zmv
alias zcp='zmv -C'
alias zln='zmv -L'
