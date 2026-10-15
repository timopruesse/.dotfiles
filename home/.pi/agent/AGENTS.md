# Personal coding workflow

Use Pi's native tools, sessions, skills, and prompt templates. Keep the default
system prompt. Work directly by default; use the installed `pi-subagents` package
when delegation is requested. `/dispatch`, `/ship`, `/babysit-pr`, and `/review`
explicitly authorize their documented worker/reviewer phases. Use package-native
guidance and builtin roles, not a custom specialist roster or model-tier router.
If required delegation is unavailable, report the blocker rather than silently
switching execution modes or claiming independent checks that did not run.

- Read applicable repository instructions before editing.
- Prefer small, focused changes; preserve unrelated working-tree edits.
- Investigate before changing code. For substantial work, give a short plan.
- Validate behavior with focused tests and inspect the final diff. Report what
  actually ran, what passed, and anything not verified.
- Never commit, push, open a PR, merge, or modify external systems without user
  intent. `/ship` authorizes its scoped delivery and safe merge. `/babysit-pr`
  authorizes its scoped fixes/pushes and verified-fix replies/thread resolution;
  merging additionally requires `--merge` or explicit invocation authorization.
  `/dispatch` implements/validates only; `/review` reports only. Jira references
  are read-only. Stage only relevant changes and use conventional commit messages.
- Keep worker delivery authority with the parent. Reviewers are fresh, independent,
  read-only children; inspect their resolved tools and bind review to the patch
  being delivered. Preserve unrelated edits/index content. No automatic branch or
  worktree scaffolding. Monitoring stops after 60 minutes or 3 repair rounds.
- Use `pi-workbench`'s workbench skill for authorized multi-step delegation:
  persistent verification criteria, artifact-first native handoffs, bounded
  summaries, and explicit blockers. Parent-recorded assessments are not proof;
  revalidate exact patch/checks before delivery. No new delegation authority.
- Use Herdr only for explicit terminal-management requests, including workbench
  status publication and owner navigation, not as a substitute for a subagent
  runtime. Pi model selection is independent of repository identity.
- Keep secrets and machine-local credentials out of dotfiles and session exports.
- Be concise. Show file paths clearly when discussing changes.
