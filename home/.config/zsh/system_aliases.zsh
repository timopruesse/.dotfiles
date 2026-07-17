alias vim=nvim

alias python=python3

alias ms="machine_setup -c $DOTFILES/machine_setup.yaml"

alias cd=z

alias ls=eza
alias l="eza -la"

alias pn=pnpm

alias lg=lazygit

# cursor agent with Smart Auto by default; --yolo/--force skip it
function agent() {
  if (( ${@[(I)--yolo|--force]} )); then
    command cursor agent "$@"
  else
    command cursor agent --auto-review "$@"
  fi
}

# batch rename via zsh patterns; zmv -n previews, zcp/zln copy/symlink instead
autoload -Uz zmv
alias zcp='zmv -C'
alias zln='zmv -L'
