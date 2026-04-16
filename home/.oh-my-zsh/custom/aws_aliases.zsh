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
    echo "Switched to AWS profile: $selected"
  fi
}

function awsc() {
  echo "${AWS_PROFILE:-default}"
}

function awsu() {
  unset AWS_PROFILE AWS_DEFAULT_PROFILE
  echo "AWS profile cleared (using default)"
}
