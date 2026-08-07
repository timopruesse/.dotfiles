# Keybinds

---

## Herdr

Prefix key: **Ctrl+Space**

Config: `~/.config/herdr/config.toml` (from `home/.config/herdr/`).

### Session / tabs / panes

| Key | Action |
| --- | --- |
| `prefix c` | New tab |
| `prefix n` / `prefix p` | Next / previous tab (within the current space) |
| `prefix \` or `prefix v` | Vertical split (right) |
| `prefix -` | Horizontal split (down) |
| `prefix r` | Reload herdr config |
| `prefix Tab` | Toggle last pane (Neovim `<C-o>`-style back-and-forth) |
| `` prefix ` `` | Scratch popup terminal (75%×80%) |
| `prefix+shift+A` | AWS profile picker (`awsp` popup) |
| `prefix ?` | Show live keybind help |

### Spaces / agents

Herdr calls spaces **workspaces**. `next_agent` / `previous_agent` stay unset —
jump agents via goto / sidebar.

| Key | Action |
| --- | --- |
| `prefix (` / `prefix )` | Previous / next space |
| `prefix w` | Space picker (go to / switch space) |
| `prefix+shift+N` | New space |
| `prefix g` / `prefix C` | Goto picker (spaces / agents / panes) — also the jump-to-agent path |
| `prefix a` | Toggle agent/space sidebar |

Agent status lives in herdr’s native sidebar (install integrations with
`herdr integration install claude` / `cursor`). No custom harpoon or fzf picker.

### Coding-agent launch

| Key | Action |
| --- | --- |
| `prefix+shift+S` | Coding agent resume (new tab; Claude vs Cursor by cwd) |
| `prefix+shift+R` | Coding agent continue (new tab) |
| `prefix+shift+H` | Coding agent in vertical split |
| `prefix+shift+V` | Coding agent in horizontal split |

Launch binds resolve Claude Code vs Cursor Agent via
`~/.config/herdr/scripts/coding_agent_resolve.sh` /
`coding_agent_launch.sh` (env → git remote org → path: chewielabs → Claude;
otherwise Cursor). Override with `CODING_AGENT=claude|agent`. These binds exec
the CLI directly (no zsh worktree wrapper); use shell `c`/`ch`/… when you want
default `--worktree` / `-w`.

### Pane navigation

Seamless across herdr panes **and** nvim splits via
`willfish/herdr-navigator` (+ `herdr-navigator.nvim`): if the active pane runs
(n)vim the key moves nvim splits first; at an edge it focuses the adjacent
herdr pane.

| Key | Action |
| --- | --- |
| `Alt+h` | Select pane / nvim split left |
| `Alt+j` | Select pane / nvim split down |
| `Alt+k` | Select pane / nvim split up |
| `Alt+l` | Select pane / nvim split right |

### Notes

- Mouse-first UI (click panes/tabs, drag borders, right-click menus)
- Detach with `prefix q`; reattach with `herdr`
- Session restore is built into herdr (detach keeps processes; server restart
  restores layout + native agent resume when integrations are installed)

---

## Neovim

Leader key: **Space**

### General

| Key          | Mode           | Action                                 |
| ------------ | -------------- | -------------------------------------- |
| `<C-s>`      | Normal         | Save file                              |
| `Q`          | Normal         | Disabled (no-op)                       |
| `j`          | Normal         | Move down + center screen              |
| `k`          | Normal         | Move up + center screen                |
| `<Down>`     | Normal         | Move down + center screen              |
| `<Up>`       | Normal         | Move up + center screen                |
| `Y`          | Normal         | Yank to end of line                    |
| `<leader>p`  | Normal, Visual | Paste without overwriting register     |
| `<leader>d`  | Normal, Visual | Delete to blackhole register           |
| `<leader>yy` | Normal, Visual | Copy to system clipboard               |
| `<leader>pp` | Normal, Visual | Paste from system clipboard            |
| `<leader>Y`  | Normal         | Copy entire buffer to system clipboard |

#### Undo Breakpoints (Insert Mode)

| Key | Action              |
| --- | ------------------- |
| `,` | Break undo sequence |
| `.` | Break undo sequence |
| `!` | Break undo sequence |
| `?` | Break undo sequence |
| `=` | Break undo sequence |

#### German Umlauts (Insert Mode)

| Key     | Output |
| ------- | ------ |
| `<M-a>` | ä      |
| `<M-o>` | ö      |
| `<M-u>` | ü      |

### Navigation

#### Split Navigation

`<M-h/j/k/l>` navigate nvim splits and **cross seamlessly into adjacent herdr
panes** at the edges (`herdr-navigator.nvim`).

