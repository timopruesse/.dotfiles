---
description: Watch a Boba-dispatched ticket until it lands a PR — auto-hand to /babysit-pr, gate unblocks
argument-hint: "<JIRA-KEY> (the boba-labeled ticket, e.g. ECW-1061)"
---

Watch the Boba-dispatched Jira ticket `$ARGUMENTS` on a self-paced loop until Boba
Fetch (`chewielabs/boba_fetch`) either opens a PR or gets stuck. If no key is
given, ask for one — there's no branch to infer a Boba ticket from.

Each iteration:

1. Spawn the `boba-watcher` agent for ONE read-only sweep of `$ARGUMENTS`. It
   classifies Boba's latest signal and returns a terminal `STATUS:` line plus a
   payload (PR URL, or blocker Reason/Suggestions). Relay its summary to me
   concisely.
2. Read the `STATUS:` and act:

   - **`STATUS: WORKING`** — Boba holds the ticket, no terminal signal yet.
     Schedule the next sweep with `ScheduleWakeup`, re-firing this same command
     (`prompt` = `/watch-boba $ARGUMENTS`). Boba's transitions land on a minutes
     timescale (analysis/bail within a minute or two, a PR in ~several minutes), so
     use a cache-warm delay ~270s. Then stop this turn — the wakeup resumes the loop.

   - **`STATUS: DONE`** — Boba opened a PR. Do NOT schedule another `boba-watcher`
     sweep; the ticket→code phase is over. Hand off to the PR lifecycle: invoke
     `/babysit-pr <PR-URL-or-number>` (from the URL the watcher extracted) to
     shepherd the new PR toward mergeable. Tell me the PR link and that babysitting
     has taken over. The watch loop ends here.

   - **`STATUS: BLOCKED`** — Boba bailed asking for more information. This is the
     auto-unblock path, and it is GATED — I confirm before anything touches the ticket:
     1. If the report carries `REPEATED-BAIL` (Boba has bailed 2+ times), do NOT
        auto-draft again. Stop, surface Boba's reason, and tell me it needs my
        decision — a ticket Boba bounces twice is a real ambiguity, not a fillable gap.
     2. Otherwise, spawn an agent to investigate and DRAFT a ticket update that
        resolves Boba's stated Reason/Suggestions — it must NOT apply anything, only
        return the proposed edit. Choose the agent by blocker type:
        - a concrete missing fact (e.g. "name the target file/directory") → `scout`
          to locate the answer in the repo, then compose the clarification;
        - anything needing judgment about scope/approach → route to Opus
          (general-purpose) — not `worker`, since this is spec-drafting, not coding.
        If the blocker is a genuine design decision rather than a fillable gap, the
        agent should say so and propose nothing — then surface it to me as needs-you
        instead of fabricating an answer.
     3. **Show me a preview and STOP for confirmation.** Print exactly what would
        change: the target (description edit and/or a new clarifying comment) and the
        full proposed text. This is a hard gate — never apply without my `go`.
     4. On my `go`, apply the update via the Atlassian MCP (`editJiraIssue` for the
        description, and/or `addCommentToJiraIssue` for a clarification). Boba
        auto-re-analyzes on a ticket update (observed: it posts "is retrying this
        ticket" without needing the label re-added), so after applying, resume the
        loop with `ScheduleWakeup` (`/watch-boba $ARGUMENTS`, ~270s) to catch the
        retry → PR. If after a couple of sweeps Boba has NOT posted a retry, surface
        that — it may need a manual re-trigger (re-applying the `boba` label).

   - **`STATUS: WAITING`** — no longer Boba's to move (label gone / never picked up,
     or a human has taken the ticket over). Do NOT schedule. Stop and tell me what
     the watcher saw.

   - Anything else (no key, MCP/auth error, agent failed) — do NOT schedule. Stop
     and report the problem.

The loop is self-terminating: it continues only on `WORKING` (and after a confirmed
unblock), and stops on `DONE` (handing to `/babysit-pr`), `WAITING`, unconfirmed
unblock, or error. You do not need to wrap this in the /loop skill.
