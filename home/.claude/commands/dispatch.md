---
description: Start one ready Jira ticket the right way — Boba label vs /start + worker
argument-hint: "<JIRA-KEY> [boba|no-boba] (e.g. ECW-1061 boba)"
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
  implementation. This session just labels. After labeling, **offer**
  `/watch-boba <KEY>` to shepherd the ticket to a PR (or surface a blocker) —
  opt-in, don't auto-start it.
- **Not Boba-enabled** → run `/start <KEY>` first (scaffold its worktree + branch
  off fresh `main`), then **offer** to hand the ticket to `worker` inside that
  worktree, with the ticket AC as the spec. Don't auto-implement.

## Offer the opt-in Jira transition

Offer the transition (To Do → In Progress) via the Atlassian MCP as one line —
only do it if I say yes; never silently.

Report what you did (labeled / scaffolded) and the follow-ups on offer. If the
Atlassian write or `/start` fails, stop and show the error rather than proceeding.
