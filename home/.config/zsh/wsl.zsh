[[ -z $WSL_DISTRO_NAME ]] && return

# fix chromium font error
export FONTCONFIG_PATH=/etc/fonts

export DISPLAY=:0
# xdg-open's WSL handler calls explorer.exe directly, bypassing MIME defaults
# and $BROWSER (and can return code 4 for local HTML). Use the generic handler
# so web links can use $BROWSER and local files use Linux MIME associations.
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-X-Generic}"

# Resolve beside this file, including when sourced through a dotfiles symlink.
# The opener always uses the default Windows browser.
export BROWSER="${${(%):-%x}:A:h}/wsl_browser.py"

# D3D12 GPU acceleration
export LIBVA_DRIVER_NAME=d3d12
