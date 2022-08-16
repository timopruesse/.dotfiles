export TMUX_SESSION_PERSONAL="timo"
export TMUX_SESSION_WORK="NO"

alias start="$HOME/start_tmux.sh $TMUX_SESSION_PERSONAL"
alias work="$HOME/start_tmux.sh $TMUX_SESSION_WORK"

alias stop="tmux kill-session -t $TMUX_SESSION_PERSONAL"
alias stop_work="tmux kill-session -t $TMUX_SESSION_WORK"
