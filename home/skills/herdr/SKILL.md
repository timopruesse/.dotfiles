---
name: herdr
description: >-
  Control Herdr, a terminal multiplexer for coding agents. Use to inspect or control
  panes, tabs, workspaces, commands, and — only on explicit user
  terminal-management intent (watch a subagent in a visible pane, or scaffold
  a worktree/tab) — to run a subagent there instead of the host's native
  subagent tool. Requires HERDR_ENV=1.
---

# Herdr

Herdr organizes terminals into workspaces, tabs, and panes, recognizes coding agents running inside panes, and exposes the current session through the `herdr` CLI.

Before issuing any control command, verify that this agent is running inside a Herdr-managed pane:

```bash
test "${HERDR_ENV:-}" = 1
```

If the check fails, say that you are not running inside Herdr and stop. Do not inspect or control the focused Herdr session from outside Herdr.

When the check passes, the `herdr` binary in `PATH` talks to the current session. Use it to inspect neighboring work, create terminal layout, start agents and commands, read output, and wait for state changes.

## Learn the current CLI

The installed binary is the authority for command syntax. Start with:

```bash
herdr --help
```

Then print the relevant command group by running the group without a subcommand:

```bash
herdr agent
herdr pane
herdr workspace
herdr tab
herdr worktree
herdr terminal
herdr notification
herdr integration
herdr session
herdr machine
```

Do not run bare `herdr` for discovery; it launches or attaches the TUI. Do not probe a mutating nested command by omitting arguments. Commands such as `herdr workspace create` are valid with defaults and will execute.

Most control commands return JSON. Read identifiers and state from those responses instead of predicting them.

## Understand layout, panes, and agents

Choose the primitive that matches the job:

- Workspace, tab, and pane topology organize terminal locations.
- Pane commands control raw terminals, shells, tests, servers, input, and output.
- Agent commands control the recognized coding agent currently occupying a pane.

A pane exists whether or not it contains an agent. `agent start` requires an existing available shell pane and never creates, splits, or moves layout. Use pane commands for ordinary processes. Use agent commands when Herdr must validate agent identity or interpret `idle`, `working`, `blocked`, `done`, and `unknown` lifecycle states.

Agent commands accept either a unique live agent name or the pane ID currently hosting that agent. They do not accept terminal IDs or bare agent-kind labels. Names must match `[a-z][a-z0-9_-]{0,31}` and be unique among live agents. A name follows the current pane occupant and is cleared when that agent exits, is released, or is replaced.

`idle` and `done` both mean the agent is ready for input. The CLI/API uses the server's seen state to distinguish them; explicit focus commands mark the target seen, while reads do not. Each TUI client tracks viewed completions independently, so its Done badge can differ from the CLI or another client's badge. `blocked` means Herdr recognized an approval or question UI. `unknown` means an agent is present but Herdr cannot classify it confidently; it does not prove completion.

## Use IDs and caller context

Public IDs are opaque stable handles:

- workspace: `w1`
- tab: `w1:t1`
- pane: `w1:p1`

Closed tab and pane IDs are not reused. A pane moved into another workspace receives a new workspace-qualified pane ID. After `pane move`, continue with `.result.move_result.pane.pane_id` or the live agent name. The old value is reported as `.result.move_result.previous_pane_id`; only the moved process's inherited caller context keeps resolving that old ID, so do not use it as a general agent target.

Herdr injects the caller's context into each managed pane:

```bash
printf '%s\n' "$HERDR_WORKSPACE_ID" "$HERDR_TAB_ID" "$HERDR_PANE_ID"
```

**Orchestrator placement rule:** Every worker split or tab must stay in the
orchestrator’s space, regardless of which space the user is viewing. Require
`HERDR_PANE_ID`; if caller context cannot be resolved, stop instead of falling
back to UI focus. Resolve the live workspace with `herdr pane current --current`
(inherited `HERDR_WORKSPACE_ID` can be stale after a pane move). Always pass that
workspace explicitly to `tab create --workspace`. The shared launch helpers
enforce this through `coding_agent_space.sh`.

