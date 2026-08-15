#!/usr/bin/env bash
# Cursor Agent CLI status line → Oh My Posh (reuse `claude` renderer).
#
# Cursor's StatusLinePayload is Claude-aligned, but OMP's claude segment expects
# integer context percentages (Cursor often sends floats) and has no Auto→resolved
# model rewrite. This adapter normalizes stdin, then renders the shared theme.
set -euo pipefail

CONFIG="${HOME}/.config/ohmyposh/catppuccin.omp.json"

if ! command -v oh-my-posh >/dev/null 2>&1; then
  echo "oh-my-posh missing" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq missing" >&2
  exit 1
fi

# Floor float percentages; null output tokens → 0; enrich Auto model label.
jq '
  .context_window.used_percentage |= (if . == null then . else floor end)
  | .context_window.remaining_percentage |= (if . == null then . else floor end)
  | .context_window.total_output_tokens |= (if . == null then 0 else . end)
  | .model as $m
  | ($m.display_name // $m.id // "?") as $shown
  | ($m.id // "") as $id
  | (
      $m.resolved_display_name
      // $m.resolved_name
      // $m.actual_display_name
      // $m.actual_model
      // $m.routed_model
      // $m.underlying_model
      // ""
    ) as $resolved
  | .model.display_name = (
      if ($resolved != "") and (($resolved | ascii_downcase) != ($shown | ascii_downcase)) then
        "\($shown)→\($resolved)"
      elif (($shown | ascii_downcase) == "auto")
           and ($id != "")
           and (($id | ascii_downcase) != "auto") then
        "Auto (\($id))"
      else
        $shown
      end
      | if ($m.param_summary // "") != "" then . + " \($m.param_summary)" else . end
      | if $m.max_mode == true then . + " · max" else . end
    )
' | oh-my-posh claude --config "$CONFIG"
