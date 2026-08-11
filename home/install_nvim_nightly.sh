#!/usr/bin/env bash
# Install or refresh Neovim nightly into /opt/nvim when the GitHub nightly
# commit changes. Keeps nightly; skips the tarball when already current.
set -euo pipefail

ARCH="$(uname -m)"
case "$ARCH" in
  aarch64) ARCH=arm64 ;;
esac

STAMP_DIR="/opt/nvim"
STAMP_FILE="${STAMP_DIR}/.nightly-commit"
URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-${ARCH}.tar.gz"
TMP_TAR="/tmp/nvim-nightly.tar.gz"

remote_commit() {
  curl -fsSL https://api.github.com/repos/neovim/neovim/releases/tags/nightly \
    | sed -n 's/.*"target_commitish":[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -1
}

REMOTE="$(remote_commit)"
if [ -z "$REMOTE" ]; then
  echo "install_nvim_nightly: could not resolve nightly commit" >&2
  exit 1
fi

LOCAL=""
if [ -f "$STAMP_FILE" ]; then
  LOCAL="$(cat "$STAMP_FILE")"
fi

if [ -x /opt/nvim/bin/nvim ] && [ -n "$LOCAL" ] && [ "$LOCAL" = "$REMOTE" ]; then
  echo "neovim nightly already current ($REMOTE)"
  sudo -n ln -sfn /opt/nvim/bin/nvim /usr/local/bin/nvim
  exit 0
fi

echo "installing neovim nightly ($REMOTE)"
curl -fsSL -o "$TMP_TAR" "$URL"
sudo -n rm -rf /opt/nvim
sudo -n mkdir -p /opt/nvim
sudo -n tar -C /opt/nvim --strip-components=1 -xzf "$TMP_TAR"
sudo -n ln -sfn /opt/nvim/bin/nvim /usr/local/bin/nvim
rm -f "$TMP_TAR"
printf '%s\n' "$REMOTE" | sudo -n tee "$STAMP_FILE" >/dev/null