Prefer `--current` when a pane command should target the calling pane. An omitted `pane split` target uses the calling pane when `HERDR_PANE_ID` is available, otherwise the focused pane. Other commands may use the UI-focused pane, which can belong to the user or another client.

Discover live state with:

```bash
herdr workspace list
herdr tab list --workspace "$HERDR_WORKSPACE_ID"
herdr pane current --current
herdr pane list --workspace "$HERDR_WORKSPACE_ID"
herdr agent list
```

Creation responses expose the IDs to use next. `workspace create` returns `.result.workspace`, `.result.tab`, and `.result.root_pane`. `tab create` returns `.result.tab` and `.result.root_pane`. `pane split` returns the new pane as `.result.pane`.

IDs and live agent names are scoped to one server. Two saved SSH machines can both have `w1:p1` or an agent named `reviewer`. Selecting a machine in the TUI does not retarget commands running in your pane: without `--machine`, they still use the inherited session and socket context.

To control a saved SSH machine, use the same global prefix for discovery and every later command:

```bash
herdr --machine <label-or-id> agent list
herdr --machine <label-or-id> pane list
herdr --machine <label-or-id> agent prompt <remote-agent-name> "Reply with your current status." --wait --timeout 120000
```

The selector must be an enabled saved profile ID or a unique, case-sensitive label, not an arbitrary SSH hostname. Commands use that profile's remote session without an open TUI. Do not combine `--machine` with `--session` or `--remote`. Discover IDs on that machine; inherited local IDs and `--current` do not identify remote panes.

Both installations must support machine API forwarding, and the remote server must already be running and API-compatible. Forwarding never installs, starts, or restarts a server and never falls back to Local. Local configuration, session management, installation commands, and interactive attachment are not forwarded. Remote worktree paths must be absolute, `~`, or start with `~/`; plugin link paths must be absolute. A connection failure does not prove a mutation was not applied: inspect remote state before retrying.

`herdr machine list` lists saved connection profiles, not a cross-machine pane inventory; add `--json` for scripts. Only add, remove, enable, or disable profiles when the user asks. Removing a profile disconnects the client but does not stop remote sessions. Adding a machine uses the remote default session unless `--remote-session` is explicitly supplied. Setup asks before stopping an incompatible server and defaults to No; do not approve replacement without the user's consent. Experimental handoff is not part of `machine add`.

## Subagent orchestration via Herdr (explicit terminal-management intent only)

> [!IMPORTANT]
> **Parent Orchestrator ONLY:**
> This subagent orchestration workflow is exclusively for the root parent orchestrator.
> **Leaf agents (`worker`, `scout`, `verifier`, `committer`, `sweep`, etc.) must NEVER spawn subagents, use Herdr to delegate, or split panes.** Leaf agents must execute their assigned task directly.

The host CLI's own native subagent tool (`Task`/`Agent` in Claude Code,
`Task`/`subagent_type` in Cursor, `invoke_subagent` in Antigravity) is the
default subagent engine — see `~/protocols/AGENT-ROUTING.md`. Reach for this
Herdr workflow instead only on **explicit terminal-management intent**: the
user asks to watch a specialist work in a visible pane, or wants an explicit
worktree/tab. Being async or long-running is not by itself a reason to use it —
prefer the host's own background/async subagent lifecycle for that.

### Why Herdr for subagents (when asked for)

1. **Visual visibility:** The subagent runs in its own pane or tab. The user can watch its commands, file edits, and tool executions live in the Herdr interface.
2. **True isolation:** Each subagent runs as an independent process with its own terminal session, environment, and working directory.
3. **Full communication:** The orchestrator dispatches the task, waits for completion, inspects progress or approvals, and receives the structured terminal contract (`ADVANCE`, `HALT`, `VERDICT:`, `STATUS:`).

### Topology: when to split vs when to open a tab

- **Split pane (`herdr pane split`)** — for focused, synchronous subagent tasks
  the user explicitly wants to watch side-by-side (`scout`, `scout-explain`,
  `worker`, `verifier`, `committer`, `sweep`).
  Split direction: inspect the layout (`herdr pane layout --pane "$HERDR_PANE_ID"`). Split **right** if wide; split **down** if narrow or tall.

