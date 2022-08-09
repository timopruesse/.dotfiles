local key = require("timopruesse.helpers.keymap")

local M = {}

M.setup = function(bufnr)
	local buffer = bufnr or false

	key.nnoremap("<leader>rr", require("rust-tools.runnables").runnables, buffer)
	key.nmap("<C-Space>", require("rust-tools").hover_actions.hover_actions, buffer)
end

return M
