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

# herdr-app: render on the GPU. Ubuntu's Mesa ships no Vulkan-on-D3D12 driver,
# so the app's wgpu renderer lands on lavapipe (CPU Vulkan). Hide Vulkan and
# force Mesa's d3d12 OpenGL driver; wgpu then renders through WSLg's D3D12
# path. The two log knobs silence Mesa's harmless EGL probe output.
herdr-app() {
  VK_DRIVER_FILES=/nonexistent GALLIUM_DRIVER=d3d12 \
    EGL_LOG_LEVEL=fatal MESA_LOG=null \
    command herdr-app "$@"
}
