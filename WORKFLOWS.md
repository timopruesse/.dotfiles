# Workflows

A visual map of the Claude Code **commands** (`home/.claude/commands/`) and the
**subagents** (`home/.claude/agents/`) they orchestrate — roughly the PR lifecycle,
front to back. See [`CLAUDE.md`](home/.claude/CLAUDE.md) for the prose reference.

## The flow graph

```mermaid
flowchart TD
    %% ---------- node groups (declared first for clean subgraph membership) ----------
    subgraph disc["🧭 Discover work"]
        direction LR
        MW(["/my-work<br/>prospective hub"])
        OW(["/open-work<br/>sprint pool"])
        SD(["/ship-digest<br/>retrospective"])
    end

    subgraph dispatch["🔀 /dispatch — ticket intake"]
        SHIP(["/ship KEY<br/>= /dispatch --auto"])
        DSP(["/dispatch KEY"])
        DISP{{"project Boba-enabled?"}}
        LBL["add 'boba' label<br/>→ boba_fetch pipeline"]
        ST(["/start<br/>worktree + branch"])
    end

    subgraph boba["🫧 Boba watch loop"]
        WB(["/watch-boba"])
        BW["boba-watcher<br/>read-only classify"]
        UNB["draft ticket update<br/>scout / Opus"]
        PG{{"preview gate"}}
        APP["apply update<br/>→ Boba re-analyzes"]
    end

    subgraph impl["🛠 Local implementation"]
        WK["worker"]
        LND(["/land"])
        VG{{"behavior change?"}}
        VER["verifier"]
        LPG{{"commit preview"}}
        CM["committer"]
        PRQ{{"PR exists?"}}
    end

    subgraph pr["🚦 PR → mergeable → merged"]
        BP(["/babysit-pr"])
        FL(["/babysit-fleet"])
        PRB["pr-babysitter"]
        AM{{"auto-mode +<br/>all-clear? (fail-closed)"}}
        MERGE(["mergeable ✅<br/>mode A: you merge"])
        MRG(["merged ✅<br/>→ Ready for Release"])
        HUM2(["needs you<br/>reviews / conflict"])
    end

    subgraph rev["🔍 Review · draft-only"]
        RR(["/review-requests"])
        PRR["pr-reviewer"]
        DR(["draft review<br/>you post"])
        AR(["/address-reviews"])
        DRP(["draft replies<br/>you post"])
    end

    SCOUT["scout"]
    OP(["/open-pr"])
    HUM1(["needs you"])

    %% ---------- edges ----------
    MW -->|"assigned Jira · ready"| DSP
    MW -->|"CI-red PR"| BP
    MW -->|"awaiting my review"| RR
    OW -->|"pick from pool"| DSP
    SD --> SCOUT

    SHIP -->|"mode B · --auto"| DSP
    DSP --> DISP
    DISP -->|"yes"| LBL
    DISP -->|"no / unsure"| ST
    LBL -. "offer" .-> WB
    ST --> WK

    WB --> BW
    BW -->|"WORKING"| WB
    BW -->|"BLOCKED"| UNB
    UNB --> PG
    PG -->|"you: go"| APP
    APP --> WB
    BW -->|"DONE · PR link"| BP
    BW -->|"WAITING / 2nd bail"| HUM1
    PG -->|"design call"| HUM1

    WK -. "done · you: /land" .-> LND
    LND --> VG
    VG -->|"runtime surface"| VER
    VG -->|"docs / mechanical"| LPG
    VER -->|"HOLDS"| LPG
    VER -->|"BREAKS · gated retry"| HUM1
    LPG -->|"you: go"| CM
    CM --> PRQ
    PRQ -->|"no PR · offer"| OP
    PRQ -->|"PR exists · push"| BP
    OP --> BP

    BP --> PRB
    FL --> PRB
    PRB -->|"code fix"| VER
    PRB -->|"WORKING"| BP
    PRB -->|"DONE · approved+green"| AM
    AM -->|"mode B · all-clear"| MRG
    AM -->|"mode A"| MERGE
    AM -->|"external blocker · fail-closed"| HUM2
    PRB -->|"WAITING"| HUM2

    RR --> PRR
    PRR -->|"risky logic"| VER
    PRR --> DR
    AR -->|"apply code"| WK
    AR --> DRP

    %% ---------- styling ----------
    classDef command fill:#dbeafe,stroke:#2563eb,color:#0b2559;
    classDef sonnet  fill:#dcfce7,stroke:#16a34a,color:#052e16;
    classDef opus    fill:#ede9fe,stroke:#7c3aed,color:#2e1065;
    classDef haiku   fill:#f1f5f9,stroke:#64748b,color:#0f172a;
    classDef gate    fill:#fef9c3,stroke:#ca8a04,color:#422006;
    classDef human   fill:#fee2e2,stroke:#dc2626,color:#450a0a;
    classDef done    fill:#bbf7d0,stroke:#15803d,color:#052e16;

    class MW,OW,SD,WB,DSP,ST,OP,BP,FL,RR,AR,LND,SHIP command;
    class SCOUT,BW,WK,PRB,PRR sonnet;
    class VER opus;
    class CM haiku;
    class DISP,PG,VG,LPG,PRQ,AM gate;
    class HUM1,HUM2 human;
    class MERGE,MRG done;
```

