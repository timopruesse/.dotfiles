# Pi coding setup

Pi is the default coding harness on Linux/WSL and macOS. Git identity still varies
by repository; the agent CLI does not. The managed startup model is
**OpenAI GPT 6.1 Sol (`gpt-6.1-sol`), medium thinking**.

## Install and configure

`machine_setup.yaml` provides `pi_cli`: the official managed installer, `pi update`,
and daily updates. The `dotfiles` task installs the resources below. Apply them
independently from a checkout with:

```sh
python3 home/setup_pi.py
```

The installer links version-controlled instructions and prompt templates from
`home/.pi/agent/`, plus the Herdr and architecture skills from `home/skills/`.
It preflights resource-name collisions and refuses to replace personal files.
Move or merge a conflicting file, then rerun. It recursively merges managed defaults
from `home/.pi/agent/settings.defaults.json` into machine-local settings: medium
thinking for `openai/gpt-6.1-sol` and a fresh/read-only reviewer tool allowlist.
Malformed managed settings sections fail before installing resources. Unrelated
settings, package registrations, credentials, and sessions are preserved.
Reapplying setup restores
these managed defaults; session-specific model choices still work normally.

Do **not** bulk-symlink `~/.pi`: installation files, `auth.json`, `settings.json`,
trust decisions, model catalogs, and sessions stay machine-local and out of Git.
Select credentials with `/login`, models with `/model`, and preferences with
`/settings`. Project trust stays at Pi's default (ask); Pi tools are not sandboxed.

Herdr's official `herdr integration install pi` manages pane state and session
references. The local workbench adds explicit display-only metadata/navigation,
not a lifecycle hook adapter, role generator, or replacement subagent runtime.

## Packages

The `pi_packages` task depends on `pi_cli` and `dotfiles`. Both install and update
run Pi's native package installer for every approved plugin:

- `npm:pi-web-access@0.41.0`: web search, URL fetching, and document extraction.
- `npm:pi-subagents@0.78.0`: native workers, independent reviewers, and package
  guidance. Roles inherit the parent model unless configured otherwise; native
  role-specific thinking defaults remain (the builtin reviewer uses high).
- `npm:pi-lens@4.4.3`: LSP diagnostics/navigation, language-aware linting,
  structural analysis, and bundled skills. Uses upstream defaults, including
  read-before-edit checks and automatic formatting/autofixes of edited files.
  Language-server/tool availability determines coverage; use `/lens-tools` and
  `/lens-health` to inspect it. Partial or unavailable checks are not clean results.
  The `rust` task installs `shuck-cli` (the `shuck` executable) for Zsh LSP support.
  If Lens reports `LSP Failed: shuck`, check that `shuck` is on `PATH`; install it
  with `cargo binstall -y shuck-cli`, then restart Pi to retry a failed server.
- `npm:pi-impeccable@0.1.0`: Impeccable design commands and opt-in non-blocking
  browser-feedback live mode. Requires Node.js >=24. Package installation does
  not install project skills or start live mode. `/impeccable install` explicitly
  installs upstream skills into `.agents/skills/impeccable`; design/live commands
  can also install them if absent. `/impeccable live` starts the background bridge;
  `/impeccable live stop` stops it. The extension version is pinned, but its
  upstream `impeccable` dependency is floating (`*`), not fully reproducible.
- `$HOME/pi-workbench` (local `pi-workbench@0.1.0`): persistent verification
  contracts, artifact-first native handoffs, and explicit Herdr status/navigation.
  Source and usage: [`home/pi-workbench/README.md`](../home/pi-workbench/README.md).
  No Agent Fleet dependency or package is installed.

Versions are pinned for repeatable provisioning. Add future approved plugins to
both lists in `machine_setup.yaml`, not just to a local Pi installation. Package
registration remains in machine-local settings, managed by `pi install`. This task
does not upgrade or remove unrelated personal packages. Web-access provider keys
and optional configuration belong in `~/.pi/agent/web-search.json`, never Git.
Browser-cookie access and remote curator access stay disabled by default.

