---
description: Browse open items in a board's active sprint (default ECW) and pick what to start
argument-hint: "[board/project key — defaults to ECW]"
---

Show me the open items in the active sprint so I can pick what to start. This is a
pool to grab from — the whole sprint's open work, not just what's assigned to me.
Selection is explicit and NEVER auto-dispatched: I start only the tickets I name,
behind the preview gate in step 3. It's fine to pick nothing.

## 1. Gather (Atlassian MCP)

- **Board/project key:** use `$ARGUMENTS` if given, else default to `ECW`.
- Query the active sprint's open items via `searchJiraIssuesUsingJql`:
  `project = <KEY> AND sprint in openSprints() AND statusCategory != Done ORDER BY rank`.
  If Atlassian is unavailable, say so and stop — there's nothing to browse without it.
- For each item capture: key, summary, status, and assignee (me / someone else /
  unassigned).

## 2. Present a numbered, actionable list

One line per open item, each PRE-BOUND to the start action and tagged for safety:

- `1. ECW-1060 "add rate limit" — To Do, unassigned` → start ✅ ready
- `2. ECW-1042 "rework billing" — To Do, unassigned, needs design input` → **needs you**
- `3. ECW-1039 "fix parser" — In Progress, you` → already yours; start resumes it
- `4. ECW-1051 "tune cache" — In Progress, @someone` → **someone else's**; won't start unless named

Judge and flag each item on two axes:

- **Ready** (concrete, low-ambiguity spec) vs **needs your design input** — be
  honest; a half-baked ticket handed off unattended wastes a run.
- **Ownership** — flag items already assigned to someone else or in progress;
  I can still grab one, but only if I name its number explicitly.

## 3. Select + start (behind the preview gate)

I reply with the numbers I want (e.g. `1 3`). There is no bare `go`/`all` here —
a sprint pool isn't a safe-to-auto set, so nothing starts without explicit numbers.

- **Show the start plan and STOP for one confirmation.** Print a one-screen plan:
  each selected item → the label/command it'll run → a one-line intent. This is the
  only thing I see before it runs.
- On my `go`, start each selected ticket in parallel and report back as each returns.
  The mechanism branches by whether its board/repo is **Boba-enabled**:
  - **Detecting Boba-enabled** (per ticket): the Boba pipeline stamps the `boba`
    label on the tickets it works, so a project that already uses it has prior
    `boba`-labeled issues. Probe with JQL `project = <KEY> AND labels = boba` — a
    non-empty result means Boba-enabled. Absence → **not** Boba-enabled.
  - **Boba-enabled** → add the `boba` label via `editJiraIssue` (appending to
    existing labels), which hands it to the Boba pipeline (`chewielabs/boba_fetch`)
    to pick up unattended. The pipeline owns branch/worktree/implementation.
  - **Not Boba-enabled** (or detection inconclusive — `worker` is the safe default)
    → run `/start <KEY>` first (scaffold its worktree + branch off fresh `main`)
    and hand the ticket to `worker` inside that worktree.
- **Offer** the opt-in Jira transition (→ In Progress) for each started ticket —
  only if I say yes; never silently.

Keep it frictionless: `/open-work` → glance → pick numbers → glance at plan → `go`.
The plan preview is a hard gate — never skip it, never start without it.
