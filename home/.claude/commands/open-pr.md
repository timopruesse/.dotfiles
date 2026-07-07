---
description: Open a ready-for-review PR from the current branch (why-focused body, Jira-linked)
argument-hint: "[base branch] (default: repo's default branch)"
---

Open a pull request from the current branch. Default flow: generate → preview →
open ready-for-review. NEVER open the PR before I confirm the preview — unless
mode B says otherwise (below).

Mode (A default vs B pre-authorized, set at `/dispatch`/`/land`) is carried in
session context — see [`HANDOFF-PROTOCOL.md`](../HANDOFF-PROTOCOL.md) for the
AUTO/STOP taxonomy this command follows. If no mode is set — e.g. you invoked
this standalone, not via a `/land` or `/dispatch` chain — there's nothing to
inherit, so it behaves as mode A.

## 1. Pre-flight (read-only)

- Determine the base branch: `$ARGUMENTS` if given, else the repo default
  (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`).
- Refuse (and say why) if: there are no commits on this branch vs base
  (`git log <base>..HEAD` empty), or the working tree has uncommitted changes
  (report them so I can commit/stash first — don't open a PR mid-edit).
- Extract the Jira key from the branch name (branches here always contain it,
  e.g. `ECW-1065-...`). Hold it for the title/body.

## 2. Generate the PR (no writes yet)

- Read the branch's commits (`git log <base>..HEAD`) and the diff
  (`git diff <base>...HEAD`) and write a **why-focused** title + body: what this
  change accomplishes and why, not a line-by-line restatement of the diff (same
  bar as a good commit message). Put the Jira key in the title matching my
  convention (`[KEY]` / `KEY:`) and reference it in the body so Mill's Jira↔GitHub
  integration auto-links it.
- Print the title + body as a single **preview block**. Under mode A, STOP for my
  `go`. Under mode B, this gate is **AUTO** (per
  [`HANDOFF-PROTOCOL.md`](../HANDOFF-PROTOCOL.md)'s taxonomy) — show the same
  preview but open without pausing, and open **ready-for-review** (the default for
  B, not draft). (`--yes`/`now` in `$ARGUMENTS` skips the pause under mode A too;
  `--draft` opens a draft PR regardless of mode — a manual override.)

## 3. Open

- Push the branch if it isn't pushed (`git push -u origin HEAD`), then
  `gh pr create --base <base> --title <title> --body <body>` (ready-for-review
  unless `--draft`). Report the PR URL.

## 4. Jira transition + shepherding handoff

- **Transition the Jira ticket** (In Progress → In Review, "PR opened") via the
  Atlassian MCP, per the protocol's Jira lifecycle mapping: **AUTO** under mode B
  (fire it without asking); under mode A, a one-line **offer** — only do it if I
  say yes; never silently.
- **Start shepherding**: `ADVANCE → /babysit-pr <number>` — launch the loop. Under
  mode A this runs up to its own next gate and waits; under mode B it runs
  through.

Do not run tests/lint/format here — that's CI and `/babysit-pr`'s job. Report the
final state honestly; if the push or `gh pr create` fails, `HALT: <reason>`
rather than proceeding.
