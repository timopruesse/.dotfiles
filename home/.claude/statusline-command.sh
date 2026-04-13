#!/bin/sh
input=$(cat)

user=$(whoami)
host=$(hostname -s)
dir=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Build PS1-style prefix: bold green user@host, reset, colon, bold blue dir, reset
prefix=$(printf '\033[01;32m%s@%s\033[00m:\033[01;34m%s\033[00m' "$user" "$host" "$dir")

# Build context info
if [ -n "$used" ]; then
  ctx_info=" [ctx: $(printf '%.0f' "$used")%]"
else
  ctx_info=""
fi

printf '%s  %s%s\n' "$prefix" "$model" "$ctx_info"
