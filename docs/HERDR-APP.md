# Native Herdr app preferences

The native `herdr-app` window uses herdr-core (`hc`). It is separate from
legacy `herdr` and its configuration in `home/.config/herdr/`.

## Apply preferences

After the dotfiles resources are linked into your home, run:

```sh
python3 "$HOME/setup_herdr_app.py"
```

The `dotfiles` task runs this command on install and update. The installer
resolves its resources beside the real script, so a symlinked script works.
It merges `home/herdr-app/settings.json` and `home/herdr-app/keys.json` into
`~/.config/herdr-app/`. `HERDR_APP_HOME` overrides the destination.

The installer manages only these preferences:

- `settings.json` sets `sounds.enabled` to `false` and `appearance` to `"dark"`.
- `keys.json` binds global `ctrl-1` through `ctrl-9` to `space.select:1`
  through `space.select:9`.

Existing fonts, other sound settings, and unrelated keys stay intact.
Existing Alt+1 through Alt+9 space bindings stay intact too. Both shortcuts
can select the same spaces. Ctrl+digits no longer reach the terminal when
these global bindings apply. A more specific terminal, layout, or mod binding
can override a global binding.

The installer validates both files before writing either. Invalid JSON,
non-object roots, and non-object managed sections cause an error without
resetting preferences. It refuses symlinked preference files. Changed files
get an adjacent `<name>.backup-<unique suffix>` copy before atomic replacement.
Unchanged files keep their contents and modification times. Backups remain
until you remove them.

## Limits

Only the two preference files are merged. The app config directory is never
symlinked. App-owned state, shipped mods, layouts, and layout click state are
outside this setup's scope. The app applies preference files live.

Legacy shell aliases, Herdr launch scripts, and Neovim's `herdr-navigator`
still use old `herdr`, not `hc` or the native app. These preferences do not
migrate those integrations, transfer sessions, or restore live layouts.
