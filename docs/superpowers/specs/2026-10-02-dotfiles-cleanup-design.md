# Dotfiles cleanup — design

Date: 2026-10-02  
Status: approved for planning

## Goal

Moderate prune of personal dotfiles: shell/host-config hygiene, soft-demote Cursor in prose (Codex = personal default), and consolidate overlapping root docs. Leave Neovim config, `machine_setup.yaml`, and terminal settings for a later pass. Keep Cursor sync emitters working.

## Constraints

- **Aggressiveness:** moderate — drop unused/duplicate when evidence is clear; consolidate docs; no speculative host-tree deletes.
- **Areas this round:** shell + Claude/Cursor host config + docs/sync *sources of truth* (root markdown, not generated pins).
- **Out of scope:** `home/.config/nvim/`, `machine_setup.yaml`, `terminal/`, deleting Cursor sync/live-install.
- **Host posture:** personal → Codex; work (`chewielabs`) → Claude Code; Cursor Agent CLI → override / secondary. Resolver already encodes this; docs must match.
- **Cursor:** soft demote only — sync/emitters stay; root docs stop implying Cursor is the personal default.

## Current issues (known)

1. **Antigravity PATH cruft** — `.zprofile` and `.zshrc` each append hard-coded `/home/timo/.local/bin` after an existing `$HOME/.local/bin` export.
2. **Leaked Claude settings** — dirty `home/.claude/settings.json` contains `autoMode.environment` prose scoped to `chewielabs/boba_fetch`, removed git-config deny rules, and model flip `claude-fable-5-1[1m]` → `opus`. Also enables Impeccable marketplace (keep).
3. **Doc overlap / framing drift** — seven root markdown files; `CLAUDE.md` mirrors README + reference indexes; `SESSION-COST-LOGGING.md` is a separate top-level doc; several lines still say “Claude vs Cursor” for launchers despite Codex personal default.

## Approach

Hygiene + doc consolidation (chosen over surgical-only and hygiene-without-fold).

## Design

### 1. Shell hygiene

- Remove Antigravity installer blocks from `home/.zprofile` and `home/.zshrc`.
- Leave the intentional `$HOME/.local/bin` exports in place (login + interactive).
- No other PATH reordering this pass.

### 2. Claude host settings

File: `home/.claude/settings.json`

| Item | Action |
| --- | --- |
| `autoMode` (boba_fetch leak) | Remove entirely |
| `permissions.deny` git-config identity rules | Restore from HEAD |
| `model` | Restore `claude-fable-5-1[1m]` |
| Impeccable marketplace + `enabledPlugins` | Keep |
| Other dirty deltas (hooks/plugins unrelated) | Keep only if they remain after the above; no drive-by plugin churn |

### 3. Doc consolidation

**Keep as canonical specialty docs**

| File | Role |
| --- | --- |
| `ALIASES.md` | zsh aliases / functions |
| `KEYBINDS.md` | Herdr + Neovim keybinds |
| `CONTEXT.md` | domain glossary (skills assume this path) |
| `WORKFLOWS.md` | spine / flow graph |

**Fold**

- Move `SESSION-COST-LOGGING.md` body into `WORKFLOWS.md` as a **Telemetry / session cost** section.
- Replace `SESSION-COST-LOGGING.md` with a short stub that links to that section (preserve inbound links from agents/protocols READMEs).

**Slim**

- `CLAUDE.md`: drop mirror “Keybinds / Aliases / Workflows Reference” sections that only restate other files; keep repo structure, apply model, git identity, key behaviors, and a short coding-agent routing blurb + links.
- `README.md`: update coding-agent one-liner and index to the reduced set; Codex = personal default; Cursor = secondary.

**Framing pass (all touched root docs + stubs)**

- Personal host = Codex; work = Claude; Cursor = override/secondary.
- Fix stale “Claude vs Cursor by cwd” style lines (e.g. `WORKFLOWS.md` header).
- Do not rewrite generated `home/.claude/CLAUDE.md` / `home/.codex/AGENTS.md` / Cursor rules by hand — those come from sync protocols. Only edit hand-authored sources if a one-line cross-ref is wrong; run `home/sync/sync` only if a source that feeds generators must change (not expected for this pass).

**KEYBINDS / ALIASES**

- Update coding-agent framing only; leave Neovim bind tables intact (nvim config stays out of scope).

### 4. Codex / Cursor trees

- No structural deletes under `home/.cursor` or `home/.codex`.
- Soft-demote is prose + mental model only.

### 5. Validation

- Diff review: shell + settings + docs.
- Grep root docs for stale personal-Cursor / “Claude vs Cursor” launcher framing.
- Verify stub link target after SESSION-COST fold.
- Do not require full machine_setup or nvim smoke this round.

## Non-goals

- Changing `coding_agent_resolve.sh` defaults (already Codex for personal).
- Removing Cursor Agent CLI, Antigravity (`agy`), or their sync paths.
- Merging `CONTEXT.md` into `WORKFLOWS.md` (glossary path is load-bearing for skills).
- Committing implementation in this design step (implementation follows a separate plan).

## Risks

- Stub vs full fold: inbound links must still resolve; stub keeps paths stable.
- Claude settings restore may surprise if `opus` was intentional globally — explicitly rejected in favor of HEAD model + keep Impeccable.
- Doc slim of `CLAUDE.md` must not remove git-identity or key WSL behaviors agents rely on.

## Implementation order (for the plan)

1. Shell PATH cleanup  
2. Claude settings sanitize  
3. Fold session-cost into WORKFLOWS + stub  
4. Slim CLAUDE.md + update README / CONTEXT / WORKFLOWS / ALIASES / KEYBINDS framing  
5. Grep + link check  
6. Land via normal commit flow when asked  
