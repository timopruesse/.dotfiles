---
description: Delegate a local task to a Poteto worker without delivery actions
argument-hint: "<task or Jira key>"
---
Implement this task locally: $@

Invoking `/dispatch` authorizes implementation and relevant validation, not
commits, pushes, PR creation, merges, or Jira writes. Work in the current checkout;
do not create or switch branches/worktrees, stash changes, or scaffold ticket files.

1. Read applicable repository instructions and the installed `poteto-mode` skill
   in full. Select its matching playbook and track steps with `pstack_todo`.
   Inspect cwd, branch/HEAD, staged/unstaged changes, and untracked files. Capture
   the starting diff and index so unrelated edits can be verified afterward.
2. Start when scope is clear. Ask only for missing requirements, genuine product
   choices, or conflicting edits. A Jira key is optional and read-only; never
   assign, label, or transition tickets or invent unavailable ticket context.
3. Delegate with pstack's native `subagent` tool using `agent: "poteto-agent"`,
   `agentScope: "bundled"`, explicit current `cwd`, and a self-contained `task`.
   Use the matching configured pstack `role`; unconfigured roles inherit the
   parent model. Do not pass pi-subagents options such as `async`, `worktree`,
   `context`, `outputMode`, or `options`. Each child is already a fresh isolated
   local Pi process. Keep one writer per checkout.
4. Supply objective/criteria, branch, relevant files, unrelated-edit boundaries,
   expected tests, and stop conditions. The child may edit scoped files and test;
   explicitly prohibit staging, commits, pushes, branch/worktree changes, external
   writes, Jira/GitHub mutations, nested delegation, and repository progress files.
   Temporary evidence outside the checkout is allowed. Ask for changed files,
   checks/results, risks, and blockers in the final result.
5. Wait for the actual tool result, not a launch/status message. The parent
   compares the delta and index to the starting snapshot and runs focused checks.
   Record real results and blockers in `pstack_todo` and the final report. A todo
   item marked complete is not proof. Do not advance into delivery automatically.

On delegation failure, report the actual error and preserve partial work. Do not
silently implement in the parent, launch Herdr workers, or switch runtimes.