- **New tab (`herdr tab create`)** — use when:
  - The task needs its own git worktree (e.g. `/start <KEY>` scaffold at `~/worktrees/<repo>/<KEY>`).
  - The user explicitly wants a long-lived or async loop agent (`boba-watcher`,
    `pr-babysitter`, `babysit-fleet`) visible in its own tab — otherwise prefer
    the host's native background/async subagent lifecycle for that work.
  - The current tab already has multiple splits and another split would be cramped.

### Protocol: orchestrator ↔ subagent lifecycle

You can orchestrate using the helper script `$HOME/.config/herdr/scripts/coding_agent_subagent.sh` or directly with `herdr` commands.

#### Step 1: Create the pane or tab

**Split:**
```bash
test -n "${HERDR_PANE_ID:-}" || return 1
herdr pane current --current >/dev/null || return 1
resp=$(herdr pane split --current --direction right --cwd "$PWD" --focus)
pane_id=$(printf '%s\n' "$resp" | python3 -c 'import json, sys; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])')
```
(Use `--direction down` for tall/narrow panes. `--focus` lets the user see the subagent activate).

**Tab:**
```bash
test -n "${HERDR_PANE_ID:-}" || return 1
caller=$(herdr pane current --current) || return 1
workspace=$(printf '%s\n' "$caller" | python3 -c 'import json, sys; w = json.load(sys.stdin)["result"]["pane"]["workspace_id"]; assert w; print(w)') || return 1
resp=$(herdr tab create --workspace "$workspace" --cwd "$PWD" --label "worker" --focus)
pane_id=$(printf '%s\n' "$resp" | python3 -c 'import json, sys; print(json.load(sys.stdin)["result"]["root_pane"]["pane_id"])')
```

#### Step 2: Start the agent in the new pane (ALWAYS with Auto Mode)

