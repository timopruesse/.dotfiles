---
description: Open a ready-for-review PR from the current branch (why-focused body, Jira-linked)
argument-hint: "[base branch] (default: repo's default branch)"
---

Open a pull request from the current branch. Default flow: generate → preview →
open ready-for-review. NEVER open the PR before I confirm the preview.

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
- Print the title + body as a single **preview block** and STOP for my `go`.
  (`--yes`/`now` in `$ARGUMENTS` skips this preview; `--draft` opens a draft PR.)

## 3. Open (on my `go`)

- Push the branch if it isn't pushed (`git push -u origin HEAD`), then
  `gh pr create --base <base> --title <title> --body <body>` (ready-for-review
  unless `--draft`). Report the PR URL.

## 4. Two opt-in follow-ups (offer, don't do automatically)

- **Transition the Jira ticket** (e.g. To Do/In Progress → In Review) via the
  Atlassian MCP — offer it as one line; only do it if I say yes.
- **Start shepherding**: offer `/babysit-pr <number>`. Only start it if I say yes
  (or `--babysit` was passed) — never silently kick off the background loop.

Do not run tests/lint/format here — that's CI and `/babysit-pr`'s job. Report the
final state honestly; if the push or `gh pr create` fails, stop and show the error.
