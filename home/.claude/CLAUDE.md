# Subagent model routing

Four user-scoped agents handle cheap work (`~/.claude/agents/`): `scout`,
`sweep`, and `worker` are pinned to Sonnet 5; `committer` is pinned to Haiku
(routine plumbing that doesn't need Sonnet-level reasoning). They live in the
`.dotfiles` repo (`home/.claude/agents/`) and are symlinked into `~/.claude/`.

- **`scout`** — read-only search/exploration and fan-out lookups. Prefer it over
  the built-in `Explore`/`general-purpose` agents when the task is pure
  retrieval or "where/how does X work", since those built-ins inherit the main
  model (Opus).
- **`sweep`** — mechanical fix loops (tsc/type errors, lint, formatting).
- **`worker`** — implementer for small, clearly-specified coding changes. Use
  over the Opus `general-purpose` agent only when the spec is concrete and
  low-ambiguity; route anything needing design judgment to Opus.
- **`committer`** — routine git plumbing (staging, commit messages, commit,
  push). Delegate the mechanical "commit this" / "commit and push" step to it
  once the work is done, instead of spending Opus on it.

Reserve Opus for reasoning-heavy subagent work: planning/architecture (the
built-in `Plan` agent), adversarial verification, and hard debugging. When a task
genuinely needs Opus but no pinned agent fits, pass `model: "opus"` on the spawn.