| Key         | Mode   | Action                  |
| ----------- | ------ | ----------------------- |
| `<M-h>`     | Normal | Navigate left (split or herdr pane)  |
| `<M-j>`     | Normal | Navigate down (split or herdr pane)  |
| `<M-k>`     | Normal | Navigate up (split or herdr pane)    |
| `<M-l>`     | Normal | Navigate right (split or herdr pane) |
| `<C-Left>`  | Normal | Navigate to left split  |
| `<C-Down>`  | Normal | Navigate to below split |
| `<C-Up>`    | Normal | Navigate to above split |
| `<C-Right>` | Normal | Navigate to right split |

#### Split Management

| Key          | Mode   | Action                            |
| ------------ | ------ | --------------------------------- |
| `<M-v>`      | Normal | Vertical split                    |
| `<M-d>`      | Normal | Horizontal split                  |
| `<M-q>`      | Normal | Close current split               |
| `<C-x>`      | Normal | Close all splits except current   |
| `<leader>nv` | Normal | Scratch pad in vertical split     |
| `<leader>nh` | Normal | Scratch pad in horizontal split   |
| `<leader>np` | Normal | Promote scratch to file and save  |

#### Window Resizing

| Key       | Mode   | Action              |
| --------- | ------ | ------------------- |
| `<C-M-H>` | Normal | Resize window left  |
| `<C-M-L>` | Normal | Resize window right |
| `<C-M-K>` | Normal | Resize window up    |
| `<C-M-J>` | Normal | Resize window down  |

#### Buffer Navigation

| Key          | Mode   | Action          |
| ------------ | ------ | --------------- |
| `<leader>bn` | Normal | Next buffer     |
| `<leader>bp` | Normal | Previous buffer |
| `<leader>bf` | Normal | First buffer    |
| `<leader>bl` | Normal | Last buffer     |

#### Insert Mode Movement

| Key     | Action            |
| ------- | ----------------- |
| `<M-h>` | Move left         |
| `<M-j>` | Move down         |
| `<M-k>` | Move up           |
| `<M-l>` | Move right        |
| `<M-f>` | Forward one word  |
| `<M-b>` | Backward one word |

### Harpoon (Quick File Navigation)

| Key         | Mode   | Action                     |
| ----------- | ------ | -------------------------- |
| `<leader>a` | Normal | Add file to harpoon        |
| `<C-e>`     | Normal | Toggle harpoon quick menu  |
| `<C-h>`     | Normal | Navigate to harpoon file 1 |
| `<C-j>`     | Normal | Navigate to harpoon file 2 |
| `<C-k>`     | Normal | Navigate to harpoon file 3 |
| `<C-l>`     | Normal | Navigate to harpoon file 4 |

### Telescope (Search & Find)

| Key           | Mode   | Action                           |
| ------------- | ------ | -------------------------------- |
| `<C-p>`       | Normal | Find project files               |
| `<leader>pl`  | Normal | Live grep                        |
| `<leader>ps`  | Normal | Grep string under cursor         |
| `<leader>pb`  | Normal | Search buffers                   |
| `<leader>qf`  | Normal | Quickfix list                    |
| `<leader>ll`  | Normal | Location list                    |
| `<leader>jl`  | Normal | Jump list                        |
| `<leader>rl`  | Normal | Registers                        |
| `<leader>ds`  | Normal | LSP document symbols             |
| `<leader>ws`  | Normal | LSP workspace symbols            |
| `<leader>ts`  | Normal | Treesitter symbols               |
| `<leader>dg`  | Normal | Diagnostics                      |
| `<leader>rf`  | Normal | LSP references                   |
| `<leader>vrc` | Normal | Search dotfiles                  |
| `<leader>gb`  | Normal | Git branches                     |
| `<leader>cl`  | Normal | Git commits                      |
| `<leader>cc`  | Normal | Git buffer commits               |
| `<leader>re`  | Visual | Refactoring options              |
| `<C-q>`       | Normal | File browser                     |
| `<leader>tf`  | Normal | File browser (current directory) |

#### Inside Telescope Picker

| Key     | Mode           | Action                               |
| ------- | -------------- | ------------------------------------ |
| `<C-f>` | Insert         | Send all to quickfix                 |
| `<M-f>` | Insert         | Send selected to quickfix            |
| `<C-h>` | Insert         | Show which_key help                  |
| `<C-d>` | Insert, Normal | Delete git branch (in branch picker) |

### LSP (Buffer-Local)

| Key                | Mode           | Action                  |
| ------------------ | -------------- | ----------------------- |
| `<leader>vd`       | Normal         | Go to definition        |
| `<leader>vi`       | Normal         | Go to implementation    |
| `<leader>vrr`      | Normal         | Show references         |
| `<leader>vws`      | Normal         | Workspace symbol search |
| `<leader>vrn`      | Normal         | Rename symbol           |
| `<leader><leader>` | Normal, Visual | Code action             |
| `<leader>vh`       | Normal         | Hover documentation     |
| `<leader>vsh`      | Normal         | Signature help          |
| `<leader>ee`       | Normal         | Open diagnostic float   |
| `[d`               | Normal         | Previous diagnostic     |
| `]d`               | Normal         | Next diagnostic         |

