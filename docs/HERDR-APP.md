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
`~/.config/herdr-app/` and copies the owned sidebar, tab bar, and PR panel
resources below.
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
- `mods/dotfiles-tabs/main.js`, `mod.json`, and `win-*.svg`
- `mods/dotfiles-prs/main.js`, `prs.js`, `mod.json`, and `pr.svg`
- `layouts/dotfiles-main.json`

The custom layout is a snapshot of the shipped main layout. Its spaces block
uses the grouped sidebar mod, its tab bar uses the owned tab bar clone, and its
side panel stack has a third `prs` child. Agents, menus, pane headers, files,
changes, and window chrome continue to use the shipped mods. The custom mods
have `place: "none"`, so installation does not dock another sidebar.

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
for mod in dotfiles-spaces dotfiles-tabs dotfiles-prs; do
  HERDR_APP_HOME="$stage" herdr-app check "$stage/mods/$mod"
done
```

The native check validates loading and an initial render, not painting,
remote asynchronous states, or later interactions. After authorized activation,
inspect expanded and narrow sidebars, local and remote spaces, owner folds and
restore, worktrees, menus, drag behavior, and numeric selection. Adapter tests
execute fold callbacks and verify per-machine visibility and saved state.
Visual and live-interaction checks have not been performed as part of the
non-activating implementation.

## Pull requests panel

The owned tab bar adds a **PRs** button beside Files and Changes. It opens the
`dotfiles-prs` panel for the shown space's repository, resolved like Changes
from the focused pane's folder (remote spaces run `gh` on their machine). The
panel needs the GitHub CLI (`gh`) signed in; without it, or outside a GitHub
repository, it shows the error instead of a list.

The top list shows the open pull requests (up to 50): number, title, a `draft`
chip, a `review` chip when you or one of your teams is asked to review, else
the review decision (`Approved`, `Changes`, `Review`), a checks dot (green ok,
yellow pending, red failed), and age. The checkout's own PR comes first, then
ones waiting on you, then yours, newest first. The header counts how many wait
on you. The list refreshes every minute and on the refresh button.

Picking a PR loads its review details through GraphQL:

- **Pending review**: your own unsubmitted review, with its summary and draft
  comments. Nobody else can see it until it is submitted. Approve, Comment, or
  Request changes submit it (the message bar becomes its summary); Discard
  deletes it. Without a pending review, the same buttons create and submit a
  review directly; Comment then needs a message.
- **Threads**: review threads, open ones first, with path, line, author, and
  the first comment stripped of bot markup. Click a thread to select it; the
  bar then offers Reply (message required), Resolve or Unresolve, and Back.
- **Reviews** and **Checks**: the latest review per reviewer, and check counts
  with failing check names.

Every outward-facing action (submit, discard, reply, resolve, checkout, merge)
arms first: the bar shows the question with Confirm and Cancel, and nothing is
sent until Confirm is clicked. Open shows the PR in the browser through `gh pr
view --web`. Checkout runs `gh pr checkout` in the space's checkout.

**Merge** runs `gh pr merge --<method> --match-head-commit <sha>` with the head
the panel last showed, so a push that lands in between fails the merge instead
of merging unseen commits. The armed row offers Squash (default), Merge, and
Rebase. The button is disabled for drafts, conflicting PRs, and unknown heads;
branch protection, required checks, and approvals are enforced by GitHub, and a
refusal is shown as the error text. The detail header shows GitHub's merge
state (`clean`, `blocked`, `behind`, `dirty`, ...) and the list marks
conflicting PRs. Editing PR metadata and starting a pending review are not
offered; use `gh` or the browser for those.

Verification so far: `herdr-app check` passes for both owned mods, the helper
module has node tests (`tests/test_herdr_app_prs.mjs`) covering row flags,
sorting, detail parsing, and the exact `gh` arguments of every action including the guarded merge, and the
list, detail, and pending-review states were inspected live with `herdr-app
shot` against a temporary private pending review on a personal PR. The submit,
discard, reply, resolve, checkout, and merge clicks were not exercised in the
app; only their `gh` argument construction is tested.

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
The app applies preference files live. The owned clones do not receive
upstream sidebar or tab bar fixes automatically. Their baselines and refresh
procedure are recorded in [Grouped sidebar source](../home/herdr-app/PROVENANCE.md).

Legacy shell aliases, Herdr launch scripts, and Neovim's `herdr-navigator`
still use old `herdr`, not `hc` or the native app. These preferences do not
migrate those integrations, transfer sessions, or restore live layouts.

## Sub-agents in the Agents list

Pi delegates through `hc run --bg` with the `worker` and `reviewer` templates
from `home/.config/herdr-core/templates/` (see [`PI.md`](PI.md)). herdr-core
records the starting terminal as each child's parent, so the shipped Agents
mod nests them under the parent agent, where they can be peeked at, kept as a
pane, or attached to.
