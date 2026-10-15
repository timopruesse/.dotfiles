---
description: Get an independent read-only subagent review of local changes
argument-hint: "[focus]"
---
Independently review staged and unstaged local changes.
Focus: ${@:-correctness, security, regressions, and missing tests}.

This command authorizes delegation to a fresh `pi-subagents` reviewer. Neither the
parent nor reviewer may edit repository files, stage, commit, push, or post/resolve
review comments. Keep existing work untouched; return findings, not fixes.

Load the installed `workbench` skill. Create/reuse a contract for this exact
review scope in its private machine-local directory; no repository edits.
Prepare the native reviewer handoff using `workbench`, keeping the complete
report out of parent context with `outputMode: "file-only"`. Native runtime
output persistence does not grant the reviewer file-write tools. Record actual
terminal receipt, bounded findings/blocker summary, and exact reviewed patch
scope. Read relevant artifact sections before concluding; missing coverage is
not clean. Missing workbench/native delegation is a blocker, not a fallback.

1. Read repository guidance and identify the repo/branch and exact review scope.
   Gather both `git diff` and `git diff --cached`, including relevant untracked
   source files and deletions. The parent may save a patch/context packet in a
   private OS temporary directory, not the repo. Capture the reviewed workspace
   state so later changes can be reported rather than presented as reviewed.
2. Load the installed `pi-subagents` guidance. Activate `subagents_enable` if
   needed, then inspect `subagent({ action: "get", agent: "reviewer",
   options: { agentScope: "user" } })`. Require a local native Pi reviewer with
   read-only tools: `read`, `grep`, `find`, `ls`, `watchdog_diff`, and native
   `contact_supervisor` are allowed. No shell, edit/write, network/MCP, nested
   delegation, or external runner. If the resolved role violates this boundary,
   stop and report it; do not weaken restrictions or claim an independent review.
3. Launch `agent: "reviewer"` with explicit current `cwd`, `worktree: false`,
   `async: true`, and `options: { agentScope: "user", context: "fresh" }`.
   Supply the task/criteria, patch packet paths, changed-file list, relevant
   guidance, and known validation results. Do not fork the implementation chat
   or prime the child with a desired verdict. Explicitly prohibit edits, progress
   files, delivery actions, and posting. Use no retained/resumed child for a fresh
   review. The reviewer may inspect working diffs with `watchdog_diff`; committed
   ranges require a parent-supplied patch, not a claim that the tool read them.
4. Wait for the actual completed review using native package notifications.
   Reconcile findings with the code: report concrete current P0/P1/P2 issues with
   file/line references, impact/evidence, and smallest recommended fixes. Separate
   uncertainty and unrun tests from confirmed defects. If none qualify, say so
   and list remaining validation gaps. Do not fix findings in this command.

If delegation fails or the workspace changes during review, report that limitation
and exact run state. Never silently substitute a parent self-review. When invoked
as a delivery phase, the parent must bind this independent review to the exact
patch/head being considered, re-reviewing after further changes.
