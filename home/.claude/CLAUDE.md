# Subagent model routing

> A visual flow graph of these commands + agents is in
> [`WORKFLOWS.md`](../../WORKFLOWS.md).

Eight user-scoped agents live in the `.dotfiles` repo
(`home/.claude/agents/`) and are symlinked into `~/.claude/`. `scout`, `sweep`,
`worker`, `pr-babysitter`, `pr-reviewer`, and `boba-watcher` are pinned to
Sonnet 5; `committer` is pinned to Haiku (routine plumbing); `verifier` is pinned
to Opus (adversarial reasoning — see below).

- **`scout`** — read-only exploration, two modes. LOCATE (default): pinpoint
  "where/how does X work" via excerpts + `file:line`. EXPLAIN: read a subsystem
  in full and return an architecture/data-flow walkthrough to understand a
  codebase. Say "explain" in the prompt for the second mode. Prefer it over the
  built-in `Explore`/`general-purpose` agents for pure retrieval/understanding,
  since those inherit Opus.
- **`sweep`** — mechanical fix loops (tsc/type errors, lint, formatting).
- **`worker`** — implementer for small, clearly-specified coding changes. Use
  over the Opus `general-purpose` agent only when the spec is concrete and
  low-ambiguity; route anything needing design judgment to Opus. **After `worker`
  reports a behavior-changing change, gate it through `verifier`** (orchestrator
  step — spawn `verifier` yourself; feed any `BREAKS` input back to `worker`,
  escalate design-level failures to Opus). Skip the gate for no-runtime-surface
  or mechanical changes.
- **`committer`** — routine git plumbing (staging, commit messages, commit,
  push). Delegate the mechanical "commit this" / "commit and push" step to it
  once the work is done, instead of spending Opus on it.
- **`verifier`** (Opus) — composable adversarial verifier. Tries to BREAK a
  change by driving its real behavior, returns `VERDICT: HOLDS/BREAKS/
  INCONCLUSIVE`. Not a diff review (that's `/code-review`) — an independent
  correctness gate other agents call. Risk-gate before spawning: skip
  no-runtime-surface (docs/config) and mechanical/compiler-validated changes; fire
  on behavior-changing code (a green test run does NOT excuse it). Used by the
  `worker` gate above and self-spawned by `pr-babysitter` after a code fix.
- **`pr-babysitter`** — shepherds one PR toward mergeable in stateless one-sweep
  runs: auto-fixes+pushes CI/lint/type failures, clean rebases, and stale PR
  bodies; self-spawns `verifier` on its own code fixes; surfaces human review
  comments and real conflicts instead of acting on them. Each sweep reports a
  `STATUS: DONE/WORKING/WAITING` line. Invoke via `/babysit-pr [pr]` (self-loops,
  no `/loop` wrapper) or `/babysit-fleet` (all your open PRs on one loop). Route
  hard debugging it flags to Opus.
- **`pr-reviewer`** — draft-only reviewer for a single PR (read-only toward
  GitHub; never posts). Reads the diff/intent, reviews adversarially, spawns
  `verifier` for risky logic, returns a draft review + suggested verdict. Fanned
  out one-per-PR by `/review-requests`.
- **`boba-watcher`** — read-only classifier for one Boba-dispatched Jira ticket.
  A stateless sweep reads the ticket's comments, identifies Boba Fetch's latest
  signal **by its comment signature** (the `boba-fetch.vercel.app/dashboard/runs/`
  Run ID link — Boba posts under the user's own account, so author can't
  disambiguate), and reports `STATUS: DONE` (+PR URL) / `WORKING` / `BLOCKED`
  (+reason) / `WAITING`. It never touches the ticket; the `/watch-boba` command
  orchestrates the reactions. Driven on a loop by `/watch-boba`.

Reserve Opus for reasoning-heavy subagent work: planning/architecture (the
built-in `Plan` agent), adversarial verification (`verifier`), and hard debugging.
When a task genuinely needs Opus but no pinned agent fits, pass `model: "opus"` on
the spawn.

## Commands (`home/.claude/commands/`)

Roughly the PR lifecycle, front to back:

- **`/open-work [board]`** — browse the **unassigned, startable** items in a
  board's active sprint (defaults to `ECW`) as a free-to-take pool that doesn't
  overlap `/my-work`. Gather fans to `scout` (raw JQL is token-fat); items are
  flagged ready/needs-you; I pick numbers (no bare `go`/`all`), and behind a
  plan-preview gate each is handed to `/dispatch`.
- **`/dispatch <JIRA-KEY> [boba|no-boba]`** — the shared ticket-intake mechanism
  behind `/my-work` and `/open-work` (and invocable directly). One deep seam: it
  detects whether the ticket's **project** is Boba-enabled (probed once per project
  by the caller and passed down, else self-detected), then branches — add the
  `boba` label for the pipeline, or `/start` + `worker` — and offers the opt-in
  `/watch-boba` and Jira transition. Executor, not gatekeeper: the calling command
  owns selection + the batch gate; `/dispatch` just dispatches the one key.
- **`/start <JIRA-KEY>`** — scaffold a ticket: self-prune stale worktrees, then
  create a fresh worktree at `~/worktrees/<repo>/<KEY>` + branch `<KEY>-<slug>`
  off `main`, load the ticket's AC as context, offer the opt-in Jira transition.
  Doesn't auto-implement; offers `worker` in the new worktree. (The non-Boba branch
  of `/dispatch`.)
- **`/watch-boba <JIRA-KEY>`** — self-looping watcher for a `boba`-labeled ticket
  (the Boba branch of dispatch). Each tick spawns `boba-watcher` to classify Boba
  Fetch's latest signal; on `DONE` it auto-hands the new PR to `/babysit-pr`, on
  `BLOCKED` it drafts a ticket update to unblock Boba behind a preview gate (Boba
  auto-re-analyzes on the update), on `WORKING` it reschedules, and stops on
  `WAITING`/repeated-bail. Offered opt-in by `/dispatch` after it labels a ticket.
- **`/open-pr [base]`** — open a ready-for-review PR from the current branch:
  why-focused title/body from the branch's commits+diff → preview → `go` opens it,
  Jira key linked. No pre-flight. Offers opt-in Jira transition + `/babysit-pr`.
- **`/babysit-pr [pr]`** — self-looping shepherd for one PR (or the current
  branch's PR).
- **`/babysit-fleet`** — single fleet loop fanning `pr-babysitter` over all your
  open PRs; one wakeup, stops when every PR is `DONE`/`WAITING`.
- **`/address-reviews [pr]`** — work through unresolved review threads on your PR:
  applies code (via `worker` + `verifier` gate) after a preview, drafts replies
  for you to post. Never posts/resolves threads. Single PR.
- **`/review-requests`** — draft-only fan-out of `pr-reviewer` over every PR
  awaiting your review. Never posts.
- **`/ship-digest [since]`** — retrospective: what you shipped (git + merged PRs
  + Jira), fanned to `scout`.
- **`/my-work`** — prospective hub: open PRs + review requests + assigned Jira,
  surfaced with one-word dispatch behind a plan-preview gate. Gather + judge +
  batch-gate here; ready tickets are handed to `/dispatch` (which owns the
  Boba-label vs `/start` + `worker` branch). Red PRs through `/babysit-pr`. Never
  auto-dispatches.

The three self-looping commands (`/babysit-pr`, `/babysit-fleet`, `/watch-boba`)
share one contract — the `STATUS:` vocabulary and the `ScheduleWakeup` cadence —
defined once in [`LOOP-PROTOCOL.md`](LOOP-PROTOCOL.md). Change the cadence or the
enum there, not in each command.
