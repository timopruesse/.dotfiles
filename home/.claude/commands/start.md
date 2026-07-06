---
description: Scaffold a Jira ticket — fresh worktree + branch off main, ticket context loaded
argument-hint: "<JIRA-KEY> (e.g. ECW-1060)"
---

Start work on the Jira ticket `$ARGUMENTS` by scaffolding an isolated worktree and
branch. Do NOT auto-implement — scaffold, orient, and hand off on my say-so.

## 1. Self-prune stale worktrees first (safe)

- Determine the repo name: `basename $(git rev-parse --show-toplevel)`, then
  `git fetch --prune` so deleted remote branches are reflected locally.
- Look under `~/worktrees/<repo>/`. For each existing worktree there, remove it
  (`git worktree remove` + `git worktree prune`) ONLY if its branch's upstream is
  **gone** — i.e. it was pushed and its remote branch has since been deleted (the
  PR merged). Detect this precisely: the branch has a configured upstream AND that
  upstream no longer exists (`git -C <wt> status -sb` shows `[gone]`).
  - Do NOT use "merged into the default branch" as the signal — a freshly created
    branch with no commits is trivially an ancestor of `main` and would be falsely
    pruned, destroying a worktree you just scaffolded. Upstream-gone is the only
    safe "this work actually landed" signal.
  - KEEP anything with no upstream at all (never pushed → new/local work) or a
    live upstream (in progress).
  - **Never remove a worktree with uncommitted changes** — report it and skip,
    even if its upstream is gone. Say what you cleaned and what you skipped.

## 2. Fetch the ticket

- Via the Atlassian MCP, get `$ARGUMENTS`: summary, description/acceptance
  criteria, status. If Atlassian is unavailable, say so and continue with just the
  key (still scaffold the worktree).

## 3. Create the worktree + branch

- `git fetch` the default remote. Determine the default branch
  (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`).
- Create a worktree at `~/worktrees/<repo>/<KEY>` on a new branch
  `<KEY>-<short-slug>` (slug derived from the ticket summary, lowercase-kebab)
  based off `origin/<default>`:
  `git worktree add ~/worktrees/<repo>/<KEY> -b <KEY>-<slug> origin/<default>`.
- Report the worktree path and branch. This is where work for this ticket lives —
  parallel Claude sessions on other tickets won't collide with it.

## 4. Orient + hand off

- Print the ticket summary + acceptance criteria as working context.
- **Offer** the opt-in Jira transition (To Do → In Progress) — only do it if I say
  yes; never silently.
- **Offer** to hand the ticket to `worker` (running in the new worktree, with the
  ticket AC as the spec). Do not start implementation unless I say go.

If the worktree already exists for this key, don't recreate it — just report its
path and orient. Report failures (fetch, worktree add) with the error rather than
proceeding blindly.
