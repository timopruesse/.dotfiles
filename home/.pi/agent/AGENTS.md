# Personal coding workflow

Use Pi's native tools, sessions, skills, and prompt templates. Keep the default
system prompt. The coding workflow is full Poteto Mode from `pi-pstack`.
Before coding or a multi-step task, read the installed `poteto-mode` skill in
full and follow its matching playbook, principles, and `pstack_todo` checklist.
This is the default unless the user disables Poteto Mode for the session.
`/poteto-mode [task]` enables the extension's sticky session reminder;
`/poteto-mode off` opts out. Do not re-enable it after an explicit opt-out.

Use pstack's `subagent` tool and bundled `poteto-agent` for implementation and
helpers, with package-native model roles and fresh isolated child processes.
Poteto's playbooks authorize relevant local delegation for the user's task.
`/dispatch`, `/ship`, `/babysit-pr`, and `/review` also authorize their documented
worker/reviewer phases. No pi-subagents, workbench handoffs, Herdr pane workers,
or alternative runtime fallbacks. If required delegation is unavailable, report
the blocker rather than claiming checks that did not run.

- Read applicable repository instructions before editing.
- Prefer small, focused changes; preserve unrelated working-tree/index edits.
- Investigate before changing code. For substantial work, give a short plan.
- Validate real behavior with focused tests and inspect the final diff. Report
  what actually ran, what passed, and anything not verified.
- Never commit, push, open a PR, merge, or modify external systems without user
  intent. `/ship` authorizes its scoped delivery and safe merge. `/babysit-pr`
  authorizes scoped fixes/pushes and verified-fix replies/thread resolution;
  merging additionally requires `--merge` or explicit invocation authorization.
  `/dispatch` implements/validates only; `/review` reports only. Jira is read-only.
  Stage only relevant changes and use conventional commit messages.
- Standing authorization permits the parent to make ordinary non-forced pushes
  of the current task branch to its configured remote without asking again.
  This does not authorize automatic commits, pushes by headless children, or
  unrelated external actions. Use a standalone `git push`, `git push REMOTE`,
  or `git push REMOTE BRANCH`; `-u` or `--set-upstream` is allowed only immediately
  after `push`, with both REMOTE and BRANCH. REMOTE matches
  `[a-zA-Z0-9][a-zA-Z0-9._-]*`; BRANCH matches
  `[a-zA-Z0-9][a-zA-Z0-9._/-]*`. Use spaces only, with no newlines, control
  characters, wrappers, shell operators, substitutions, URLs, or other options.
  Colon and `+` refspecs are not exempt. Other guarded actions still confirm.
- Keep delivery authority with the parent. Reviewers are fresh, independent,
  read-only children bound to the exact patch. Use the managed `pstack-reviewer`
  role with `agentScope: "user"`; implementation uses bundled scope. Reviewers
  receive a parent-prepared patch packet and have no shell or mutation tools.
  Tool restrictions are not an OS sandbox. Never claim model diversity unless
  a different authenticated model was actually used.
- Keep one writer per checkout. No automatic branch/worktree scaffolding.
  Monitoring stops after 60 minutes or 3 repair rounds. Local command-specific
  limits override broader upstream playbook suggestions. The pstack external
  action guard stays enabled. Only the interactive ordinary-push exception above
  skips confirmation; workflow grants do not bypass other confirmations.
- Use Herdr only for explicit terminal-management requests, not as a subagent
  runtime. Pi model selection is independent of repository identity.
- Keep secrets and machine-local credentials out of dotfiles and session exports.
- Be concise. Show file paths clearly when discussing changes.
