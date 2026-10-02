# Dotfiles Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Moderate hygiene + doc consolidation: Codex-first personal framing, shell/Claude cleanup, fold session-cost into WORKFLOWS.

**Architecture:** Edit hand-authored sources only. Restore Claude settings from HEAD base + keep Impeccable. Fold SESSION-COST body into WORKFLOWS with stub. Slim CLAUDE.md; soft-demote Cursor in root docs.

**Tech Stack:** Shell configs, JSON settings, Markdown docs (no sync generator changes expected).

## Global Constraints

- Personal host = Codex; work = Claude; Cursor = override/secondary.
- Out of scope: nvim config, machine_setup.yaml, terminal/, deleting Cursor sync.
- Keep Impeccable; restore model `claude-fable-5-1[1m]` + git-config deny; drop `autoMode`.
- Do not hand-edit generated agent-routing trees.
- Commits only when the user asks (or parent-quota fallback for docs land).

---

### Task 1: Shell PATH hygiene

**Files:**
- Modify: `home/.zprofile` (remove trailing Antigravity block)
- Modify: `home/.zshrc` (remove trailing Antigravity block)

- [ ] **Step 1:** Delete from both files:

```
# Added by Antigravity CLI installer
export PATH="/home/timo/.local/bin:$PATH"
```

(and blank lines immediately above if they only existed for that block)

- [ ] **Step 2:** Verify

```bash
rg -n 'Antigravity|/home/timo/\.local/bin' home/.zprofile home/.zshrc
```

Expected: no matches. Intentional `$HOME/.local/bin` exports remain.

---

### Task 2: Sanitize Claude settings

**Files:**
- Modify: `home/.claude/settings.json`

- [ ] **Step 1:** Start from HEAD content; add Impeccable keep-list:

```json
"impeccable@impeccable": true
```

under `enabledPlugins`, and marketplace:

```json
"impeccable": {
  "source": {
    "source": "github",
    "repo": "pbakaus/impeccable"
  }
}
```

under `extraKnownMarketplaces`. Ensure `permissions.deny` git-config rules and `model: "claude-fable-5-1[1m]"` are present. Ensure `autoMode` is absent.

- [ ] **Step 2:** Validate JSON

```bash
python3 -c "import json; d=json.load(open('home/.claude/settings.json')); assert 'autoMode' not in d; assert d['model']=='claude-fable-5-1[1m]'; assert 'deny' in d['permissions']; assert d['enabledPlugins'].get('impeccable@impeccable') is True"
```

Expected: exit 0.

---

### Task 3: Fold session-cost into WORKFLOWS

**Files:**
- Modify: `WORKFLOWS.md` (append Telemetry section; fix header framing; repair truncated Herdr sentence)
- Modify: `SESSION-COST-LOGGING.md` → stub only

- [ ] **Step 1:** Update WORKFLOWS.md header launcher line to Codex-first (not “Claude vs Cursor by cwd”).
- [ ] **Step 2:** Append `## Telemetry / session cost` containing the former SESSION-COST body. Fix truncated Herdr paragraph to end with:

```markdown
[`home/sync/normalize-herdr-hooks`](home/sync/normalize-herdr-hooks) after
integration install (`machine_setup` does this automatically).
```

Anchor: use heading `## Telemetry / session cost` so stub can link `#telemetry--session-cost`.

- [ ] **Step 3:** Replace `SESSION-COST-LOGGING.md` with stub pointing to `WORKFLOWS.md#telemetry--session-cost`.

- [ ] **Step 4:** Update inbound pointer prose in `README.md`, `CONTEXT.md`, `CLAUDE.md`, `home/agents/README.md`, `home/protocols/README.md` to the WORKFLOWS anchor (stub may remain as alternate path).

---

### Task 4: Slim CLAUDE.md + framing pass

**Files:**
- Modify: `CLAUDE.md`, `README.md`, `CONTEXT.md`, `ALIASES.md`, `KEYBINDS.md`, `WORKFLOWS.md` (framing)

- [ ] **Step 1:** Slim `CLAUDE.md`: remove standalone Keybinds/Aliases/Workflows/Session-cost mirror sections; replace with one short “Where to read” list. Rename routing heading to reflect Codex personal default. Keep structure, git identity, key behaviors, short routing blurb.
- [ ] **Step 2:** README coding-agents line + index: Codex personal; Cursor secondary; session cost → WORKFLOWS telemetry.
- [ ] **Step 3:** CONTEXT “Where to read next” + any soft-demote touch on coding-agent resolve row if needed.
- [ ] **Step 4:** ALIASES/KEYBINDS: ensure personal default reads as Codex; Cursor as override (minimal wording).

---

### Task 5: Verification

- [ ] **Step 1:**

```bash
rg -n 'Claude vs Cursor by cwd|Antigravity CLI installer|autoMode|boba_fetch' \
  README.md CLAUDE.md CONTEXT.md ALIASES.md KEYBINDS.md WORKFLOWS.md \
  SESSION-COST-LOGGING.md home/.zprofile home/.zshrc home/.claude/settings.json
```

Expected: no stale launcher framing / installer blocks / autoMode / boba leak (design-spec mentions of boba OK under `docs/`).

- [ ] **Step 2:** Confirm stub and WORKFLOWS anchor exist; JSON still valid.
