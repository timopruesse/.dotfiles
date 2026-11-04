# Grouped sidebar source

`mods/dotfiles-spaces/` and `layouts/dotfiles-main.json` are owned snapshots
of the native Herdr app 0.1.7 resources. They were copied from the installed
`mods/spaces/` and `layouts/main.json`, not cloned through the live app.
The source app reported `herdr-app 0.1.7`.

The original SHA-256 hashes are:

| Shipped file | SHA-256 |
| --- | --- |
| `mods/spaces/main.js` | `f97d3b89741ad270b5927a3ed1f8310a08be95053152a491f8c40fa87acaa1e2` |
| `mods/spaces/mod.json` | `8357ce89d375376872b6db414b9555b26936b2e9d61e44275dc2e2bfe2a5783e` |
| `layouts/main.json` | `b4438dafcf1aa379b0d08b62a97af37b31bb63b9ff9e5537d1848a8f221bea7f` |

`mods/dotfiles-tabs/` is an owned snapshot of the shipped `mods/tabs/` from
herdr-app 0.1.12 (`main.js`, `mod.json`, and the four `win-*.svg` icons):

| Shipped file | SHA-256 |
| --- | --- |
| `mods/tabs/main.js` | `12d4ecc89dbf864d5a889f240adaea25590812e0be1835bbdb3e636fe14f51d3` |
| `mods/tabs/mod.json` | `bd2a09edf56933dd318e75ce134b2c48aed56010b825f3c936f92a995e686c4d` |
| `mods/tabs/win-close.svg` | `bc46f314ea68818459856618e10f694e53cccd947b3069286f1988927e8a1fac` |
| `mods/tabs/win-max.svg` | `d8f2df2b1c3b3416ab765be0ad0b6f453f4c89e0c01ac01e4e10bd12e01b109a` |
| `mods/tabs/win-min.svg` | `c2f8d7d1e117f99b73970816877a926becb3da102cd706fd0f0ce1780259cd52` |
| `mods/tabs/win-restore.svg` | `69ccde33c78d83ce39972ef129e158dd09fb19d3002bd709047801802fbad51d` |

Its only changes are the header comment, its own `win-*.svg` asset paths, an
always-offered `prs` panel, and the PRs button beside Files and Changes.

`mods/dotfiles-agents/` is an owned snapshot of the shipped `mods/agents/`
from herdr-app 0.1.12 (`main.js` and `mod.json`):

| Shipped file | SHA-256 |
| --- | --- |
| `mods/agents/main.js` | `8fd808ca158ac3a6861de0177ce5d07ef789c53ee5e9f827f1135f7bee27fb0d` |
| `mods/agents/mod.json` | `9990dc9eb8ac4c956f1d6f49ff1bf1691dc7eae7a38865c82ef5b9b229839a20` |

Its only changes are the header comment, the `nextCommand` import and loop
in `init`, a `command()` method that maps `focus1` .. `focus9` to
`pane.focus` on the nth drawn top-level agent, `this.order` recorded beside
`setAgentOrder` in `render`, and the sort menu overlay opening
`dotfiles-agents` instead of `agents`. The layout's agents block points at it.
`mods/dotfiles-prs/` is original code modeled on the shipped `changes` mod,
not a clone of it.

The layout changes are clone provenance, the spaces, agents, and tabs mod
references, and a third `prs` child in the `panel-body` stack. The
mod retains shipped Git refresh, machine state, worktree nesting, rows,
menus, dragging, compact numbering, and shared colors. Its additions are
`grouping.js`, row location fields, and collapsible owner section rendering.
Owner folds persist as machine-owner pairs under `owners.folded`, separate
from `machines.folded`. Invalid saved owner-fold JSON or root types default
to open sections, and invalid array entries are ignored. Owner headings use
the shipped chevrons and retain clickable P, W, and O labels in compact mode.
The mod also handles malformed saved machine-fold state and uses an explicit
if/else in the machine fold callback. Generated types and editor configuration
are not vendored. Shared icons and overlays still come from shipped mods.

## Design selection

Two read-only architect candidates explored a vendored clone and an
installer-generated clone. An independent read-only cross-judge preferred
the vendored clone. The implementation follows that choice.

A vendored clone installs before the app's first launch and makes the final
runtime code directly reviewable. A generator would need pinned installed
source hashes, transformation anchors, and compatibility fixtures. It
would still need maintenance whenever the shipped source changes. The
vendored clone accepts manual upstream reconciliation instead of adding a
source-rewriting installer.

The useful part retained from the generator proposal is explicit source
provenance. Hashes document the baseline; they do not gate installation.
The installer owns an explicit list of four resource files and backs up
changed copies. It does not mirror directories or own app state.

## Refresh the snapshot

Compare the installed shipped resources with these hashes after app
updates. Review changes to the shipped spaces, agents, and tabs mods and the main
layout, then port relevant upstream fixes into the owned snapshots. Keep local changes
at the owner-group rendering boundary. Update the hashes and clone version
after reviewing a new baseline.

The adapter tests execute owner and machine fold callbacks, check independent
visibility and original indices, and restore saved folds through the actual
mod initializer. They also cover malformed owner-fold storage.

Run the Python installer tests and both JavaScript test files listed in
[Native Herdr app preferences](../../docs/HERDR-APP.md). Install into a
temporary app home and run `herdr-app check` there. A passing check does
not verify painting or later interactions. Review the actual sidebar after
explicit activation before calling a new baseline visually verified.
