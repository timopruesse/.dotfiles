local key = require("timopruesse.helpers.keymap")

local M = {}

M.setup = function(bufnr)
	local buffer = bufnr or false

	key.nmap("<leader>tt", key.exec_command("!npm run test"), buffer)
end

return M
