# Workflow migration decisions

Review the former commands and skills one at a time with the user. Do not restore
behavior or enable unattended writes merely because it existed before. Record
keep/drop/replace decisions here, then implement only approved migrations.

Original sources are in Git at `9abf70b6832e5c62f9c9a18b65d9d74e0b0b2952`:

```sh
git show 9abf70b6832e5c62f9c9a18b65d9d74e0b0b2952:home/commands/dispatch.md
```

## Command decisions

| Command | Former purpose | Decision |
| --- | --- | --- |
| `/dispatch` | Start one Jira ticket: route to Boba or local worktree/implementation. | Keep/migrate local implementation in the current checkout; no Boba or automatic ticket/worktree scaffolding |
| `/start` | Create a fresh worktree/branch and load ticket context. | Drop; remove ticket/worktree scaffolding entirely |
| `/ship` | Pre-authorized end-to-end ticket delivery, including PR shepherding. | Keep/migrate end-to-end automation in the current checkout; no automatic ticket/worktree scaffolding |
| `/watch-boba` | Watch a Boba ticket for a PR and handle blockers. | Drop; no Boba watcher migration |
| `/land` | Verify, commit, then advance to PR creation/shepherding. | Drop; remove the initial Pi template too. Use natural-language requests or `/ship` |
| `/open-pr` | Draft and open a ready-for-review, Jira-linked PR. | Drop the standalone command; use natural-language requests. `/ship` retains its approved PR-creation step |
| `/babysit-pr` | Monitor one PR's CI, base drift, review threads, and merge readiness. | Keep/migrate full monitoring and fixes; merging requires explicit authorization at invocation |
| `/babysit-fleet` | Monitor all authored open PRs in a shared loop. | Drop; use `/babysit-pr` for selected PRs |
| `/address-reviews` | Apply review feedback, acknowledge fixes, resolve threads. | Drop the standalone command; use natural-language requests. `/babysit-pr` retains its approved review-feedback handling |
| `/review-requests` | Draft reviews for requested PRs; never post automatically. | Drop; request reviews in natural language |
| `/triage-security` | Classify security/Bugbot findings on authored PRs. | Drop; request security triage in natural language |
| `/my-work` | Dashboard of PRs, reviews, and assigned Jira work, with gated dispatch. | Drop; ask what needs attention in natural language |
| `/open-work` | Browse unassigned, startable active-sprint tickets. | Drop; ask about available work in natural language |
| `/ship-digest` | Summarize shipped work from Git, merged PRs, and Jira. | Drop; request a shipped-work summary in natural language |
| `/session-cost` | Cross-client cost/duration and routing-audit rollup. | Drop; use native Pi `/session` |
| `/wrap-up` | Validate current branch and advance to PR creation. | Drop, including the initial Pi continuation-summary template; request handoff summaries in natural language |

## Templates added during Pi setup

| Template | Purpose | Decision |
| --- | --- | --- |
| `/plan` | Investigate and propose an implementation plan without editing files. | Keep as a reusable planning prompt |
| `/review` | Review local staged and unstaged changes without editing. | Keep/migrate to an independent `pi-subagents` reviewer; enforce read-only findings, not the reviewer's optional fixes |

The initial Pi `/land` and `/wrap-up` templates have been removed following the
user's decisions.

## `/ship` decision

**Keep end-to-end automation**, adapted to Pi and the current checkout (user
selected option 1): implementation → validation → commit/push → PR → monitor
CI/reviews → potentially merge. Stop on blockers or judgment calls; do not bypass
required checks, repository protections, or unresolved review concerns. Preserve
unrelated working-tree changes. Do not reintroduce automatic ticket/worktree
scaffolding or Boba routing.

Invoking `/ship` is the explicit automation entry point; recording this
migration decision does not authorize shipping the current dotfiles changes.
Implementation/review execution is decided: a `pi-subagents` worker implements,
the parent validates, then a fresh independent read-only reviewer checks the
changes. Route actionable findings back to the worker and revalidate. Allow at
most 3 fix/review rounds, then stop for user input if unresolved. The parent
retains responsibility for delivery; child implementation/review tasks must not
commit, push, open PRs, merge, or write to Jira.

Merge authorization is decided: invoking `/ship` authorizes the parent to merge
once required checks pass, review concerns are resolved, and repository rules
permit it. No separate `--merge` flag or final confirmation is required. Never
bypass branch protections or required approvals. If these conditions cannot be
verified, stop rather than infer permission or readiness. For `/ship` and any
merge-authorized `/babysit-pr` invocation, follow the repository's documented
merge policy; if no policy is documented, use squash only when allowed. Stop
if policy is unclear/conflicting or the fallback is unavailable; do not silently
choose another method.

For both `/ship` and `/babysit-pr`, PR monitoring is bounded: poll approximately
every 60 seconds and stop after 60 minutes or 3 repair rounds, whichever limit
is reached first. Stop sooner for blockers or user-judgment calls. Report the
PR state, outstanding blockers/checks, and how to resume; never merge while
required checks are pending. The monitoring repair budget is separate from
`/ship`'s pre-delivery fix/review budget.

## `/babysit-pr` decision

**Keep full monitoring and fixes** (user selected option 1): monitor one PR's CI,
base drift, and review feedback; apply relevant fixes and push updates within the
invocation's scope. Merging requires explicit authorization at invocation and
passing required checks/repository protections. Stop on blockers, ambiguous review
requests, or decisions needing user judgment; preserve unrelated work. Use the
shared monitoring limits above (approximately 60-second polling, at most 60
minutes or 3 repair rounds). A `pi-subagents` worker makes fixes; the parent
validates and obtains a fresh independent read-only review before pushing.
Reply to and resolve a review thread only after its fix is pushed and verified.
Stop on ambiguous feedback; never dismiss reviews or override required approvals.
These repair/thread rules also apply when `/ship` enters PR monitoring.

