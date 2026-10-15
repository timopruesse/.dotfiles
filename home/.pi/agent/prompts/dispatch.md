---
description: Delegate a local task to a worker in the current checkout, without delivery actions
argument-hint: "<task or Jira key>"
---
Implement this task locally: $@

Invoking `/dispatch` authorizes implementation and relevant validation, not
commits, pushes, PR creation, merges, or Jira writes. Work in the current checkout;
do not create or switch branches/worktrees, stash changes, or scaffold ticket files.

Load the installed `workbench` skill. Create a verification contract for this
scope (or reuse the same task's selected contract), with checkable criteria.
Use `workbench handoff` to prepare the native parameters below, keeping full
reports in its private artifact directory with `outputMode: "file-only"`.
Preparation is not launch/completion. Record native terminal receipts, concise
summaries and explicit blockers; parent validation separately assesses criteria
with evidence and exact patch/check scope. The package must be available; if
not, report the blocker. Workbench does not expand this command's authority.

1. Read applicable repository instructions and inspect the current path, branch,
   git status, staged changes, and existing diff. Identify unrelated work and
   overlapping edits. Preserve it; ask before touching ambiguous shared changes.
2. If the task is empty, unclear, blocked, or requires an unapproved decision,
   pause for the user. Otherwise start immediately, without a separate plan gate
   or `--auto` mode. A Jira key is optional: use available authorized Jira tools
   to read its description and acceptance criteria, never assign it, label it,
   or transition its status. If context cannot be retrieved, report that rather
   than inventing requirements or configuring credentials on the user's behalf.
3. Use `pi-subagents`' installed guidance and native `subagent` tool. If only
   `subagents_enable` is active, activate it first. Inspect the resolved `worker`
   in user scope; require a local native Pi child, not a project override or an
   external/machine runner. Delegate with `agent: "worker"`, explicit current
   `cwd`, `worktree: false`, `async: true`, and
   `options: { agentScope: "user", context: "fresh" }`.
4. Supply a concrete brief: objective/criteria, repo and branch, relevant files,
   existing-edit boundaries, expected tests, and stop conditions. The child may
   edit scoped files and run validation; it must not stage, commit, push, change
   branches/worktrees, mutate Jira/GitHub, spawn children, or create progress or
   ticket-scaffolding files. The native output report in workbench's private
   artifact directory is allowed; no repository progress files. If starting with staged content, use documented
   checked acceptance with `preserveStagedIndex: true`; never unstage the user's
   work to satisfy a gate. Keep one writer per checkout and wait for its actual
   completed result before validation. A launch receipt is not completion.
5. The parent inspects the delta against the starting snapshot, checks scope and
   index preservation, and runs appropriate focused validation. Report actual
   changed files, test results, remaining risks, and blockers. Do not silently
   advance into `/ship` or perform any delivery action.

Use package-native completion/supervisor handling, not Herdr panes or CLI
fallbacks. On delegation failure, report the exact error/run state and preserve
partial work; do not silently implement in the parent or switch execution modes.
