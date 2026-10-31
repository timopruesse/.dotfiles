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
`~/.config/herdr-app/` and copies the four owned sidebar resources below.
`HERDR_APP_HOME` overrides the destination. It never selects a layout.

The installer manages these preferences:

- `settings.json` sets `sounds.enabled` to `false` and `appearance` to `"dark"`.
- `keys.json` binds global `ctrl-1` through `ctrl-9` to `space.select:1`
  through `space.select:9`.

Existing fonts, other sound settings, and unrelated keys stay intact.
Existing Alt+1 through Alt+9 space bindings stay intact too. Both shortcuts
can select the same spaces. Ctrl+digits no longer reach the terminal when
these global bindings apply. A more specific terminal, layout, or mod binding
can override a global binding.

The installer preflights preferences and owned resources before writing.
Invalid JSON, non-object roots, non-object managed preference sections,
empty resources, and non-file destinations cause an error without writes.
It refuses symlinked managed files and directory ancestors, including dangling
symlinks. JavaScript syntax is checked separately with `herdr-app check`.
Changed files get an adjacent `<name>.backup-<unique suffix>` copy before
atomic replacement. Unchanged files keep their contents and modification
times. Backups remain until you remove them. Replacement is atomic per file,
not across the whole install. Rerun setup after an interrupted install.

## Activate Personal and Work grouping

The installer copies only these owned resources:

- `mods/dotfiles-spaces/main.js`
- `mods/dotfiles-spaces/grouping.js`
- `mods/dotfiles-spaces/mod.json`
- `layouts/dotfiles-main.json`

The custom layout is a snapshot of the shipped main layout. Only its spaces
block uses the custom mod. Agents, tabs, menus, pane headers, files, changes,
and window chrome continue to use the shipped mods. The custom mod has
`place: "none"`, so installation does not dock another sidebar.

After installing, check the mod and explicitly select the custom layout:

```sh
herdr-app check "$HOME/.config/herdr-app/mods/dotfiles-spaces"
herdr-app do layout.switch '{"name":"dotfiles-main"}'
```

Use the corresponding path and environment if you set `HERDR_APP_HOME`.
To return to the shipped layout, run:

```sh
herdr-app do layout.switch '{"name":"main"}'
```

Within each machine, nonempty sections appear in this order:

1. Personal matches `github/timopruesse/<repo>` path components.
2. Work matches `github/chewielabs/<repo>` path components.
3. Other contains every unmatched space.

The ordered registry is `mods/dotfiles-spaces/grouping.js`. Matching uses
complete, case-sensitive components, not the space name or Git identity.
Paths such as `~/github/timopruesse/repo` match, but `chewielabs-extra` does
not match Work. Absolute paths can have any home prefix, including remote
homes. No remote machine assumes `/home/timo`. Backslashes are normalized
for classification; other Git behavior retains the shipped implementation.

Classification prefers the known Git common directory. This lets a
worktree under `~/.herdr/worktrees/` inherit its checkout's owner, even
without a visible main-checkout space. Before Git information arrives, the
first live pane cwd is used, falling back to the space's creation folder.
A displayed checkout and its nested worktrees stay together. Other remains
visible when Git fails or no rule matches. Repository remote URLs are not
queried. Repositories outside the path convention generally appear in Other.

Click a Personal, Work, or Other heading to fold its rows. Each machine keeps
its own owner folds. The app saves them in localStorage under `owners.folded`,
separate from `machines.folded`. Invalid saved JSON or a non-array root opens
all owner sections; invalid entries in an array are ignored. Folding a machine
does not reset its owner folds.

Existing selection, context menus, Git details, machine folding, loading,
new-space controls, and worktree rows remain. Narrow sidebars show clickable P,
W, and O headings. Owner headings use the shipped open and closed chevrons.
Compact row numbers and Ctrl+digit bindings keep the app's global
space indices. Presentation order can differ from numeric shortcut order.
Dragging keeps the shipped move action and cannot change a space's owner;
a cross-section move still renders under its classified section.

Installation does not switch the live layout, modify selection state, or
start/restart the app or core. Once this layout is selected, later setup runs
can hot-reload changed owned resources. Local edits to these four installed
files are backed up and replaced. Edit the dotfiles sources to keep changes.
Unlisted files inside the custom mod directory remain untouched.

## Verify without activating

Run the focused tests from the repository root. Node is needed only for tests,
not by the mod at runtime.

```sh
python3 -m unittest discover -s tests -p 'test_herdr_app_setup.py' -v
node --test tests/test_herdr_app_*.mjs
stage=$(mktemp -d)
HERDR_APP_HOME="$stage" python3 home/setup_herdr_app.py
HERDR_APP_HOME="$stage" herdr-app check "$stage/mods/dotfiles-spaces"
```

The native check validates loading and an initial render, not painting,
remote asynchronous states, or later interactions. After authorized activation,
inspect expanded and narrow sidebars, local and remote spaces, owner folds and
restore, worktrees, menus, drag behavior, and numeric selection. Adapter tests
execute fold callbacks and verify per-machine visibility and saved state.
Visual and live-interaction checks have not been performed as part of the
non-activating implementation.

## Open WSL desktop web links in Windows

After linking the dotfiles, register the Windows browser bridge:

```sh
python3 "$HOME/setup_wsl_browser.py"
```

The `dotfiles` task runs this installer on install and update. Outside WSL,
it does nothing. In WSL, it writes `dotfiles-wsl-browser.desktop` under
`${XDG_DATA_HOME:-$HOME/.local/share}/applications` and sets the HTTP and HTTPS
defaults with `xdg-mime`. GIO also recognizes these defaults without
`update-desktop-database`.

The installer symlinks `~/.local/bin/dotfiles-wsl-browser` to the executable
bridge. The desktop entry uses `Exec=dotfiles-wsl-browser %u` because generic
`xdg-open` does not handle quoted executable arguments like GIO does. The symlink
keeps checkout paths with spaces or `%` out of `Exec`. GUI applications need
`~/.local/bin` on their `PATH`. Repeated installs keep the correct symlink,
replace stale symlinks, and refuse to overwrite an unrelated regular file.

This covers Linux GUI applications that use desktop URI associations, including
native Herdr app links. Applications with their own browser settings can bypass
these defaults. Local HTML, PDF, and `file:` associations stay unchanged. The
existing `home/.config/zsh/wsl_browser.py` bridge selects the Windows default
browser; this installer does not change its routing or launch a browser.

## Limits

The app config directory is never symlinked. App-owned state, shipped mods,
shipped layouts, and layout click state remain outside this setup's scope.
The app applies preference files live. The owned clone does not receive
upstream sidebar fixes automatically. Its baseline and refresh procedure are
recorded in [Grouped sidebar source](../home/herdr-app/PROVENANCE.md).

Legacy shell aliases, Herdr launch scripts, and Neovim's `herdr-navigator`
still use old `herdr`, not `hc` or the native app. These preferences do not
migrate those integrations, transfer sessions, or restore live layouts.
