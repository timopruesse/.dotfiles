# Native Herdr app preferences

The native `herdr-app` window uses herdr-core (`hc`). It is the default Herdr
in these dotfiles; the legacy `herdr` TUI and its configuration in
`home/.config/herdr/` are the fallback. New behaviour (keys, layout, sidebar,
panels, agent handling) is built and verified here first and mirrored into the
TUI config only where the TUI offers the same feature.

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
  through `space.select:9`, and global `alt-1` through `alt-9` to
  `dotfiles-agents.focus1` through `dotfiles-agents.focus9`.

Existing fonts, other sound settings, and unrelated keys stay intact.
The app ships Alt+1 through Alt+9 as space bindings; the installer replaces
them, so Ctrl+digits select spaces and Alt+digits select agents, as in the
TUI. Alt+digits only act while the `dotfiles-main` layout shows the owned
agents mod; on the shipped layout they do nothing. Ctrl+digits and
Alt+digits no longer reach the terminal when these global bindings apply.
A more specific terminal, layout, or mod binding can override a global
binding.

Alt+n shows the nth top-level agent in the order the agents list draws it:
pinned agents first, then the chosen sort (priority or grouped by space).
That is the number the narrow rail prints beside each row. Sub-agents are
not counted. The key does what clicking the row does (`pane.focus`), so it
also switches to the agent's space and tab.

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

- `mods/dotfiles-agents/main.js` and `mod.json`
- `mods/dotfiles-spaces/main.js`
- `mods/dotfiles-spaces/grouping.js`
- `mods/dotfiles-spaces/mod.json`
- `mods/dotfiles-tabs/main.js`, `mod.json`, and `win-*.svg`
- `mods/dotfiles-prs/main.js`, `prs.js`, `mod.json`, and `pr.svg`
- `mods/dotfiles-outputs/main.js`, `outputs.js`, `mod.json`, and `outputs.svg`
- `layouts/dotfiles-main.json`

The custom layout is a snapshot of the shipped main layout. Its spaces block
uses the grouped sidebar mod, its agents block uses the owned agents clone
(the shipped list plus the Alt+digit key commands), its tab bar uses the
owned tab bar clone, and its side panel stack has `prs` and `outputs` children
after Files and Changes.
Menus, pane headers, files, changes, and window chrome continue to use the
shipped mods. The custom mods
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
for mod in dotfiles-agents dotfiles-spaces dotfiles-tabs dotfiles-prs dotfiles-outputs; do
  HERDR_APP_HOME="$stage" herdr-app check "$stage/mods/$mod"