Subagents **MUST always be started in Auto Mode** (or the host CLI's auto-approval flags).
If launched without auto mode, the subagent will stop to prompt for approval on file edits
and commands, blocking the unattended orchestrator run.

```bash
# Claude Code (Auto Mode classifier; add --dangerously-skip-permissions for full unattended Mode B):
herdr agent start worker --kind claude --pane "$pane_id" -- --agent worker --permission-mode auto

# Antigravity (agy - auto-approve all tool permissions):
herdr agent start worker --kind agy --pane "$pane_id" -- --agent worker --dangerously-skip-permissions

# Cursor CLI (force allow commands, trust workspace, approve MCPs):
herdr agent start worker --kind cursor --pane "$pane_id" -- -f --approve-mcps --trust --model <cursor-model>
```

`herdr agent start` automatically waits until the agent process starts and signals interactive readiness.

#### Step 3: Dispatch prompt and wait for results

Submit the prompt with `--wait` so Herdr pauses execution until the agent finishes its turn (transitions to `idle`, `done`, or `blocked`):

```bash
herdr agent prompt worker "
Spec: <exact instructions>
Scope: <target files>

Instructions:
1. Make the changes cleanly.
2. Run relevant tests/checks.
3. Report what you did and end your response with your required terminal line:
   ADVANCE → /land  (if all checks pass)
   HALT: <reason>   (if blocked or spec is ambiguous)
" --wait --timeout 300000
```

#### Step 4: Handle agent state

Check the agent's status if needed:
```bash
herdr agent get worker
```
- If state is `idle` or `done`: The turn is complete. Read the result.
- If state is `blocked`: The agent is waiting at an interactive approval or question dialog.
  - Read recent output (`herdr agent read worker --source recent --lines 40`) to inspect the question.
  - Inform the user or reply via `herdr agent prompt worker "<answer>" --wait` or `herdr agent send-keys worker ...`.

#### Step 5: Read back the result and terminal contract

```bash
herdr agent read worker --source recent-unwrapped --lines 120
```

Extract the agent's findings and verify the required terminal line (`ADVANCE → ...`, `HALT: ...`, `STATUS: ...`, or `VERDICT: ...`).
- If the terminal line is missing, treat as `HALT: missing terminal contract` per `HANDOFF-PROTOCOL.md`.
- For multi-turn follow-up, simply send another `herdr agent prompt worker "<follow-up>" --wait`.

#### Step 6: Cleanup or retain

- **`committer` panes/tabs MUST be closed immediately upon completion:**
  `committer` only performs routine git staging and committing. Its terminal session holds no diagnostic details or diffs that need to be revisited. Always close its pane/tab once it reports completion:
  ```bash
  herdr pane close "$pane_id"
  ```
  (`coding_agent_subagent.sh run --agent committer` automatically closes `committer` upon completion).
- **Inspection / reasoning panes (`worker`, `verifier`, `sweep`, `scout`):**
  Leave these open so the user can inspect code edits, test outputs, compiler errors, or findings in the split pane.

### Streamlined helper script: `coding_agent_subagent.sh`

The helper script `$HOME/.config/herdr/scripts/coding_agent_subagent.sh` packages this into a single command:

```bash
# Run a subagent synchronously and capture its output:
$HOME/.config/herdr/scripts/coding_agent_subagent.sh run \
  --agent worker \
  --layout right \
  --prompt "Implement the requested change..."

# Or step-by-step:
pane_id=$($HOME/.config/herdr/scripts/coding_agent_subagent.sh spawn --agent scout --layout right)
$HOME/.config/herdr/scripts/coding_agent_subagent.sh prompt scout "Find all callers of auth()"
output=$($HOME/.config/herdr/scripts/coding_agent_subagent.sh read scout)
```

## Run an ordinary command in another pane

Create a sibling pane with the same geometry rule, preserve the caller's working directory, and keep user focus unchanged:

```bash
herdr pane split --current --direction right --cwd "$PWD" --no-focus
```

Read the new pane ID from `.result.pane.pane_id`, then run and inspect the command:

```bash
herdr pane run <returned-pane-id> "just test"
herdr pane wait-output <returned-pane-id> --match "test result" --timeout 120000
herdr pane read <returned-pane-id> --source recent-unwrapped --lines 120
```

`pane run` atomically sends command text and Enter. `pane wait-output` searches the selected snapshot immediately, so output that already exists can match. Use `--match <text>` for a literal substring or `--regex <pattern>` for a Rust regular expression. Omitting `--timeout` allows an indefinite wait.

Use the read source that matches the task:

- `visible`: the currently rendered viewport.
- `recent`: recent rendered output, including soft wraps.
- `recent-unwrapped`: recent output with soft wraps joined; prefer it for logs and transcripts.
- `detection`: the plain-text bottom-buffer snapshot used for agent detection.

Use `--format ansi` when colors and terminal styling are evidence. Otherwise use text.

`--lines` asks Herdr for more rows from the pane's available screen and host scrollback. Alternate-screen rows do not enter ordinary host scrollback. For supported idle agents, Herdr can collect application-owned history and restore the viewport afterward, but not every application or response can be recovered this way.

If a larger recent read still does not reveal the completed response, ask the agent to write it as Markdown in a temporary directory and reply only with the file path, then read that file on the same machine. Use this only as a fallback; do not request file output in the initial prompt.

## Safety and coordination rules

- Use `--focus` when opening a subagent tab or split so the user can easily follow along with the new agent.
- Use `--no-focus` for silent background jobs (e.g. running build/tests in a separate pane).
- Use `--current`, an explicit pane ID, or a unique agent name. Do not rely on another client's focused pane.
- Parse IDs from JSON responses. Do not derive them from sidebar order or examples.
- Do not close workspaces, tabs, panes, or sessions you did not create unless the user explicitly asked. `workspace close --group` closes the primary workspace and its linked worktree workspaces; never add it merely to bypass `workspace_group_close_required`.
- Use `--trust-repository` only after the user has verified the repository. It grants per-request Git trust; it is not a routine retry for a failed worktree command.
- Client and server versions can differ after an update. Check `herdr status` before relying on new server features. A missing method is not permission to stop or upgrade a server.
- Never run `herdr server stop` from an active session unless the user explicitly intends to stop the server and its pane processes.
- Never kill the main Herdr process. Use named test sessions for experiments that need an isolated server.
- CLI server errors are JSON on stderr with exit status 1. CLI syntax errors exit with status 2.
