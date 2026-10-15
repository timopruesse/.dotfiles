---
name: herdr
description: "Control Herdr panes, tabs, and workspaces on explicit terminal-management requests; requires HERDR_ENV=1."
---

# Herdr terminal management

Use this skill only when the user asks to inspect or manage terminals, workspaces,
visible agents, or worktree tabs. Do not create panes merely to delegate coding
work. Pi has no assumed specialist roster or subagent runtime.

## Verify caller context

Before any Herdr control command:

```bash
test "${HERDR_ENV:-}" = 1
```

If it fails, stop and explain that this agent is not running inside Herdr. Do not
control the focused session from outside it. Require `HERDR_PANE_ID` for creation;
never fall back to whichever workspace the user is viewing.

## Discover syntax and state

The installed CLI is the authority. Start with `herdr --help`, then inspect the
relevant command group (`herdr pane`, `herdr tab`, `herdr workspace`, `herdr agent`,
`herdr worktree`, or `herdr machine`). Do not run bare `herdr`: it attaches the TUI.
Do not probe a mutating nested command with omitted arguments; defaults can execute.

Most commands return JSON. Parse returned IDs; never infer them from sidebar order.
Pane IDs and unique live agent names are different from terminal IDs or agent kinds.
A pane exists independently of its agent. `agent start` requires an available shell
pane; it does not create layout. Use pane commands for shells, tests, and servers.

```bash
herdr pane current --current
herdr agent list
```

Resolve the caller's current workspace through `pane current --current` before
creating a tab. Inherited `HERDR_WORKSPACE_ID` can be stale after a pane move.
Always pass that resolved workspace to `tab create --workspace`. The shared
`coding_agent_space.sh` launcher enforces this policy for shell/editor launches.

After moving a pane, use the returned new pane ID or live agent name. IDs are
server-scoped; local IDs do not identify panes on an SSH machine.

## Create and use terminals

For an explicitly requested sibling terminal:

```bash
herdr pane split --current --direction right --cwd "$PWD" --no-focus
```

Use `down` for a narrow layout. Read the returned `.result.pane.pane_id`, then:

```bash
herdr pane run <pane-id> "just test"
herdr pane wait-output <pane-id> --match "test result" --timeout 120000
herdr pane read <pane-id> --source recent-unwrapped --lines 120
```

`pane run` sends the command and Enter atomically. `wait-output` searches existing
output too; use `--regex` for a regular expression and always bound the timeout.
Use `--focus` when the user wants to watch the new terminal; otherwise preserve focus.

For Pi in a tab or split, prefer the existing
`$HOME/.config/herdr/scripts/coding_agent_herdr.sh` launcher with `tab`, `right`, or
`down`. It preserves caller context and starts Pi directly. Do not add automatic
trust or approval bypass flags. Herdr's official Pi integration owns pane state
and session references; no custom role prompts or terminal contracts are required.

## Inspect recognized agents

Use `agent get`, `agent read`, and `agent prompt` only after checking current CLI
syntax. `idle` or `done` means ready for input; `blocked` means a recognized approval
or question UI. `unknown` is not evidence that work finished. Read the result and
inspect actual changes/tests instead of trusting a state badge alone.

For reading transcripts, prefer `recent-unwrapped`; `visible` is just the current
viewport and `detection` is the classifier's bottom-buffer snapshot. Alternate-screen
history may be incomplete. If a larger read cannot recover a requested result,
ask the agent to write it to a temporary Markdown file and read that file.

## Remote machines and safety

- Use `herdr --machine <label-or-id>` consistently for discovery and every subsequent
  remote command. TUI selection does not retarget commands from this pane.
- Machine forwarding requires an already running compatible remote server. Do not
  install, start, restart, or replace one to repair a connection without permission.
- Only add/remove/enable/disable machine profiles when asked. A failed connection
  does not prove a mutation failed; inspect state before retrying.
- Do not close panes, tabs, workspaces, or sessions you did not create unless asked.
  `workspace close --group` can close linked worktree workspaces as well.
- Do not kill the Herdr process or stop its server from an active session. Server
  shutdown requires explicit intent to terminate the pane processes.
- Check `herdr status` for version mismatches; a missing method is not permission
  to restart or upgrade the server. Use isolated named sessions for experiments.
- Use `--trust-repository` only after explicit repository trust, not as a routine
  retry. Keep credentials out of captured terminal output.
