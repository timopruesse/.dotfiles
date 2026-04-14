# Keybinds

---

## Tmux

Prefix key: **Ctrl+b** (default)

### Session / Window Management

| Key          | Action                               |
| ------------ | ------------------------------------ |
| `prefix s`   | List/switch sessions                 |
| `prefix (`   | Switch to previous session           |
| `prefix )`   | Switch to next session               |
| `prefix c`   | New window (current directory)       |
| `prefix \`   | Vertical split (current directory)   |
| `prefix -`   | Horizontal split (current directory) |
| `prefix r`   | Reload tmux config                   |
| `prefix Tab` | Open popup terminal (75%x80%)        |
| `prefix S`   | Browse/resume Claude sessions (new window)    |
| `prefix R`   | Resume last Claude session (new window)        |
| `prefix H`   | Open Claude in horizontal split (current dir)  |
| `prefix V`   | Open Claude in vertical split (current dir)    |
| `prefix C`   | fzf picker to jump to a running Claude agent   |

### Pane Navigation

| Key         | Action            |
| ----------- | ----------------- |
| `Alt+Left`  | Select pane left  |
| `Alt+Right` | Select pane right |
| `Alt+Up`    | Select pane up    |
| `Alt+Down`  | Select pane down  |

### Window Reordering

| Key                | Action            |
| ------------------ | ----------------- |
| `Ctrl+Shift+Left`  | Swap window left  |
| `Ctrl+Shift+Right` | Swap window right |

### Notes

- Vi mode enabled for copy mode (`mode-keys vi`)
- Mouse support enabled
- Windows auto-renumber on close
- Sessions auto-saved/restored via tmux-resurrect + tmux-continuum

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

| Key         | Mode   | Action                  |
| ----------- | ------ | ----------------------- |
| `<M-h>`     | Normal | Navigate to left split  |
| `<M-j>`     | Normal | Navigate to below split |
| `<M-k>`     | Normal | Navigate to above split |
| `<M-l>`     | Normal | Navigate to right split |
| `<C-Left>`  | Normal | Navigate to left split  |
| `<C-Down>`  | Normal | Navigate to below split |
| `<C-Up>`    | Normal | Navigate to above split |
| `<C-Right>` | Normal | Navigate to right split |

#### Split Management

| Key     | Mode   | Action                          |
| ------- | ------ | ------------------------------- |
| `<M-v>` | Normal | Vertical split                  |
| `<M-d>` | Normal | Horizontal split                |
| `<C-x>` | Normal | Close all splits except current |

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

### Claude (Tmux Integration)

| Key          | Mode   | Action                                             |
| ------------ | ------ | -------------------------------------------------- |
| `<leader>zo` | Normal | Open Claude in vertical tmux split                 |
| `<leader>zh` | Normal | Open Claude in horizontal tmux split               |
| `<leader>zw` | Normal | Open Claude in new tmux window                     |
| `<leader>zs` | Visual | Send selection to Claude (new pane)                |
| `<leader>zp` | Visual | Prompt for instruction + send selection (new pane) |
| `<leader>zr` | Visual | Send selection to existing Claude pane             |
| `<leader>zR` | Visual | Prompt + send selection to existing Claude pane    |
| `<leader>zf` | Normal | Send current file to Claude                        |
| `<leader>zd` | Normal | Send current line diagnostics to Claude            |
| `<leader>zg` | Normal | Send git diff for current file to Claude           |

### Miscellaneous

| Key          | Mode   | Action                                 |
| ------------ | ------ | -------------------------------------- |
| `<leader>u`  | Normal | Toggle undo tree                       |
| `<leader>db` | Normal | Toggle database UI                     |
| `<leader>td` | Normal | Todo quickfix list                     |
| `<leader>tl` | Normal | Todo telescope search                  |
| `<leader>md` | Normal | Toggle markdown preview (in .md files) |
| `<M-f>`      | Normal | Toggle quickfix window                 |
