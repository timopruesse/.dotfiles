#!/usr/bin/env bash
# Cursor Agent CLI status line (stdin: StatusLinePayload JSON).
# Shows the selected model; when picker is Auto, prefers any resolved/routed
# model fields Cursor may send. Today those are often absent — then we show
# "Auto" (and model.id only if it differs from Auto).
set -euo pipefail

input=$(cat)

model=$(printf '%s' "$input" | jq -r '
  .model as $m
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
  | (
      if ($resolved != "") and (($resolved | ascii_downcase) != ($shown | ascii_downcase)) then
        "\($shown)→\($resolved)"
      elif (($shown | ascii_downcase) == "auto")
           and ($id != "")
           and (($id | ascii_downcase) != "auto") then
        "Auto (\($id))"
      else
        $shown
      end
    )
  | if ($m.param_summary // "") != "" then . + " \($m.param_summary)" else . end
  | if $m.max_mode == true then . + " · max" else . end
')

pct=$(printf '%s' "$input" | jq -r '
  .context_window.used_percentage // ""
  | if . == "" then "" else (tonumber | floor | tostring) end
')

dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
base="${dir##*/}"
[ -z "$base" ] && base="?"

wt=$(printf '%s' "$input" | jq -r '.worktree.name // empty')

parts=("$model")
[ -n "$pct" ] && parts+=("ctx ${pct}%")
parts+=("$base")
[ -n "$wt" ] && parts+=("wt:$wt")

out=$(IFS=' · '; echo "${parts[*]}")
printf '\033[90m%s\033[0m\n' "$out"
