local key = require("timopruesse.helpers.keymap")

local M = {}

M.setup = function(bufnr)
	local buffer = bufnr or false

	key.nmap("<leader>tt", key.exec_command("!sail test"), buffer)
	key.nmap("<leader>rl", key.exec_command("!sa route:list"), buffer)
end

return M
