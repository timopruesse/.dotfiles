[[ -z $WSL_DISTRO_NAME ]] && return

# fix chromium font error
export FONTCONFIG_PATH=/etc/fonts

export DISPLAY=:0
# use Windows default browser
export BROWSER=/usr/bin/wslview

# D3D12 GPU acceleration
export LIBVA_DRIVER_NAME=d3d12
