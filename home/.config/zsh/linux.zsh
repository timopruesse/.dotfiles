[[ "$(uname)" != "Linux" ]] && return

alias trim_vdisk="sudo fstrim -av"
alias clean_snaps="sudo ~/clean_snaps.sh"

# fd-find on Ubuntu installs as `fdfind` due to a name collision
alias fd=fdfind

alias upgrade="sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y"

alias nocors="chromium --disable-web-security --user-data-dir=/tmp/temporary-chrome-profile-dir"
