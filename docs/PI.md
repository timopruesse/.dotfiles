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
thinking for `openai/gpt-6.1-sol`. It also links the read-only `pstack-reviewer`
agent definition; package-provided Poteto agents stay in the package.
Malformed managed settings sections fail before installing resources. Unrelated
settings, package registrations, credentials, and sessions are preserved.
Reapplying setup restores
these managed defaults; session-specific model choices still work normally.

Do **not** bulk-symlink `~/.pi`: installation files, `auth.json`, `settings.json`,
trust decisions, model catalogs, and sessions stay machine-local and out of Git.
Select credentials with `/login`, models with `/model`, and preferences with
`/settings`. Project trust stays at Pi's default (ask); Pi tools are not sandboxed.

Herdr's official `herdr integration install pi` manages pane state and session
references. Pstack children run as isolated local Pi processes, not Herdr panes.
No workbench or Herdr subagent runtime is loaded.

## Packages

The `pi_packages` task depends on `pi_cli` and `dotfiles`. Both install and update
run Pi's native package installer for every approved plugin:

- `npm:pi-web-access@0.41.0`: web search, URL fetching, and document extraction.
- `npm:pi-pstack@0.1.0`: all 44 bundled pstack skills, sticky Poteto Mode,
  isolated subagents, `pstack_todo`, `pstack_sessions`, and `pstack_config`.
  Replaces `pi-subagents` and the local workbench integration. Install/update
  removes their package registrations first, without deleting saved state.
  Do not install `@casualjim/pi-pstack` alongside it; that fork targets a
  different runtime (`pi-herdr-agents`).
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

Versions are pinned for repeatable provisioning. Add future approved plugins to
both lists in `machine_setup.yaml`, not just to a local Pi installation. Package
registration remains in machine-local settings, managed by `pi install`. This task
does not upgrade or remove unrelated personal packages. Web-access provider keys
and optional configuration belong in `~/.pi/agent/web-search.json`, never Git.
Browser-cookie access and remote curator access stay disabled by default.

Delegation uses pstack's bundled `poteto-agent` with bundled scope and fresh
local processes. The managed `pstack-reviewer` uses user scope and only `read`,
`grep`, `find`, and `ls`; it consumes a parent-prepared exact-patch packet.
No shell, mutation, network tools, or nested delegation are selected for review.
Workers need shell access for tests. Tool selection and no-delivery instructions
are **not an OS sandbox**. Personal/project extensions remain trusted code.
See the [workflow decision record](PI-WORKFLOW-MIGRATION.md) for approved policies.

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

## Full Poteto Mode

Personal `AGENTS.md` makes the installed `poteto-mode` skill the default coding
workflow. It directs the model to read the full skill and matching playbooks,
track multi-step work with `pstack_todo`, and use deliberate fresh delegates.
This is instruction-driven, not an automatic extension-state toggle.

For the extension's sticky session state and status indicator, run:

```text
/poteto-mode <task>
/poteto-mode off
```

Mode state and todos persist on the current session branch. New sessions do not
inherit that extension toggle; the personal default still applies unless the
user opts out. An explicit opt-out must not be silently re-enabled.

Use `/setup-pstack` to map pstack roles to authenticated Pi models, or use
`pstack_config`. Configuration stays in `~/.pi/agent/pstack/models.json` (under
`PI_CODING_AGENT_DIR` if set), never Git. Unconfigured roles inherit the parent
model. No model pools or paid provider calls are configured by provisioning.

Pstack's `subagent` supports single, parallel `tasks` (up to eight tasks, four
running at once), and sequential `chain` calls. It returns completed results,
not pi-subagents run handles. Children use fresh `--no-session` local processes.
Do not assume persistent child sessions, async run IDs, workbench file-only
handoffs, resume, or a read-only sandbox.

The external-action guard stays enabled. Recognized pushes, PR mutations,
merges, deployments, infrastructure writes, and recursive deletion prompt for
confirmation in interactive Pi and are blocked in non-interactive children.
This is a regex guardrail, not a shell security boundary. Even an authorized
`/ship` can still need a runtime confirmation. Keep delivery in the parent.
Upstream playbooks can mention Graphite, Bun, GitHub authentication, or other
project-specific tools; installing pstack does not install those dependencies
or authorize their external actions. Local command limits take precedence.

The local workbench package is retired from provisioning and commands. Its
source and private saved contracts remain untouched for recovery. Legacy
`settings.json.subagents` preferences remain inert rather than deleting
user-owned configuration. Fresh setup no longer creates those preferences.

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
Pstack's skill commands remain available, for example `/skill:how`,
`/skill:architect`, `/skill:swarm`, and `/skill:unslop`. Their broader playbooks
are not permission to bypass this repo's delivery limits.

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
