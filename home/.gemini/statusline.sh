#!/usr/bin/env bash
# Antigravity (agy) CLI status line → Oh My Posh (reuse `claude` renderer).
#
# Antigravity's StatusLinePayload is Claude-aligned, but OMP's claude segment expects
# integer context percentages and a structured cost object. This adapter
# normalizes stdin, then renders the shared theme.
set -euo pipefail

CONFIG="${HOME}/.config/ohmyposh/catppuccin.omp.json"

# Statusline is agent UI (not a zsh readline) — theme hides vimode when set.
export AGY_AGENT="${AGY_AGENT:-1}"

if ! command -v oh-my-posh >/dev/null 2>&1; then
  echo "oh-my-posh missing" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq missing" >&2
  exit 1
fi

# Floor float percentages; null output tokens → 0; normalize cost to object.
jq '
  .context_window.used_percentage |= (if . == null then . else floor end)
  | .context_window.remaining_percentage |= (if . == null then . else floor end)
  | .context_window.total_output_tokens |= (if . == null then 0 else . end)
  | if (.cost | type) == "number" then
      .cost = { "total_cost_usd": .cost }
    elif (.cost | type) != "object" then
      .cost = { "total_cost_usd": 0 }
    else
      .
    end
  | .model as $m
  | ($m.display_name // $m.id // "?") as $shown
  | ($m.id // "") as $id
  | .model.display_name = (
      if ($shown | ascii_downcase) == "auto" and ($id != "") and (($id | ascii_downcase) != "auto") then
        "Auto (\($id))"
      else
        $shown
      end
    )
' | oh-my-posh claude --config "$CONFIG"
