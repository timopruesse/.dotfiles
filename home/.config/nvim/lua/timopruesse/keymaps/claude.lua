local key = require("timopruesse.helpers.keymap")
local claude = require("timopruesse.claude")

-- open agents
key.nnoremap("<leader>zo", function()
	claude.open_claude({ mode = "vsplit" })
end)
key.nnoremap("<leader>zh", function()
	claude.open_claude({ mode = "hsplit" })
end)
key.nnoremap("<leader>zw", function()
	claude.open_claude({ mode = "window" })
end)

-- send selection
key.vnoremap("<leader>zs", function()
	claude.send_selection({ mode = "vsplit" })
end)
key.vnoremap("<leader>zp", function()
	claude.prompt_and_send({ mode = "vsplit" })
end)

-- send file / diagnostics
key.nnoremap("<leader>zf", function()
	claude.send_file({ mode = "vsplit" })
end)
key.nnoremap("<leader>zd", function()
	claude.send_diagnostics({ mode = "vsplit" })
end)
