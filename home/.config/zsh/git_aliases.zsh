alias gd="git diff"
alias gc="git checkout"
alias gb="git branch"
alias new="git checkout -b"
alias pull="git pull"
alias push="git push"
alias gs="git status"
alias commit="git commit -m"
alias add="git add . && git commit --amend"
alias gx="git update-index --chmod=+x"
alias rs="git reset --hard"
alias branch_prune="git branch --merged | egrep -v \"(^\*|main|master|dev)\" | xargs -r git branch -d"
alias patch="git add --patch"
alias gl="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all"

# Jump to the repo's primary checkout (not the linked worktree).
# `git rev-parse --show-toplevel` stays inside ~/.cursor/worktrees (etc.).
gr() {
  local root
  root=$(git worktree list --porcelain 2>/dev/null | awk '/^worktree / { print $2; exit }')
  if [[ -z "$root" ]]; then
    echo "gr: not a git repository" >&2
    return 1
  fi
  cd "$root"
}
