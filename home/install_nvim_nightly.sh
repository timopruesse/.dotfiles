#!/usr/bin/env bash
# Install or refresh Neovim nightly into /opt/nvim when the GitHub nightly
# commit changes. Keeps nightly; skips the tarball when already current.
# Nightly-commit lookup is cached (24h) under ~/.cache/dotfiles to avoid
# GitHub API hits on every re-run.
set -euo pipefail

ARCH="$(uname -m)"
case "$ARCH" in
  aarch64) ARCH=arm64 ;;
esac

STAMP_DIR="/opt/nvim"
STAMP_FILE="${STAMP_DIR}/.nightly-commit"
URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-${ARCH}.tar.gz"
TMP_TAR="/tmp/nvim-nightly.tar.gz"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
CACHE_FILE="$CACHE_DIR/nvim-nightly.commit"
CACHE_TTL_SECS="${NVIM_NIGHTLY_CACHE_TTL:-86400}" # 1 day

_cache_age_secs() {
  local file=$1 now mtime
  now=$(date +%s)
  mtime=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null) || return 1
  echo $((now - mtime))
}

_fetch_remote_commit() {
  curl -fsSL https://api.github.com/repos/neovim/neovim/releases/tags/nightly \
    | sed -n 's/.*"target_commitish":[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -1
}

resolve_remote_commit() {
  local age commit
  if [ -s "$CACHE_FILE" ]; then
    age=$(_cache_age_secs "$CACHE_FILE" || echo 999999999)
    if [ "$age" -lt "$CACHE_TTL_SECS" ]; then
      cat "$CACHE_FILE"
      return 0
    fi
  fi

  if commit=$(_fetch_remote_commit) && [ -n "$commit" ]; then
    mkdir -p "$CACHE_DIR"
    printf '%s\n' "$commit" >"$CACHE_FILE"
    printf '%s\n' "$commit"
    return 0
  fi

  if [ -s "$CACHE_FILE" ]; then
    echo "install_nvim_nightly: GitHub API failed; using stale cached commit" >&2
    cat "$CACHE_FILE"
    return 0
  fi
  return 1
}

REMOTE="$(resolve_remote_commit || true)"
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
# Keep API cache aligned with what we just installed.
mkdir -p "$CACHE_DIR"
printf '%s\n' "$REMOTE" >"$CACHE_FILE"
