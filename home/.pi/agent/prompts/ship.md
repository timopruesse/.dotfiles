---
description: Implement, independently review, publish, and safely merge work in the current checkout
argument-hint: "[task or existing-change scope]"
---
Ship this scoped work end-to-end: $@

Invoking `/ship` authorizes the parent to implement/validate, commit scoped
changes, push the current feature branch, create/update its PR, monitor it, and
merge when safe. No extra `--merge` flag is needed. Pstack's runtime confirmations
still apply to recognized external commands; never bypass the guard. This
is not authority to bypass checks/approvals, mutate Jira, discard unrelated work,
force-push, change branches, or create worktrees/ticket scaffolding.

Read the installed `poteto-mode` skill in full. Select the matching playbooks
and use `pstack_todo` across implementation, review, delivery, and monitoring.
Track criteria, actual checks/results, blockers, and exact assessed patch/head.
Reset affected checks after source changes. Todo completion never substitutes
for fresh validation or merge authorization. Local delivery limits below take
precedence over upstream suggestions to open PRs or change branches/worktrees.

## Establish scope and implementation

- Read repo guidance and inspect cwd, branch/HEAD, remotes/upstream, staged and
  unstaged changes, untracked files, and any existing PR. Establish an exact
  starting snapshot and explicit owned file/hunk scope. With no task arguments,
  ship existing changes only if the intended scope is clear; otherwise ask.
- Remain in the current checkout. Stop if detached, on the default/protected
  branch, targeting the wrong PR/repository, or unable to separate unrelated
  staged/working changes. Do not create a feature branch as a hidden fallback.
- Read the sibling `dispatch.md` template for native worker launch mechanics and
  `review.md` for independent-review mechanics. Follow them as phases of this
  command, not recursive slash invocations. The parent retains `/ship` delivery
  authority; children get implementation/review authority only.
- If implementation is needed, use one fresh local pstack `poteto-agent` in the
  current cwd with bundled scope and a concrete no-delivery brief. Do not
  bypass required delegation. Existing finished changes can proceed directly to
  validation/review; do not fabricate a worker task just for ceremony.

## Validate and independently review

1. Inspect the scoped patch and run relevant focused tests/checks in the parent.
   Missing/failed required checks are blockers, not passing evidence.
2. Launch a fresh, read-only `pstack-reviewer` using the sibling review instructions;
   provide the task, exact patch, changed files, and validation evidence. Wait
   for the completed result. No forked implementation chat or resumed reviewer.
3. Route actionable findings to a worker, then revalidate and obtain another
   fresh review. Allow at most **3 fix/review rounds after the initial review**.
   Stop for unresolved findings, ambiguous decisions, or delegation failure.
   Do not silently downgrade to self-review. Check index and unrelated-edit
   preservation after every worker. Children must not stage, commit, push, open
   PRs, merge, post replies, resolve threads, or write to Jira.

## Commit and publish — parent only

- Inspect the final diff and index. Stage only the reviewed scoped changes;
  never use blanket staging. Preserve unrelated staged content. If it cannot be
  safely separated without changing the user's index/work, stop and ask.
- Use a conventional commit message and normal repository hooks. Inspect the
  actual commit diff (hooks can change it); rerun checks/review if it differs
  materially from what was validated. Never amend another person's commit or
  disable hooks to make delivery pass.
- Push only the intended current feature branch to its verified remote. Use a
  normal push, never force. Check the existing PR for that exact head/base, or
  create a ready-for-review PR with a why-focused title/body and honest test/risk
  notes. Include a Jira reference only when supplied/verified; do not write Jira.
- Read sibling `babysit-pr.md` and execute its bounded monitoring/fix policy on
  this exact PR. `/ship` carries explicit merge authorization into this phase.
  Its 60-minute / 3-repair-round budget begins at PR monitoring, separately from
  the pre-delivery fix/review budget; never reset it on a follow-up tool call.

## Safe merge and final report

Follow the repo's documented merge policy; when no policy is documented, squash
only if allowed. Stop for unclear/conflicting policy or unavailable fallback.
Freshly verify the exact pushed/reviewed head, required checks and approvals,
unresolved review concerns, mergeability/base freshness, and repository rules.
Pending, stale, missing, or unknown evidence is not permission to merge. Never
bypass branch protections, use admin overrides, dismiss reviews, or resolve
unaddressed concerns. Use an exact-head merge guard (for example GitHub CLI's
`--match-head-commit`); if HEAD changes, revalidate/review rather than race it.
A queued/auto-merge request is not a completed merge; inspect authoritative state.

Report the branch/commit and PR URL, validation/review results, and actual merged,
open, queued, or blocked state. At a monitoring limit or blocker, include remaining
work and an exact resumption instruction; never claim unattended work continues
unless a real package-owned run is still active and identified. Do not delete
branches/worktrees or broaden the task as cleanup.
