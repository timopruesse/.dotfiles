# Subagent model routing

Seven user-scoped agents live in the `.dotfiles` repo
(`home/.claude/agents/`) and are symlinked into `~/.claude/`. `scout`, `sweep`,
`worker`, `pr-babysitter`, and `pr-reviewer` are pinned to Sonnet 5; `committer`
is pinned to Haiku (routine plumbing); `verifier` is pinned to Opus (adversarial
reasoning — see below).

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

Reserve Opus for reasoning-heavy subagent work: planning/architecture (the
built-in `Plan` agent), adversarial verification (`verifier`), and hard debugging.
When a task genuinely needs Opus but no pinned agent fits, pass `model: "opus"` on
the spawn.

## Commands (`home/.claude/commands/`)

- **`/babysit-pr [pr]`** — self-looping shepherd for one PR (or the current
  branch's PR).
- **`/babysit-fleet`** — single fleet loop fanning `pr-babysitter` over all your
  open PRs; one wakeup, stops when every PR is `DONE`/`WAITING`.
- **`/review-requests`** — draft-only fan-out of `pr-reviewer` over every PR
  awaiting your review. Never posts.
- **`/ship-digest [since]`** — retrospective: what you shipped (git + merged PRs
  + Jira), fanned to `scout`.
- **`/my-work`** — prospective hub: open PRs + review requests + assigned Jira,
  surfaced with one-word dispatch into `worker`/`pr-babysitter`/`/review-requests`
  behind a plan-preview gate. Never auto-dispatches.
