local key = require("timopruesse.helpers.keymap")
local agent = require("timopruesse.coding_agent_herdr")

key.nnoremap("<leader>zo", function()
	agent.open({ mode = "vsplit" })
end, { desc = "open agent (vsplit)" })

key.nnoremap("<leader>zh", function()
	agent.open({ mode = "hsplit" })
end, { desc = "open agent (hsplit)" })

key.nnoremap("<leader>zw", function()
	agent.open({ mode = "window" })
end, { desc = "open agent (window)" })

-- Mirror herdr prefix+shift+S / R
key.nnoremap("<leader>zS", function()
	agent.open({ mode = "window", resume_mode = "resume" })
end, { desc = "agent resume (new tab)" })

key.nnoremap("<leader>zc", function()
	agent.open({ mode = "window", resume_mode = "continue" })
end, { desc = "agent continue (new tab)" })

key.vnoremap("<leader>zs", function()
	agent.send_selection({ mode = "vsplit" })
end, { desc = "send selection (new pane)" })

key.vnoremap("<leader>zp", function()
	agent.prompt_and_send({ mode = "vsplit" })
end, { desc = "prompt + send selection (new pane)" })

key.vnoremap("<leader>zr", function()
	agent.send_selection({ existing = true })
end, { desc = "send selection (existing pane)" })

key.vnoremap("<leader>zR", function()
	agent.prompt_and_send({ existing = true })
end, { desc = "prompt + send selection (existing pane)" })

key.nnoremap("<leader>zf", function()
	agent.send_file({ mode = "vsplit" })
end, { desc = "send file (new pane)" })

key.nnoremap("<leader>zd", function()
	agent.send_diagnostics({ mode = "vsplit" })
end, { desc = "send diagnostics (new pane)" })

key.nnoremap("<leader>zD", function()
	agent.send_diagnostics({ existing = true })
end, { desc = "send diagnostics (existing pane)" })

key.nnoremap("<leader>zg", function()
	agent.send_git_diff({ mode = "vsplit" })
end, { desc = "send git diff (new pane)" })

key.nnoremap("<leader>zG", function()
	agent.prompt_and_send_git_diff({ mode = "vsplit" })
end, { desc = "prompt + send git diff (new pane)" })
