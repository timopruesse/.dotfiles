alias upgrade="sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y"

alias nvim=$HOME/.nvim/nvim.appimage
alias vim=nvim

alias python=python3

alias ms="machine_setup -c $DOTFILES/machine_setup.yaml"

export TMUX_SESSION="timo"

alias tmux_create="tmux new -s$TMUX_SESSION"
alias tmux_attach="tmux attach -d -t $TMUX_SESSION"

alias start="tmux_attach || tmux_create"
alias tkill="tmux kill-session -t $TMUX_SESSION"