### Completion (nvim-cmp)

| Key         | Mode   | Action               |
| ----------- | ------ | -------------------- |
| `<C-p>`     | Insert | Select previous item |
| `<C-n>`     | Insert | Select next item     |
| `<C-u>`     | Insert | Scroll docs up       |
| `<C-d>`     | Insert | Scroll docs down     |
| `<C-Space>` | Insert | Trigger completion   |
| `<CR>`      | Insert | Confirm selection    |
| `<C-x>`     | Insert | Abort completion     |

### Snippets (LuaSnip)

| Key          | Mode   | Action                 |
| ------------ | ------ | ---------------------- |
| `<C-k>`      | Insert | Expand or jump forward |
| `<C-j>`      | Insert | Jump backward          |
| `<C-l>`      | Insert | Change choice          |
| `<C-u>`      | Insert | Select choice          |
| `<leader>rs` | Normal | Reload snippets        |

### Formatting

| Key         | Mode   | Action                       |
| ----------- | ------ | ---------------------------- |
| `<leader>f` | Normal | Format buffer (conform.nvim) |

### Git

| Key          | Mode   | Action       |
| ------------ | ------ | ------------ |
| `<leader>gg` | Normal | Open LazyGit |

### Rust (Buffer-Local)

| Key          | Mode   | Action            |
| ------------ | ------ | ----------------- |
| `<leader>rr` | Normal | Rust runnables    |
| `<leader>tt` | Normal | Rust testables    |
| `<leader>rd` | Normal | Render diagnostic |
| `<C-Space>`  | Normal | Hover actions     |

### Node.js / TypeScript (Buffer-Local)

| Key          | Mode   | Action               |
| ------------ | ------ | -------------------- |
| `<leader>ta` | Normal | Toggle npm test all  |
| `<leader>tt` | Normal | Toggle npm test file |

### Package Info (package.json)

| Key          | Mode   | Action                 |
| ------------ | ------ | ---------------------- |
| `<leader>pu` | Normal | Update package         |
| `<leader>pd` | Normal | Delete package         |
| `<leader>pi` | Normal | Install package        |
| `<leader>pc` | Normal | Change package version |

### 99 (AI Agent — inline)

Provided by [ThePrimeagen/99](https://github.com/ThePrimeagen/99). Provider follows
the same cwd routing as coding-agent launchers (`ClaudeCodeProvider` for
chewielabs, `CursorAgentProvider` otherwise); re-syncs on `DirChanged`. Override
temporarily with `<leader>9p`.

| Key          | Mode   | Action                                          |
| ------------ | ------ | ----------------------------------------------- |
| `<leader>9v` | Visual | Send selection with prompt; replace with result |
| `<leader>9s` | Normal | Search the project with a prompt (quickfix)    |
| `<leader>9o` | Normal | Open last result (quickfix / tutorial window)   |
| `<leader>9x` | Normal | Stop all in-flight requests                     |
| `<leader>9c` | Normal | Clear previous requests                         |
| `<leader>9l` | Normal | View logs                                       |
| `<leader>9m` | Normal | Telescope: select model                         |
| `<leader>9p` | Normal | Telescope: select provider                      |

### Coding agent (Tmux Integration)

Same cwd routing as the shell aliases / herdr binds (env → remote org → path;
chewielabs → Claude Code, otherwise Cursor Agent). Keymaps are unchanged.

| Key          | Mode   | Action                                             |
| ------------ | ------ | -------------------------------------------------- |
| `<leader>zo` | Normal | Open coding agent in vertical herdr split           |
| `<leader>zh` | Normal | Open coding agent in horizontal herdr split         |
| `<leader>zw` | Normal | Open coding agent in new herdr tab                  |
| `<leader>zs` | Visual | Send selection to agent (new pane)                 |
| `<leader>zp` | Visual | Prompt for instruction + send selection (new pane) |
| `<leader>zr` | Visual | Send selection to existing agent pane              |
| `<leader>zR` | Visual | Prompt + send selection to existing agent pane     |
| `<leader>zf` | Normal | Send current file to agent                         |
| `<leader>zd` | Normal | Send current line diagnostics to agent             |
| `<leader>zD` | Normal | Send diagnostics to existing agent pane            |
| `<leader>zg` | Normal | Send git diff for current file to agent            |
| `<leader>zG` | Normal | Prompt for instruction + send git diff to agent    |

### Miscellaneous

| Key          | Mode   | Action                                 |
| ------------ | ------ | -------------------------------------- |
| `<leader>u`  | Normal | Toggle undo tree                       |
| `<leader>db` | Normal | Toggle database UI                     |
| `<leader>td` | Normal | Todo quickfix list                     |
| `<leader>tl` | Normal | Todo telescope search                  |
| `<leader>md` | Normal | Toggle markdown preview (in .md files) |
| `<M-f>`      | Normal | Toggle quickfix window                 |
