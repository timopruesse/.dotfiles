# Shared slash-command sources

Edit command prompts here (`*.md`), plus protocols in `home/protocols/`, then run:

```bash
./home/commands/sync-commands
```

That regenerates:

- `home/.claude/commands/` — Claude Code (frontmatter + `$ARGUMENTS`)
- `home/.cursor/commands/` — Cursor (plain markdown + `$1`/`$2`/…)

and installs live symlinks into `~/.cursor/commands/`. Protocols are linked from
`home/protocols/` into `home/.claude/` and `home/.cursor/protocols/`.

Do **not** hand-edit the generated trees; they are overwritten on sync.
`machine_setup` runs the sync after `sync-agents`.
