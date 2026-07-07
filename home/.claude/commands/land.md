---
description: Land the current branch's work — verifier gate, commit (committer), then offer /open-pr
argument-hint: "[--yes to skip the commit preview]"
---

Land the work on the current branch: run the `verifier` gate, commit via
`committer`, and hand off toward a PR. This is the seam between `worker` (which
already made the edits) and `/open-pr` — the local counterpart to how
`/watch-boba` auto-hands a Boba ticket to `/babysit-pr`. It operates on the
**current branch/worktree**; it does NOT run `worker` (that already happened) and
does NOT open the PR itself (it offers `/open-pr`).

## 1. Pre-flight (read-only)

- Resolve the current branch and repo. **Refuse** (and say why) if you're on the
  repo's default branch — there's nothing to land onto a PR from `main`.
- Determine the base branch (repo default via
  `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`).
- Gather the state that defines "the work":
  - uncommitted changes (`git status --porcelain`, `git diff` staged + unstaged), and
  - committed-but-unpushed commits (`git log <base>..HEAD`, and whether an upstream
    exists / is ahead).
- **Refuse with "nothing to land"** only if the tree is clean AND there's nothing
  unpushed vs base. Some `worker` runs arrive already-committed — that's fine,
  it's still landable (skip the commit step in §3).
- Check whether a PR already exists for the branch (`gh pr view --json number,url`);
  hold the answer — it decides §4.

## 2. Verify — the gate (behavior-changing changes only)

- Look at the **branch diff vs base** (`git diff <base>...HEAD` plus any uncommitted
  changes) and apply the risk-gate yourself: **skip `verifier`** for no-runtime-surface
  diffs (docs, comments, formatting, config/lockfile bumps) and mechanical/
  compiler-validated edits (types, lint, pure renames). **Spawn `verifier`** when
  there's real runtime surface, giving it the specific behavior the change is meant
  to produce and letting it try to break it.
- **On `VERDICT: BREAKS`** — do NOT commit. Surface the verifier's failing input
  and the observed wrong behavior, and STOP for me (same posture as
  `/address-reviews` and the babysitter). Offer to hand the failing case to a fresh
  `worker` as a new spec — but only on my `go`; never auto-retry, never loop
  unattended. One verifier attempt, then it's my call.
- On `HOLDS` (or a skipped gate), continue.

## 3. Commit (preview → my `go`)

- If there are uncommitted changes, hand them to `committer` to stage only the
  intended changes (report, don't sweep up, unrelated working-tree cruft) and
  write ONE why-focused commit message in the repo's established style. A `worker`
  change is one scoped unit — don't split it.
- **Show me one preview and STOP for `go`:** the verifier verdict (or why it was
  skipped), the proposed commit message, and the file list. This is a hard gate —
  never commit without my `go`. (`--yes` in `$ARGUMENTS` skips this preview.)
- If §1 found the work already committed and the tree is clean, skip this step —
  there's nothing to commit; go straight to §4.

## 4. Push / PR handoff (on my `go`)

Branch on whether a PR already exists (from §1):

- **No PR yet** → commit locally only; do NOT push (that's `/open-pr`'s job — it
  does its own `git push -u origin HEAD`). Then **offer** `/open-pr` as one line —
  only run it if I say yes.
- **PR already exists** → this is a follow-up commit onto an open PR, so **push**
  (`git push`) to feed the existing PR / its babysitter. Then **offer**
  `/babysit-pr <number>` rather than `/open-pr`.

Do not offer or perform the Jira transition here — that's `/open-pr`'s (In Review)
step; landing isn't review-ready by itself. Report what you did honestly — the
verdict, what was committed/pushed, and the follow-up on offer. If `verifier`
returned BREAKS, or a commit/push failed, stop and show it rather than proceeding.
