function _aws_state_file() {
  local session=$(tmux display-message -p '#{session_name}' 2>/dev/null || echo "default")
  echo "${XDG_STATE_HOME:-$HOME/.local/state}/aws_profile_${session}"
}

function awsp() {
  local config="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
  if [ ! -f "$config" ]; then
    echo "No AWS config found at $config"
    return 1
  fi

  local profiles
  profiles=$(grep '^\[profile ' "$config" | sed 's/\[profile \(.*\)\]/\1/')

  # include default if it exists
  if grep -q '^\[default\]' "$config"; then
    profiles="default\n$profiles"
  fi

  if [ -z "$profiles" ]; then
    echo "No AWS profiles found"
    return 1
  fi

  local current="${AWS_PROFILE:-default}"
  local selected
  selected=$(echo "$profiles" | fzf \
    --height=40% \
    --reverse \
    --prompt="AWS Profile ($current) > " \
    --header="Select an AWS profile" \
  )

  if [ -n "$selected" ]; then
    export AWS_PROFILE="$selected"
    export AWS_DEFAULT_PROFILE="$selected"
    echo "$selected" > "$(_aws_state_file)"
    echo "Switched to AWS profile: $selected"
  fi
}

function awsc() {
  echo "${AWS_PROFILE:-default}"
}

function awsu() {
  unset AWS_PROFILE AWS_DEFAULT_PROFILE
  rm -f "$(_aws_state_file)"
  echo "AWS profile cleared (using default)"
}