## Reading the graph

- **Rounded blue** nodes are slash **commands** you invoke; **rectangles** are
  **subagents** they spawn. **Hexagons** are decision / preview **gates**.
- Node colors encode the model pin: 🟢 Sonnet, 🟣 Opus (`verifier`), ⚪ Haiku
  (`committer`).
- The single **`verifier`** node is one agent invoked from several flows (the
  `/land` gate on local work, `pr-babysitter`, `pr-reviewer`) — the converging
  arrows show its reuse, not multiple agents.
- **`/land`** is the local counterpart to the Boba loop's `boba-watcher → /babysit-pr`
  hand-off: it closes the seam between `worker` and `/open-pr` by owning the
  post-`worker` conveyor (verifier gate → commit preview → `committer` → offer the
  next step). If a PR already exists it pushes the follow-up commit and offers
  `/babysit-pr` instead of `/open-pr`.
- **Red "needs you"** nodes are where a flow deliberately STOPS for a human: the
  design philosophy is *auto-fix the deterministic, surface the judgment calls*.
  Nothing posts to GitHub or resolves a review thread on your behalf.
- Two self-looping loops (`/watch-boba` → `boba-watcher`, `/babysit-pr` →
  `pr-babysitter`) re-fire on an interval via `ScheduleWakeup` and terminate
  themselves on `DONE` / `WAITING` / `MERGED`. The `STATUS:` vocabulary and the
  `ScheduleWakeup` cadence they (and `/babysit-fleet`) share are defined once in
  [`home/.claude/LOOP-PROTOCOL.md`](home/.claude/LOOP-PROTOCOL.md).
- The `/dispatch → … → merged` **spine auto-chains** in one of two modes: **A**
  (default) auto-invokes each successor but pauses at every preview gate for a
  one-word `go`; **B** (via `/ship`, `--auto`, or the hubs' `ship <nums>`) runs
  through, auto-approving the deterministic (AUTO) gates and stopping only at
  judgment (STOP) gates. Every spine step ends with an `ADVANCE → <next>` or
  `HALT: <reason>` line the orchestrator dispatches on. The spine, the taxonomy,
  the conditional **auto-merge** (fail-closed, mode-B only — the `auto-mode +
  all-clear?` gate), and the **Jira lifecycle** (In Progress → In Review → Ready
  for Release) are defined once in
  [`home/.claude/HANDOFF-PROTOCOL.md`](home/.claude/HANDOFF-PROTOCOL.md) — the
  synchronous sibling of `LOOP-PROTOCOL.md`.
- **Notifications:** a `Notification` hook
  ([`home/.claude/hooks/notify.sh`](home/.claude/hooks/notify.sh)) pings macOS
  (desktop notification + chime) when a loop **needs you** — a preview gate,
  permission, or idle wait — so you can fire off a loop and walk away. OS-aware;
  falls back to `notify-send` / a terminal bell off macOS.

## Agents at a glance

| Agent | Model | Role | Driven by |
|---|---|---|---|
| `scout` | Sonnet | read-only retrieval / codebase explain | gather in `/my-work`, `/open-work`, `/ship-digest`; Boba unblock locate |
| `worker` | Sonnet | implementer for concrete, low-ambiguity specs | `/start`, `/address-reviews`, Boba unblock |
| `verifier` | Opus | adversarial correctness gate (tries to BREAK a change) | `/land` gate, `pr-babysitter`, `pr-reviewer` |
| `committer` | Haiku | git staging / commit-message / commit / push | `/land` (post-`worker` conveyor) |
| `pr-babysitter` | Sonnet | shepherd one PR toward mergeable (CI, rebase, body); conditional fail-closed auto-merge in auto-mode | `/babysit-pr`, `/babysit-fleet` |
| `pr-reviewer` | Sonnet | draft-only adversarial PR review (never posts) | `/review-requests` |
| `boba-watcher` | Sonnet | classify a Boba-dispatched ticket's latest signal | `/watch-boba` |
| `sweep` | Sonnet | mechanical fix loops (tsc / lint / formatting) | ad hoc (not bound to a command) |

> Opus is reserved for reasoning-heavy work: the built-in `Plan` agent,
> `verifier`, and hard debugging.
