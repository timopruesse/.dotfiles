---
description: Land the current branch's work — verifier gate, commit (committer), then advance to /open-pr or /babysit-pr
argument-hint: "[--yes to skip the commit preview]"
---

Land the work on the current branch: run the `verifier` gate, commit via
`committer`, and hand off toward a PR. This is the seam between `worker` (which
already made the edits) and `/open-pr` — the local counterpart to how
`/watch-boba` auto-hands a Boba ticket to `/babysit-pr`. It operates on the
**current branch/worktree**; it does NOT run `worker` (that already happened) and
does NOT open the PR itself (it advances into `/open-pr`). Mode (A default vs B
pre-authorized, set at `/dispatch`) is carried in session context — see
[`~/protocols/HANDOFF-PROTOCOL.md`](../protocols/HANDOFF-PROTOCOL.md) for the AUTO/STOP taxonomy this
command follows below.

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
  and the observed wrong behavior, and `HALT: <reason>` (a `verifier` BREAKS is a
  STOP always, per the protocol's taxonomy — B never overrides it). Offer to hand
  the failing case to a fresh `worker` as a new spec — but only on my `go`; never
  auto-retry, never loop unattended. One verifier attempt, then it's my call.
- On `HOLDS` (or a skipped gate), continue.

## 3. Commit (preview → mode-aware)

- If there are uncommitted changes, hand them to `committer` to stage only the
  intended changes (report, don't sweep up, unrelated working-tree cruft) and
  write ONE why-focused commit message in the repo's established style. A `worker`
  change is one scoped unit — don't split it.
- **Preview:** the verifier verdict (or why it was skipped), the proposed commit
  message, and the file list. Under mode A, show it and **STOP for `go`** — a hard
  gate; never commit without it. Under mode B, this gate is **AUTO** (per
  [`~/protocols/HANDOFF-PROTOCOL.md`](../protocols/HANDOFF-PROTOCOL.md)'s taxonomy) — show the same
  preview but commit without pausing. (`--yes` in `$ARGUMENTS` skips the pause
  under mode A too.)
- If §1 found the work already committed and the tree is clean, skip this step —
  there's nothing to commit; go straight to §4.

## 4. Push / PR handoff

Branch on whether a PR already exists (from §1) — this is a branch point, so name
the successor rather than writing a bare `ADVANCE`:

- **No PR yet** → commit locally only; do NOT push (that's `/open-pr`'s job — it
  does its own `git push -u origin HEAD`). `ADVANCE → /open-pr`.
- **PR already exists** → this is a follow-up commit onto an open PR, so **push**
  (`git push`) to feed the existing PR / its babysitter. `ADVANCE → /babysit-pr
  <number>`.

Under mode A, advancing runs the next step up to its own preview gate and waits
for `go` there; under mode B it runs through, auto-approving that step's AUTO
gates. Do not fire the Jira transition here — that's `/open-pr`'s (In Review)
step; landing isn't review-ready by itself. Report what you did honestly — the
verdict, what was committed/pushed, and the step advanced to. If `verifier`
returned BREAKS, or a commit/push failed, `HALT: <reason>` rather than proceeding.
