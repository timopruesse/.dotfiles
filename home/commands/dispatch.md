---
description: Start one ready Jira ticket the right way — Boba label vs /start + worker
argument-hint: "<JIRA-KEY> [boba|no-boba] [--auto] (e.g. ECW-1061 boba)"
tier: cheap
---

Dispatch ONE ready Jira ticket (`$ARGUMENTS`) into implementation. This is the
shared intake mechanism behind `/my-work` and `/open-work`: they gather, judge,
and gate a batch, then hand each confirmed key here. It's also invocable directly
when you already know the ticket you want to start.

This command is the EXECUTOR, not the gatekeeper. It assumes the decision to start
this ticket was already made — either you named the key yourself, or a caller
cleared it through its batch preview gate. Do NOT re-gate; just dispatch and report.

## Parse the target

- First token: the ticket key (e.g. `ECW-1061`). If none, say so and stop.
- Optional second token: a pre-resolved Boba verdict — `boba` or `no-boba`. A
  caller that already probed the project (once, for the whole batch) passes it so
  this command doesn't re-probe. If absent, detect it below.
- Optional `--auto` token (anywhere after the key): selects mode **B**
  (pre-authorized) per [`~/protocols/HANDOFF-PROTOCOL.md`](../protocols/HANDOFF-PROTOCOL.md) — auto-
  approve AUTO gates downstream, stop only at STOP gates. Absent → mode **A**
  (default): auto-chain to the next step, but pause at every preview gate for a
  `go`. `/ship <KEY>` is exactly `/dispatch <KEY> --auto`. This is the one place
  mode enters the spine — it's carried in session context from here on, and every
  auto-advanced successor (`/watch-boba`, `/start` → `worker`, `/land`,
  `/open-pr`, `/babysit-pr`) inherits it.

## Detect Boba-enabled (only if no verdict was passed)

The Boba pipeline (`chewielabs/boba_fetch`) stamps the `boba` label on the tickets
it works, so a project that already uses it has prior `boba`-labeled issues. Probe
once with JQL `project = <PROJECT> AND labels = boba` via the Atlassian MCP
(`<PROJECT>` = the key prefix, e.g. `ECW`). Non-empty → Boba-enabled. Absence, or
detection inconclusive → treat as NOT Boba-enabled: `worker` is always the safe
default.

> Callers dispatching a batch: probe **once per distinct project**, not once per
> ticket — the verdict is a property of the project. Pass it down as the second
> token so each `/dispatch` skips its own probe.

## Branch on the verdict

- **Boba-enabled** → add the `boba` label via the Atlassian MCP (`editJiraIssue`,
  appending to existing labels — never clobber them). That hands the ticket to the
  Boba pipeline to pick up unattended; the pipeline owns the branch, worktree, and
  implementation. This session just labels. After labeling, **auto-advance** by
  launching `/watch-boba <KEY>` to shepherd the ticket to a PR (or surface a
  blocker) — under mode A this runs up to `/watch-boba`'s own next gate and waits;
  under B it runs through.
- **Not Boba-enabled** → **auto-advance** into `/start <KEY>` (scaffold its
  worktree + branch off fresh `main`) — under mode A this runs up to `/start`'s
  own next gate and waits; under B it runs through. `/start` in turn auto-advances
  into `worker` with the ticket AC as the spec, so the chain reaches
  implementation without a second hop back through here.

## Jira transition

Only this command fires the "work starts" transition (To Do → In Progress) — and
only on the **Boba-enabled** branch, since `/start` is not called there and would
otherwise own it (on the local branch, `/start` fires it instead). Per
[`~/protocols/HANDOFF-PROTOCOL.md`](../protocols/HANDOFF-PROTOCOL.md)'s Jira lifecycle mapping: **AUTO**
under mode B (fire it via the Atlassian MCP without asking); under mode A, a
one-line **offer** — only do it if I say yes; never silently.

Report what you did (labeled / scaffolded) and the follow-up in flight. If the
Atlassian write or `/start` fails, `HALT: <reason>` rather than proceeding — never
advance on error.

`ADVANCE → /watch-boba` (Boba-enabled) or `ADVANCE → /start` (not Boba-enabled) on
success.
