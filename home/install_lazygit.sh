#!/usr/bin/env bash
# Install lazygit from GitHub releases; skip when already on the latest tag.
set -euo pipefail

LAZYGIT_VERSION="$(
  curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
    | sed -n 's/.*"tag_name":[[:space:]]*"v\([^"]*\)".*/\1/p' \
    | head -1
)"

if [ -z "$LAZYGIT_VERSION" ]; then
  echo "install_lazygit: could not resolve latest version" >&2
  exit 1
fi

if command -v lazygit >/dev/null 2>&1; then
  INSTALLED="$(lazygit --version 2>/dev/null | sed -n 's/.*version=\([^,]*\).*/\1/p' | head -1)"
  if [ "$INSTALLED" = "$LAZYGIT_VERSION" ]; then
    echo "lazygit already current ($LAZYGIT_VERSION)"
    exit 0
  fi
fi

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/lazygit.XXXXXX")"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

curl -fsSL -o "$WORKDIR/lazygit.tar.gz" \
  "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf "$WORKDIR/lazygit.tar.gz" -C "$WORKDIR" lazygit
sudo install "$WORKDIR/lazygit" /usr/local/bin
echo "lazygit version $LAZYGIT_VERSION has been installed successfully."
