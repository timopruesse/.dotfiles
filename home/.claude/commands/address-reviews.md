---
description: Work through unresolved review threads on your PR — apply code (gated), draft replies
argument-hint: "[pr number] (default: current branch's PR)"
---

Help me address the unresolved review comments on ONE pull request (`$ARGUMENTS`,
else the current branch's PR). Boundary: you may **apply code** to my branch after
I confirm, but you **never post, resolve, or dismiss** review threads — replies are
drafts I post myself.

## 1. Gather (read-only)

- Resolve the PR; pull its unresolved review threads (human reviewers and bots
  like CodeRabbit) via `gh api`/`gh pr view`. Read each thread in the context of
  the code it points at.

## 2. Classify each thread

- **Actionable code-change request** — a concrete "change X" the diff can satisfy.
- **Question / discussion / design pushback** — needs a human position, not a code
  edit.

## 3. Prepare (no writes yet)

- For each **code-change** thread: hand the change to `worker` (the reviewer's
  comment is the spec) in this branch's working tree; because it's addressing
  correctness feedback, run the result through the `verifier` gate. Draft a short
  reply for me (e.g. "Done in `<sha>` — <one line>").
- For each **question** thread: draft a *suggested* reply but flag it **needs your
  answer** — never invent a design position in my name.
- Present ONE preview: the proposed code diffs (grouped) + every drafted reply,
  each tagged to its thread. STOP for my `go`.

## 4. Apply (on my `go`)

- Apply + commit + push the approved code changes to my branch (like any fix —
  `worker` already did the edit; commit with a why-focused message).
- Leave the replies as drafts in my output — I post them. Do NOT post comments,
  do NOT resolve threads, do NOT approve/submit anything.

Report what was applied and what still needs my input. If `verifier` returns
BREAKS on a proposed change, don't push it — surface it with the failing input so
I decide, same as the babysitter's rule.
