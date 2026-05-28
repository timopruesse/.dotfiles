local key = require("timopruesse.helpers.keymap")

-- split navigation (seamless across nvim splits and tmux panes)
key.nnoremap("<M-h>", "<cmd>TmuxNavigateLeft<cr>")
key.nnoremap("<M-j>", "<cmd>TmuxNavigateDown<cr>")
key.nnoremap("<M-k>", "<cmd>TmuxNavigateUp<cr>")
key.nnoremap("<M-l>", "<cmd>TmuxNavigateRight<cr>")

-- arrow keys as alternative
key.nnoremap("<C-Down>", "<C-W><C-J>")
key.nnoremap("<C-Up>", "<C-W><C-K>")
key.nnoremap("<C-Right>", "<C-W><C-L>")
key.nnoremap("<C-Left>", "<C-W><C-H>")

-- splits
key.nnoremap("<C-x>", key.exec_command("only"))
key.nnoremap("<M-v>", key.exec_command("vsplit"))
key.nnoremap("<M-d>", key.exec_command("split"))
key.nnoremap("<M-q>", key.exec_command("close"))

-- buffers
key.nnoremap("<leader>bn", key.exec_command("bnext"))
key.nnoremap("<leader>bp", key.exec_command("bprevious"))
key.nnoremap("<leader>bf", key.exec_command("bfirst"))
key.nnoremap("<leader>bl", key.exec_command("blast"))

-- insert mode movement
key.imap("<M-h>", "<left>")
key.imap("<M-j>", "<down>")
key.imap("<M-k>", "<up>")
key.imap("<M-l>", "<right>")
key.imap("<M-f>", "<C-right>")
key.imap("<M-b>", "<C-left>")
