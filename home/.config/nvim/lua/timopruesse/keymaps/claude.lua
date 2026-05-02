local key = require("timopruesse.helpers.keymap")
local claude = require("timopruesse.claude")

key.nnoremap("<leader>zo", function()
    claude.open_claude({ mode = "vsplit" })
end, { desc = "open (vsplit)" })

key.nnoremap("<leader>zh", function()
    claude.open_claude({ mode = "hsplit" })
end, { desc = "open (hsplit)" })

key.nnoremap("<leader>zw", function()
    claude.open_claude({ mode = "window" })
end, { desc = "open (window)" })

key.vnoremap("<leader>zs", function()
    claude.send_selection({ mode = "vsplit" })
end, { desc = "send selection (new pane)" })

key.vnoremap("<leader>zp", function()
    claude.prompt_and_send({ mode = "vsplit" })
end, { desc = "prompt + send selection (new pane)" })

key.vnoremap("<leader>zr", function()
    claude.send_selection({ existing = true })
end, { desc = "send selection (existing pane)" })

key.vnoremap("<leader>zR", function()
    claude.prompt_and_send({ existing = true })
end, { desc = "prompt + send selection (existing pane)" })

key.nnoremap("<leader>zf", function()
    claude.send_file({ mode = "vsplit" })
end, { desc = "send file (new pane)" })

key.nnoremap("<leader>zd", function()
    claude.send_diagnostics({ mode = "vsplit" })
end, { desc = "send diagnostics (new pane)" })

key.nnoremap("<leader>zD", function()
    claude.send_diagnostics({ existing = true })
end, { desc = "send diagnostics (existing pane)" })

key.nnoremap("<leader>zg", function()
    claude.send_git_diff({ mode = "vsplit" })
end, { desc = "send git diff (new pane)" })

key.nnoremap("<leader>zG", function()
    claude.prompt_and_send_git_diff({ mode = "vsplit" })
end, { desc = "prompt + send git diff (new pane)" })