Delegation uses the package's builtin roles and native completion handling, not
custom agent pins, tiers, Herdr panes, or fallback CLIs. The custom workflow prompts
inspect resolved roles in user scope before use. The reviewer is limited to read,
search, diff inspection, and supervisor contact; no shell, edits, or posting.
Workers need shell access for local tests: their no-delivery/no-external-write
boundary is an instruction, **not an OS sandbox**. Personal/project extensions
and configuration remain trusted code. See the
[workflow decision record](PI-WORKFLOW-MIGRATION.md) for the approved policies.

## Higgsfield MCP

The `pi_mcp` task registers the official Higgsfield HTTP MCP server on install
and update, using deferred tool loading. It requires no MarketingAgents package
or Higgsfield CLI. To register it manually:

```sh
pi mcp add higgsfield --url https://mcp.higgsfield.ai/mcp --exposure deferred --description 'Higgsfield image, video, and audio generation; ask for approval before spending credits.'
pi mcp login higgsfield
pi mcp list
```

Provisioning registers the endpoint but does not initiate browser sign-in. Complete
`pi mcp login higgsfield` on each machine, then `/reload` in an existing Pi session.
The endpoint configuration lives in `~/.pi/agent/mcp.json`; OAuth credentials stay
in `~/.pi/agent/mcp-auth.json`. Neither file is symlinked or committed. Uninstall
removes the server registration; use `pi mcp logout higgsfield` first to clear its
stored credentials if desired.

