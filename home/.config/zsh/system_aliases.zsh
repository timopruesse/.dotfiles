alias vim=nvim

alias python=python3

alias ms="machine_setup -c $DOTFILES/machine_setup.yaml"

alias cd=z

alias ls=eza
alias l="eza -la"

alias pn=pnpm

alias lg=lazygit

# batch rename via zsh patterns; zmv -n previews, zcp/zln copy/symlink instead
autoload -Uz zmv
alias zcp='zmv -C'
alias zln='zmv -L'
