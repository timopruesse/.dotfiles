local key = require("timopruesse.helpers.keymap")

local M = {}

M.setup = function(bufnr)
	local buffer = bufnr or false

	key.nmap("<leader>ta", key.exec_command("ToggleNpmTestAll"), buffer)
	key.nmap("<leader>tt", key.exec_command("ToggleNpmTestFile"), buffer)
end

return M
