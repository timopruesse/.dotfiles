---
description: Summarize what you shipped (git + merged PRs + Jira) over a timeframe
argument-hint: "[since — e.g. '24h', 'yesterday', '1 week'; default 24h]"
---

Produce a digest of what I SHIPPED over the timeframe in `$ARGUMENTS` (default:
last 24h). This is retrospective — the sibling of `/my-work`, which is
prospective.

Fan out the retrieval to `scout` (cheap-tier; keeps the token-fat raw output
out of this thread) — spawn these in parallel, one `scout` call each:

1. **Git** — my authored/merged commits across the relevant repos in the
   timeframe (`git log --author=<me> --since=...`, pretty one-liners).
2. **GitHub** — my PRs merged in the timeframe: `gh search prs --author=@me
   --merged --merged=>=<date>` (title, repo, number).
3. **Jira** — my tickets that moved to done/resolved in the timeframe (via the
   Atlassian MCP; search by assignee + status-changed date).

Then synthesize their distilled results into a single markdown digest, grouped by
theme or repo, with a one-line "what/why" per item and links/numbers. Keep it
tight — this is a standup/status artifact, not a changelog. If a source returns
nothing or is unavailable (e.g. Jira not authorized), note that and carry on with
the rest rather than failing the whole digest.
