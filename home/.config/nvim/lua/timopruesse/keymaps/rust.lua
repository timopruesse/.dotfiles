local key = require("timopruesse.helpers.keymap")

local M = {}

M.setup = function(bufnr)
	local buffer = bufnr or false

	key.nnoremap("<leader>rr", require("rust-tools.runnables").runnables, buffer)
end

return M
