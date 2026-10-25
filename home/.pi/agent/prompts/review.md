---
description: Get a fresh read-only pstack review of local changes
argument-hint: "[focus]"
---
Independently review staged and unstaged local changes.
Focus: ${@:-correctness, security, regressions, and missing tests}.

This command authorizes a fresh pstack reviewer. Neither parent nor reviewer may
edit repository files, stage, commit, push, or post/resolve review comments.
Keep existing work untouched and return findings, not fixes.

1. Read repository guidance and identify the exact task, branch/HEAD, and scope.
   Capture `git diff`, `git diff --cached`, relevant untracked files/deletions,
   and known test evidence in a private OS temporary patch packet outside the
   repository. Include a changed-file list and absolute source paths. Record the
   workspace snapshot so later changes cannot be presented as reviewed.
2. Read the managed user agent definition `~/.pi/agent/agents/pstack-reviewer.md`
   (under `PI_CODING_AGENT_DIR` if set). Require exactly the read/search tools
   `read`, `grep`, `find`, and `ls`, with no shell, mutation, network, or nested
   delegation tools. If missing or changed incompatibly, stop. This is a tool
   restriction, not an OS sandbox. Do not replace it with a writable Poteto agent.
3. Call pstack's `subagent` with `agent: "pstack-reviewer"`, `agentScope: "user"`,
   explicit current `cwd`, and a concrete `task` pointing to the packet, criteria,
   guidance, files, and actual validation results. Each call starts a fresh
   isolated process; do not fork or resume the implementation chat. Use an
   authenticated different model where available, otherwise disclose same-model
   context-isolated review. Do not invent model availability or desired verdicts.
4. Wait for the actual completed tool result. Reconcile findings with source.
   Report concrete P0/P1/P2 issues with file/line references, impact/evidence, and
   smallest fixes. Separate uncertainty and unrun checks from defects. If none
   qualify, say so and list gaps. Do not fix findings under this command.

Missing/failed delegation or workspace drift is a limitation, not a clean review.
Never silently substitute self-review. Delivery phases must bind review to the
exact patch/head and obtain a new fresh review after further source changes.
