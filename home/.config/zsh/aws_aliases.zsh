# AWS profile helpers — pane-scoped via pane_context.sh (see docs/adr/0001-pane-context-per-pane.md).
PANE_CONTEXT="${HOME}/.config/herdr/scripts/pane_context.sh"

function awsp() {
  local config="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
  if [ ! -f "$config" ]; then
    echo "No AWS config found at $config"
    return 1
  fi

  local profiles
  profiles=$(grep '^\[profile ' "$config" | sed 's/\[profile \(.*\)\]/\1/')

  if grep -q '^\[default\]' "$config"; then
    profiles="default\n$profiles"
  fi

  if [ -z "$profiles" ]; then
    echo "No AWS profiles found"
    return 1
  fi

  local current
  if [ "${HERDR_ENV:-}" = "1" ] && [ -x "$PANE_CONTEXT" ]; then
    current=$("$PANE_CONTEXT" get-aws 2>/dev/null || true)
  fi
  current="${current:-${AWS_PROFILE:-default}}"

  local selected
  selected=$(echo "$profiles" | fzf \
    --height=40% \
    --reverse \
    --prompt="AWS Profile ($current) > " \
    --header="Select an AWS profile")

  if [ -z "$selected" ]; then
    return 0
  fi

  if [ "${HERDR_ENV:-}" = "1" ] && [ -x "$PANE_CONTEXT" ]; then
    # PANE_CONTEXT_TARGET=focused (set by prefix+shift+A popup) applies to the UI-focused pane.
    "$PANE_CONTEXT" set-aws "$selected" || return 1
    # CLI runs in a subprocess — export here when this shell is the target pane.
    if [ -z "${PANE_CONTEXT_TARGET:-}" ] && [ -n "${HERDR_PANE_ID:-}" ]; then
      export AWS_PROFILE="$selected"
      export AWS_DEFAULT_PROFILE="$selected"
    fi
    echo "Switched AWS profile for pane to: $selected"
  else
    export AWS_PROFILE="$selected"
    export AWS_DEFAULT_PROFILE="$selected"
    echo "Switched to AWS profile: $selected"
  fi
}

function awsc() {
  if [ "${HERDR_ENV:-}" = "1" ] && [ -x "$PANE_CONTEXT" ]; then
    local from_file
    from_file=$("$PANE_CONTEXT" get-aws 2>/dev/null || true)
    if [ -n "$from_file" ]; then
      echo "$from_file"
      return 0
    fi
  fi
  echo "${AWS_PROFILE:-default}"
}

function awsu() {
  if [ "${HERDR_ENV:-}" = "1" ] && [ -x "$PANE_CONTEXT" ]; then
    "$PANE_CONTEXT" clear-aws || return 1
    if [ -z "${PANE_CONTEXT_TARGET:-}" ] && [ -n "${HERDR_PANE_ID:-}" ]; then
      unset AWS_PROFILE AWS_DEFAULT_PROFILE
    fi
    echo "AWS profile cleared for this pane (using default)"
  else
    unset AWS_PROFILE AWS_DEFAULT_PROFILE
    echo "AWS profile cleared (using default)"
  fi
}
