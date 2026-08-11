# Pane context is per-pane, not session-scoped

Status: accepted

Herdr UI chrome (sidebar `$aws` / `$wt` tokens, display-agent, titles) mirrors
**pane context** — signals owned by a single herdr pane (AWS profile, worktree
label, resolved coding agent). The **pane-context reporter** mirrors into the
herdr host via `report-metadata` `--token` (not custom `--state-label` names —
herdr rejects those). Display adapters are native `[ui.sidebar.*]` rows and
launch-time titles — not a custom status bar (tmux→herdr native-first spec).

**Lifetime:** per pane. Rejected session-scoped and workspace-scoped AWS
inheritance — a profile belongs to the pane that selected it.

**Persistence:** a **pane-keyed** side file (`…/aws_profile_${HERDR_PANE_ID}`)
is allowed as a bridge when we cannot `export` into an agent TUI. Rejected the
old **session-keyed** file (`…/aws_profile_${HERDR_SESSION}`) and any restore
onto *new* panes.

**`awsp`:** popup picker applies to the **focused** pane; in-pane `awsp` applies
to the calling pane. Both write the pane file, export when the target is a
plain shell, and report `$aws`.

**Agent shells:** Claude and Cursor hooks parse `--profile` /
`AWS_PROFILE=` / `export AWS_PROFILE=` on command **completion (any exit
code)**, update the pane file + `$aws`, and on later aws/terraform-ish commands
**pre-inject** `AWS_PROFILE` when the command has no explicit profile (so we
never `send-text` into the agent prompt).

## Considered options (lifetime)

- Per pane (chosen)
- Per herdr session — inaccurate across panes
- Per workspace — follows repo, not the process

## Consequences

- Soft seam for now: gated p10k AWS; agent TUI statuslines unchanged.
- Clearing profile (`awsu`) clears the pane file, chrome tokens, and stops
  pre-inject.
