[[ "$(uname)" != "Darwin" ]] && return

alias upgrade="brew update && brew upgrade && brew cleanup"

alias nocors='open -na "Google Chrome" --args --disable-web-security --user-data-dir=/tmp/temporary-chrome-profile-dir'
