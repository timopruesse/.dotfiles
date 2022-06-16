local key = require("timopruesse.helpers.keymap")

-- split navigation
key.nnoremap("<M-j>", "<C-W><C-J>")
key.nnoremap("<M-k>", "<C-W><C-K>")
key.nnoremap("<M-l>", "<C-W><C-L>")
key.nnoremap("<M-h>", "<C-W><C-H>")

-- arrow keys as alternative
key.nnoremap("<C-Down>", "<C-W><C-J>")
key.nnoremap("<C-Up>", "<C-W><C-K>")
key.nnoremap("<C-Right>", "<C-W><C-L>")
key.nnoremap("<C-Left>", "<C-W><C-H>")

-- splits
key.nnoremap("<C-x>", key.exec_command("only"))
key.nnoremap("<M-v>", key.exec_command("vsplit"))
key.nnoremap("<M-d>", key.exec_command("split"))

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
