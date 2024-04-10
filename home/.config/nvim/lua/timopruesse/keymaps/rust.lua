local key = require("timopruesse.helpers.keymap")

local M = {}

M.setup = function(bufnr)
	local buffer = bufnr or false

	key.nnoremap("<leader>rr", function()
		vim.cmd.RustLsp("runnables")
	end, buffer)

	key.nmap("<C-Space>", function()
		vim.cmd.RustLsp({ "hover", "actions" })
	end, buffer)

	key.nmap("<leader>tt", function()
		vim.cmd.RustLsp("testables")
	end, buffer)

	key.nmap("<leader>rd", function()
		vim.cmd.RustLsp("renderDiagnostic")
	end, buffer)
end

return M
