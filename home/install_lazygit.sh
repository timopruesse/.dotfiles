#!/usr/bin/env bash
# Install lazygit from GitHub releases; skip when already on the latest tag.
# Latest-tag lookup is cached (24h) under ~/.cache/dotfiles to avoid GitHub API
# rate limits on every machine_setup / re-run.
set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
CACHE_FILE="$CACHE_DIR/lazygit-latest.version"
CACHE_TTL_SECS="${LAZYGIT_VERSION_CACHE_TTL:-86400}" # 1 day

_cache_age_secs() {
  local file=$1 now mtime
  now=$(date +%s)
  mtime=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null) || return 1
  echo $((now - mtime))
}

_fetch_latest_version() {
  curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
    | sed -n 's/.*"tag_name":[[:space:]]*"v\([^"]*\)".*/\1/p' \
    | head -1
}

resolve_latest_version() {
  local cached age version
  if [ -s "$CACHE_FILE" ]; then
    age=$(_cache_age_secs "$CACHE_FILE" || echo 999999999)
    if [ "$age" -lt "$CACHE_TTL_SECS" ]; then
      cat "$CACHE_FILE"
      return 0
    fi
  fi

  if version=$(_fetch_latest_version) && [ -n "$version" ]; then
    mkdir -p "$CACHE_DIR"
    printf '%s\n' "$version" >"$CACHE_FILE"
    printf '%s\n' "$version"
    return 0
  fi

  # API failed — fall back to stale cache if present.
  if [ -s "$CACHE_FILE" ]; then
    echo "install_lazygit: GitHub API failed; using stale cached version" >&2
    cat "$CACHE_FILE"
    return 0
  fi
  return 1
}

LAZYGIT_VERSION="$(resolve_latest_version || true)"

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