## Skill decisions

| Skill | Purpose / current state | Decision |
| --- | --- | --- |
| `herdr` | Terminal management; currently installed, rewritten without specialist orchestration. | Keep for explicit terminal-management requests only |
| `improve-codebase-architecture` | Architectural survey, visual HTML candidates, interactive design discussion; currently installed. | Keep the full workflow, including the visual HTML report and interactive design discussion |
| `route-agents` | Select pinned specialists/model tiers; removed with the harness. | Drop; use `pi-subagents`' built-in guidance instead of a custom routing policy |

## Packages

- **Approved and installed:** `npm:pi-web-access@0.41.0`. Declared in the
  `pi_packages` task in `machine_setup.yaml` for install and update.
- **Approved and installed:** `npm:pi-subagents@0.78.0` for `/review`, `/dispatch`,
  `/ship`, and `/babysit-pr`, pinned for both install and update in machine setup.
  `/review` delegates to a fresh independent reviewer with explicit no-edit,
  no-commit, no-post instructions and a managed read-only tool allowlist. Detailed
  source inspection found that this version's builtin reviewer already declares
  read-only acceptance/tools (the earlier overview suggested optional fixes);
  the explicit constraints still apply. Report unavailable delegation rather
  than silently claiming an independent review. `/dispatch` uses a package worker
  for local implementation, with the parent coordinating and checking the result.
  Delivery/repair commands add fresh independent review; children never receive
  parent delivery authority. The package does not itself recreate Jira/Boba/PR
  workflows.
- Any subsequently approved package must be added to both install and update in
  `machine_setup.yaml`; do not leave dependencies as a one-off local installation.

## First decision: `/dispatch`

Former behavior: accept a ready Jira key, detect whether its project uses Boba
(unless explicitly specified), then either label it `boba` and watch for its PR,
or scaffold local work and hand off implementation. A separate `--auto` mode
pre-authorized downstream lifecycle steps; the normal mode kept preview gates.

Questions to resolve before migrating:

1. **Decided:** local implementation only; no Boba detection, labeling, or handoff.
2. **Decided:** start local implementation in the current checkout; the subsequent `/start` decision removes automatic ticket/worktree scaffolding.
3. **Decided:** accept a plain-language task or optional Jira key. A Jira key
   loads ticket context read-only; no assignment, labels, or status changes.
4. **Decided:** start the worker immediately when the task is clear; pause for
   ambiguity, blockers, or decisions outside scope. The parent checks the result.
   No separate `--auto` mode is needed for `/dispatch`; it does not commit, push,
   create PRs, merge, or write to Jira.
5. **Decided:** a `pi-subagents` worker implements; the parent coordinates and
   checks the result. Delegate a concrete scope and preserve unrelated edits.

Decision: **keep/migrate local implementation only** (user selected option 2).
Updated by the `/start` decision: implement in the current checkout, without
creating worktrees, branches, or ticket scaffolding automatically. Accept a
plain-language task or optional Jira key; load ticket context read-only, without
assignment, labels, or status changes. Start immediately when scope is clear;
pause for ambiguity, blockers, or out-of-scope decisions, without a separate
`--auto` mode. Execution uses a `pi-subagents` worker, with the parent
coordinating and checking its result. This does not authorize commits, pushes,
PR creation, merges, or Jira writes through `/dispatch`.

## Approved local workbench layer

The user approved a custom local package for verification contracts, thin-context
orchestration, and **Herdr option A: visibility/control only**, without installing
Agent Fleet. This supersedes the earlier blanket avoidance of a custom
orchestration layer, not the decision to keep native Pi/pi-subagents execution.

`home/pi-workbench/` is a private local Pi package, registered in `pi_packages`
for install/update/removal. It adds a revisioned, parent-owned contract ledger,
artifact-first native handoff preparation, bounded parent summaries with explicit
blockers, and manual Herdr display-token publication/owner navigation. It never
launches children, creates panes, replaces the system prompt, configures model
tiers, or introduces an independent runtime/daemon. Existing commands retain
all authority, independent-review, index-preservation, and monitoring limits.
Detailed usage and evidence limitations are in its README and `workbench` skill.

Evidence hashes bind report bytes, not source patches. Assessments/receipts are
parent-recorded, not automatic correctness or native-completion attestations.
Fresh exact-patch validation and native terminal results remain mandatory.
Private task artifacts are permitted outside the checkout; repository progress
and ticket scaffolding remain prohibited. Herdr operations require explicit
commands and a verified local owner binding; no automatic terminal orchestration.

## Implementation status

- Installed native templates: `/plan`, `/review`, `/dispatch`, `/ship`, and
  `/babysit-pr`. Removed `/land` and `/wrap-up` remain absent.
- No custom role files, routing skill, workflow-script engine, hooks, or monitoring
  daemon were added. These commands are model-followed prompt templates, not a
  deterministic delivery harness. Native package commands/prompts remain available.
- Managed settings recursively preserve unrelated values, including personal
  role/model overrides, while restoring the declared fresh/read-only reviewer
  tools and acceptance role. Resolved roles are inspected before delegation.
- Offline Pi resource discovery and the package's real reviewer `get` action
  confirm the prompts, error-free extension loading, and read-only reviewer setup.
  No model-backed worker, reviewer, delivery, or live PR-monitoring run was used
  to validate these templates; no commits/pushes/PR mutations were authorized or
  performed by this migration.

## `/start` decision

**Drop ticket/worktree scaffolding entirely** (user selected option 3).
Do not migrate `/start` or hide its scaffolding inside `/dispatch`. This does not
prohibit creating a branch or worktree when the user explicitly requests one.
