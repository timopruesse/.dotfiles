---
description: Work through unresolved review threads on your PR — apply code (gated), reply + resolve applied threads
argument-hint: "[pr number] (default: current branch's PR)"
---

Help me address the unresolved review comments on ONE pull request (`$ARGUMENTS`,
else the current branch's PR). Boundary: after I confirm, you may **apply code**
to my branch and — **only for a thread whose fix you actually applied and pushed**
— post an acknowledgement reply and resolve that thread. Anything needing my
position (questions, design pushback, or a fix I didn't apply) stays a **draft I
post myself**; never invent a stance in my name or resolve a thread I didn't act
on.

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
  correctness feedback, run the result through the `verifier` gate. Prepare a
  short acknowledgement reply (e.g. "Done in `<sha>` — <one line>") that I'll
  **post and resolve** on apply.
- For each **question** thread: draft a *suggested* reply but flag it **needs your
  answer** — never invent a design position in my name. These stay drafts.
- Present ONE preview: the proposed code diffs (grouped) + every reply, each
  tagged to its thread and marked whether it'll be **posted + resolved** (applied
  code-change) or left a **draft** (question). STOP for my `go`.

## 4. Apply (on my `go`)

- Apply + commit + push the approved code changes to my branch (like any fix —
  `worker` already did the edit; commit with a why-focused message).
- For each **code-change** thread whose fix actually landed (pushed; `verifier`
  did not return `BREAKS`), post its acknowledgement reply to that thread and
  resolve it. Post + resolve only on the applied fix — a fix I skipped or one the
  `verifier` broke leaves its thread untouched.
- For **question** threads, leave the reply as a draft in my output — I post
  those. Do NOT approve/submit a review, and never resolve a thread you didn't
  apply a fix for.

Report what was applied and what still needs my input. If `verifier` returns
BREAKS on a proposed change, don't push it — surface it with the failing input so
I decide, same as the babysitter's rule.