An active paid Higgsfield subscription is required. Generations spend credits;
ask for explicit approval before generating or making other paid changes. The
server description is guidance, not an enforced spending limit. See the
[official connection guide](https://higgsfield.ai/creator-hub/help-center/integrations/how-do-i-connect-higgsfield-to-ai-agent).

## OpenRouter MCP

The `pi_mcp` task also registers the official remote OpenRouter MCP server on
install and update with deferred tool loading. No local server or API key in
configuration is required. To register it manually:

```sh
pi mcp add openrouter --url https://mcp.openrouter.ai/mcp --exposure deferred --description 'Live OpenRouter models, pricing, credits, rankings, and docs; ask for approval before billable inference or submitting feedback.'
pi mcp login openrouter
pi mcp list
```

Provisioning only registers the endpoint. Run `pi mcp login openrouter` on each
machine to approve browser OAuth, then `/reload` in an existing Pi session.
Configuration and credentials stay in machine-local `~/.pi/agent/mcp.json` and
`~/.pi/agent/mcp-auth.json`, respectively; neither is symlinked or committed.
OpenRouter issues a dedicated key with a 7-day expiry and a default $10 spending
cap, editable during approval. Reauthenticate when it expires.

Tools provide live models, pricing, credits, rankings, benchmarks, and docs.
`send-message` and `generate-image` make billable inference calls; `send-feedback`
submits feedback to OpenRouter. Ask for explicit approval before those actions.
The description is guidance, not an enforced permission gate or spending limit.
Uninstall removes the registration; run `pi mcp logout openrouter` first if you
also want to remove stored credentials. See the
[official MCP guide](https://openrouter.ai/docs/guides/overview/mcp-server).

## Workbench contracts and thin context

`/dispatch`, `/review`, `/ship`, and `/babysit-pr` load the `workbench` skill.
The parent creates/reuses a task contract and uses `workbench` to prepare native
`pi-subagents` handoffs with fresh context and file-only outputs. Full reports
stay on disk; concise summaries, explicit blockers, and artifact references
return to the parent. Native subagents still own execution/completion/cancellation;
workbench never launches workers or conceals native failure output.

Contracts/evidence live below `~/.pi/agent/workbench/`, separated by canonical
checkout path and task UUID, not in repository progress files. Revisions prevent
lost updates, only the owning Pi session may mutate a contract, and history is
append-only through the API. Evidence hashes detect changed reports, not changed
source: parent must revalidate the exact patch/checks and reset affected criteria.
Recorded readiness is an assessment, not a proof or delivery authorization.

`/workbench` shows selected-task status; `/workbench list` and
`/workbench select <id>` inspect/restore task selection. Selection follows the
Pi session branch. `/workbench herdr` explicitly publishes a separate display
`$workbench` token for 60 seconds; add it to a Herdr sidebar row if desired.
`/workbench herdr clear` removes only that session's custom tokens.
`/workbench focus [id]` validates the live owning Pi session before focusing its
pane. No timer, daemon, terminal worker, or automatic focus/pane creation exists.

## Entry points

- `pi`: interactive Pi in the current terminal.
- `c`, `ch`, `cv`: Pi in a Herdr tab or split (require `HERDR_ENV=1`).
- `cr`: continue the latest Pi session for the checkout (`--continue`).
- `cpi`: prompt and optional piped input, using Pi print mode in a Herdr tab.
- Herdr `prefix+shift+H/V/R/S`: split / continue / resume via the same launcher.
- Neovim `<leader>z*`: the same Herdr launcher; 99 (`<leader>9*`) uses Pi's print
  provider without saving one-off sessions, inheriting the configured model.
- `CODING_AGENT=pi|claude|codex|agy|agent|cursor` or per-call `--pi`, `--claude`,
  `--codex`, `--agy`, `--agent`, `--cursor`: explicit alternative-client override.
  These launch clients directly, without generated roles or project-agent injection.

## Native workflow

- `/plan [task]`: investigate and propose a plan without editing.
- `/review [focus]`: fresh independent read-only review of local changes.
- `/dispatch <task or Jira key>`: one local implementation worker, then parent
  validation; no commits, pushes, PRs, or Jira writes.
- `/ship [task or existing-change scope]`: implementation → parent validation →
  independent review → scoped commit/push → PR → bounded monitoring → safe merge.
  Invocation authorizes merge; it does not bypass checks or required approvals.
- `/babysit-pr [PR number or URL] [--merge]`: monitor/fix one PR, with independent
  review before pushing and replies/resolution only after verified pushed fixes.
  Without explicit merge authorization, stop when ready rather than merging.
- `/skill:improve-codebase-architecture`: full architectural investigation,
  visual HTML report, and interactive design discussion.

These are native prompt templates, not deterministic automation or background
services. Invoking them supplies workflow instructions to the model. Neither
setup nor a discussion about `/ship` authorizes shipping the current changes.
`pi-subagents` also exposes its own native commands/prompts; those are not aliases
for this repo's delivery policies.

Delivery stays in the current feature-branch checkout: no automatic branch,
worktree, or ticket scaffolding. Preserve unrelated work and index content.
`/ship` stops after at most 3 pre-delivery fix/review rounds; PR monitoring has a
separate budget of 60 minutes or 3 repair rounds, with roughly 60-second polling.
Stop earlier for ambiguity or unverifiable checks/approvals. Use documented merge
policy, otherwise squash only when allowed; guard the exact head and never use
admin overrides. Reports must distinguish open/ready/queued from actually merged.
Unavailable delegation is a blocker, not permission for a fake independent review.

Use `/name`, `/resume`, `/tree`, and `/compact` for native session management and
`/session` for statistics. Run `/reload` after editing resources. Start a fresh
session if earlier conversation context still contains obsolete instructions.

## Ownership and maintenance

The former multi-client harness has been removed: generated specialists, tier
routing, legacy delegated workflow commands, protocols, sync tooling, custom session-cost
logging, and the Herdr subagent helper. Git history is the recovery mechanism.
There is no compatibility harness or archived copy in the active tree.

Alternative client preferences, MCP configuration, status lines, and independent
Herdr/AWS hooks remain separate from Pi. Existing sessions and credentials are
not removed. Setup excludes these client directories from bulk symlinking.

`pi_cli` uninstall removes only the managed binary and release directories;
it keeps credentials, sessions, and configuration. To unlink dotfiles resources,
remove only the individual links installed by `setup_pi.py`, not the agent directory.
