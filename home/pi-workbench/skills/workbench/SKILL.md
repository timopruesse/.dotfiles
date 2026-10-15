---
name: workbench
description: Use verification contracts and thin-context native subagent handoffs for authorized multi-step implementation, review, or research. Never authorizes delegation or delivery by itself.
---
# Workbench

Keep the default Pi system prompt. Work directly unless the user or applicable
workflow authorizes delegation. This package is a ledger and handoff layer, not
a scheduler, subagent runtime, sandbox, or proof engine.

## Contract

1. For an authorized multi-step task, call `workbench` with `action: create`, a
   short title, and checkable `criteria`. Persist task ID and contract path.
   Do not create a new contract on every turn. On resume, inspect `status` and
   read the contract. `/workbench select <id>` attaches existing state to this
   session's branch; it does not transfer mutation authority from its owner.
2. Mutations require `taskId` and the latest `revision`. Re-read status on a
   revision conflict. `add` appends criteria with stable A1/A2 IDs; criteria are
   never deleted or silently rewritten. Scope changes need explicit new criteria.
3. `record` takes assertion ID, state (pending/passed/failed/blocked/waived), note,
   evidence file paths, and exact assessed patch/check `scope`. Passed assessments
   require existing evidence; waived assessments require an explicit reason and
   scope. Only waive when authorized; never use a waiver to bypass required checks.
4. Evidence hashes detect changed or missing evidence files, NOT changed source
   patches. A passing command or report may be insufficient. Parent must assess
   relevance, completeness, exact patch identity, and required approvals. If the
   assessed source changes, reset affected assertions to pending and revalidate.
5. `criteria-recorded-ready` means only that criteria were recorded passed/waived.
   Check handoff blockers too. It is NOT independently verified readiness,
   completion, merge permission, or authority to perform delivery actions.

## Thin-context handoffs

1. Use native pi-subagents guidance; inspect resolved user-scope builtin roles,
   tools, and native runner before launching. Keep one writer per checkout.
2. Call `handoff` with role and concrete objective. Include exact file/hunk scope,
   existing-edit boundaries, expected validation, and stop conditions. Reviewers
   must be fresh, read-only, and bound to the exact patch. Returned `subagent`
   parameters use fresh context, native async execution, `worktree: false`,
   explicit output path, and `outputMode: file-only`. Preparation launches nothing.
3. Pass these parameters to the native `subagent` tool only when authorized.
   Keep native completion, status, cancellation, budgets, and supervisor handling.
   Add staged-index preservation/acceptance options required by the parent workflow.
   Never replace failed delegation with a shell/Herdr child or parent implementation.
4. Full worker/research/reviewer reports stay on disk. The native output binding
   saves read-only reviewer output without granting the reviewer write tools.
   Children report blockers to the supervisor immediately; failure output remains
   visible through native pi-subagents. Do not intercept/truncate failure results.
5. Wait for the actual terminal result. A run ID, prepared brief, file's existence,
   or idle badge is not completion. Read relevant report sections and check the
   native status. Record `receipt` with handoff ID, native run ID, completed/failed/
   blocked state, <=1500-character summary, and explicit blockers (empty only if
   none). This is parent-attested bookkeeping, not runtime attestation.
6. Reports include changed files, real checks/results, risks, and source/evidence
   references. Read more when findings, decisions, or uncertainty require it;
   never infer correctness from a short summary. Contract assessments remain a
   separate parent decision. Status shows the latest four handoffs and explicitly
   counts omissions; all attention handoff IDs remain visible in status.

## Herdr: visibility only

- `/workbench herdr` explicitly publishes a display-only `$workbench` token on
  the owner's pane for 60 seconds. Refresh explicitly as needed; no timers,
  processes, panes, lifecycle states, or background control are installed.
- `/workbench herdr clear` clears only this session's custom tokens.
- `/workbench focus [task-id]` or the package CLI `focus <task-id>` navigates to
  the owner only after validating its current Pi session, host, and socket.
  Requires running inside Herdr; stale/reused pane IDs fail closed.
- `/workbench` shows counts, blockers, contract path, and artifact directory.
  `node <package>/cli.mjs list|status <id>` provides read-only terminal inspection.
- Official Herdr Pi integration and pi-subagents own lifecycle/child state.
  Do not use this package to spawn terminal workers or infer live run state.

Keep credentials, raw prompts, and sensitive command output out of public
metadata and session exports. Task artifacts are private machine-local files,
not committed progress scaffolding; curate evidence rather than copying secrets.