done
```

The native check validates loading and an initial render, not painting,
remote asynchronous states, or later interactions. The agents clone has node
tests (`tests/test_herdr_app_agents.mjs`) that render the actual list and
check that `focus<n>` picks the nth drawn agent in both sorts, before the
first render, and through the `nextCommand()` loop. After authorized activation,
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
chip, an `unsent review` chip when you have a pending review on it, a `review`
chip when you or one of your teams is asked to review, else the review decision
(`Approved`, `Changes`, `Review`), a checks dot (green ok, yellow pending, red
failed), and age. The checkout's own PR comes first, then ones waiting on you
(a review request, or a review you started and have not sent), then yours,
newest first. The header counts how many wait on you and how many carry an
unsent review; the unsent ones come from one GraphQL query per list refresh.
The list refreshes every minute and on the refresh button.

The panel keeps one record per repository and machine: the list, the picked
PR, its details, its diff, and the unsent message. Moving the focus to another
agent, tab, or space switches records instead of clearing the panel, so a
repository seen before comes back as it was, at once, and refreshes behind its
rows when its list is older than 20 seconds. Worktrees of one repository share
a record; actions still run in the shown checkout. A folder is resolved to its
checkout root and repository once; the loader shows only for a repository that
was never listed. Errors (no git repository, no GitHub remote) are not
remembered, so the next timer tick or refresh click asks again.

Picking a PR shows its header (title, author, branches, merge state, counts),
the **Review** / **Files** switch, and the buttons `nvim`, `Open`, `Checkout`,
and `Merge`. Review details load through GraphQL:

- **Pending review**: your own unsubmitted review, with its summary and draft
  comments. Nobody else can see it until it is submitted. Approve, Comment, or
  Request changes submit it (the message box becomes its summary); Discard
  deletes it. Without a pending review, the same buttons create and submit a
  review directly; Comment then needs a message. Click a draft comment to see
  its line in Files.
- **Threads**: review threads, open ones first, with path, line, author, and
  the first comment stripped of bot markup. Click a thread to select it; the
  bar then offers Reply (message required), Resolve or Unresolve, Show diff
  (the thread's line in Files), and Back.
- **Reviews** and **Checks**: the latest review per reviewer, and check counts
  with failing check names.

**Files** lists the PR's changed files from `gh pr diff` (status `A`, `D`,
`R`, `M`, counts, and chips for your drafts and open threads on the file) and
shows the picked file's diff below: numbered lines with the side GitHub
comments on (deletions are old-file lines, additions and context new-file
lines), `draft` chips on lines with a draft comment of yours (GraphQL gives a
draft no side, so one on an old-file line is marked on the new-file line of the
same number), and a count chip
on lines with threads. Click a line to comment on it: the bar shows the line
and any draft or thread already there, and **Add to review** puts the message
box's text on that line as a draft comment. The first draft starts a pending
review on the PR's head commit through `addPullRequestReview` with no event;
later ones join it through `addPullRequestReviewThread`. **Delete draft**
removes the line's draft comment. Draft comments are private until the review
is submitted from Review, so they need no confirmation. The diff is fetched
once per PR head and dropped when the list shows new commits; files over 4,000
diff lines are cut with a note, and a diff GitHub refuses (too many files or
lines) shows its error. The message box is multi-line and grows up to six
rows.

**nvim** walks the PR in Neovim without touching your branches or worktree: it
fetches `refs/pull/<n>/head` and the base branch from the remote whose fetch
URL names the repository (`origin` otherwise) into `refs/herdr/pr/<n>` and
`refs/herdr/base/<n>`, then runs `terminal.open` with
`nvim -c "DiffviewOpen refs/herdr/base/<n>...refs/herdr/pr/<n>"` in the
checkout, split to the right of the focused pane (a new tab when no pane is
focused). The dotfiles Neovim config includes diffview.nvim for this
(`<leader>gd`, `<leader>gD`, `<leader>gh`; see [`KEYBINDS.md`](../KEYBINDS.md)).
The refs stay until you delete them (`git update-ref -d refs/herdr/pr/<n>`).

The mod takes commands for keys.json or `herdr-app do`: `dotfiles-prs.review`,
`dotfiles-prs.files`, `dotfiles-prs.nvim`, and `dotfiles-prs.refresh`.

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
conflicting PRs. Editing PR metadata, multi-line (range) comments, suggestions,
and editing a draft's text are not offered; use `gh` or the browser for those.

Verification so far: `herdr-app check` passes for the mod; the helper module
has node tests (`tests/test_herdr_app_prs.mjs`) covering row flags, sorting,
detail parsing, diff parsing and row numbering, line markers, and the exact
`gh` arguments of every action including draft comments, the guarded merge, and
the nvim refs; the rendered panel is tested for keeping its record across pane
switches, the Files view (diff fetched once per head, file list, lines, errors),
line comments into a new and an existing pending review, draft deletion,
revealing a thread's line, the nvim hand-off, the unsent-review badges, and the
mod commands. The submit, discard, reply, resolve, checkout, and merge clicks
were not exercised in the app; only their `gh` argument construction is tested.
The reworked panel was inspected live in the app on a repository without open
PRs (header, empty list, message box, and buttons render; a `"transparent"`
background the host rejects was found and fixed there). The Files view, line
comments, the unsent-review badges, and the nvim hand-off were not inspected
live; open the panel on a checkout with an open PR to see them.

## Outputs panel

The owned tab bar adds an **Outputs** button after PRs. It lists what the
focused pane's agent session wrote: files it created or edited and artifacts it
published, newest first, one row per path with how often it was touched. Click
a file for a read-only preview (the Files panel's reader); click an artifact to
open its `claude.ai` page through the system browser (the WSL bridge below).

The panel reads the session transcript named by the terminal's
`agent.transcript` label, with `agent.kind` (`claude` or `pi`) and
`agent.session` beside it. Two small hooks set those labels through `hc label`
on the terminal in `HC_TERMINAL_ID`, so they are exact per pane and survive
`clear` and resume:

- Claude Code: `~/.claude/hooks/hc-session-label.sh`, a `SessionStart` hook in
  `.claude/settings.json`. It ignores sub-agents and never fails the session.
- Pi: `~/.pi/agent/extensions/hc-session-label.ts`, linked by `setup_pi.py`,
  on `session_start` and `agent_start`. Sessions without a file
  (`pi --no-session`, the hc worker and reviewer templates) are skipped.

Outside an hc terminal nothing is labelled and the panel says so. The
transcript is narrowed with `grep` on the pane's machine before parsing, so
remote spaces work through the same `exec` path as Changes; transcripts on a
Windows host are not read yet. Claude Code rows come from the `Write`, `Edit`,
`MultiEdit`, and `NotebookEdit` tool records and from `Artifact` publish
results; Pi rows from its `write` and `edit` tool calls. Files changed through
shell commands (heredocs, `sed`) do not appear; Changes covers those inside
the repository.

Verification so far: `herdr-app check` passes for the mod, node tests
(`tests/test_herdr_app_outputs.mjs`) cover the label reader, the grep filter
against real-shaped transcript lines, the parser for both agents, and the
rendered panel (empty states, rows, preview click, artifact open, errors), and
`tests/test_hc_session_label.py` runs the Claude hook against a fake `hc`. The
panel was opened live with this checkout's own session labelled through the
hook and showed the Claude Code header with its empty state; a transcript with
rows was not inspected visually in the app.

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

## Render on the GPU in WSL

Ubuntu's Mesa packages ship no Vulkan-on-D3D12 driver, so the app's wgpu
renderer picks lavapipe, Mesa's CPU Vulkan device, under WSLg. Mesa's `d3d12`
OpenGL driver does reach the GPU, and wgpu falls back to OpenGL when Vulkan
exposes no device. `home/.config/zsh/wsl.zsh` defines a `herdr-app` shell
function that sets `VK_DRIVER_FILES=/nonexistent` and `GALLIUM_DRIVER=d3d12`
before the real binary, plus `EGL_LOG_LEVEL=fatal` and `MESA_LOG=null` to
silence Mesa's harmless EGL probe warnings at startup. The `zbus::proxy`
warnings about `org.freedesktop.portal.Desktop` remain: they come from the
missing xdg-desktop-portal and the app's log filter ignores environment
variables.

Verified on 2026-11-12 (RTX 2080 Ti, Mesa 26.0.8): the window loads
`libd3d12core.so` and the NVIDIA D3D12 driver instead of `libvulkan_lvp.so`,
renders the same frame, and uses about a twentieth of the idle CPU. Only
shell launches go through the function; `command herdr-app` bypasses it.
Outside WSL the file returns early and nothing changes.

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
