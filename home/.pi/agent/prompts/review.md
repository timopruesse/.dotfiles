---
description: Get a fresh read-only hc reviewer pass over local changes
argument-hint: "[focus]"
---
Independently review staged and unstaged local changes.
Focus: ${@:-correctness, security, regressions, and missing tests}.

This command authorizes one fresh read-only reviewer child through herdr-core
(`hc`). Neither parent nor reviewer may edit repository files, stage, commit,
push, or post/resolve review comments.
Keep existing work untouched and return findings, not fixes.

1. Read repository guidance and identify the exact task, branch/HEAD, and scope.
   Capture `git diff`, `git diff --cached`, relevant untracked files/deletions,
   and known test evidence in a private OS temporary patch packet outside the
   repository. Include a changed-file list and absolute source paths. Record the
   workspace snapshot so later changes cannot be presented as reviewed.
2. Check `hc templates` for the managed `reviewer` template
   (`~/.config/herdr-core/templates/reviewer.md`). Its command must run Pi with
   exactly `--tools read,grep,find,ls`: no shell, mutation, network, or nested
   delegation tools. If missing or changed incompatibly, stop. This is a tool
   restriction, not an OS sandbox. Do not replace it with the `worker` template.
3. Start one fresh child: `hc run --bg --name review --cwd "<current cwd>"
   reviewer "<task>"`, where the task points to the packet, criteria, guidance,
   files, and actual validation results and asks for a report with `hc send`.
   Check `first_message.sent`. Each launch is a fresh isolated process; do not
   fork or resume the implementation chat. Use an authenticated different model
   where available (`--model` in a copy of the template), otherwise disclose
   same-model context-isolated review. Do not invent model availability or
   desired verdicts.
4. Wait with `hc wait review`, read the report and `hc read review`, then
   `hc kill review` and `hc rm review`. Reconcile findings with source.
   Report concrete P0/P1/P2 issues with file/line references, impact/evidence, and
   smallest fixes. Separate uncertainty and unrun checks from defects. If none
   qualify, say so and list gaps. Do not fix findings under this command.

Missing/failed delegation or workspace drift is a limitation, not a clean review.
Never silently substitute self-review. Delivery phases must bind review to the
exact patch/head and obtain a new fresh review after further source changes.
