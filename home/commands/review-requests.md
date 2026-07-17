---
description: Draft reviews for all PRs awaiting your review (fan-out, never posts)
argument-hint: "[optional gh search qualifiers, e.g. org:chewielabs]"
tier: mid
---

Draft a review for every open pull request where my review is requested. This is
DRAFT-ONLY: nothing is posted, submitted, approved, or commented — you produce
drafts for me to act on.

1. Find the PRs: `gh search prs --review-requested=@me --state=open $ARGUMENTS`
   (include both my personal and Mill/work contexts unless `$ARGUMENTS` narrows
   it). **Exclude PRs in archived repos** — their open PRs are dead and will
   never merge, so reviewing them is wasted effort. Add `archived:false` to the
   search, or verify each result's repo with
   `gh repo view <repo> --json isArchived` and drop the archived ones (e.g.
   `chewielabs/ChewieWebApi` is archived). If nothing remains after filtering,
   say so and stop.
2. Fan out: spawn one `pr-reviewer` agent PER PR, in parallel (a single message
   with multiple Agent calls), each given that PR's number/URL. Isolated context
   per PR so a huge diff on one doesn't pollute another.
3. Collect the drafts and present them to me grouped by PR: for each, the
   `pr-reviewer`'s summary, its must-fix vs nits, and its suggested verdict —
   clearly marked as drafts I still need to post.

Do not post anything. If I want to post one, I'll tell you and you can help me do
it then. Report honestly if any PR was too large or lacked context to review
well — don't pad a thin review to look complete.
