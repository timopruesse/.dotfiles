local key = require("timopruesse.helpers.keymap")

local M = {}

M.setup = function(bufnr)
	local buffer = bufnr or false

	key.nnoremap("<leader>vd", vim.lsp.buf.definition, buffer)
	key.nnoremap("<leader>vi", vim.lsp.buf.implementation, buffer)
	key.nnoremap("<leader>vrr", vim.lsp.buf.references, buffer)
	key.nnoremap("<leader>ee", vim.diagnostic.open_float, buffer)

	-- [ = backward (prev), ] = forward (next)
	key.nnoremap("[d", key.exec_command("Lspsaga diagnostic_jump_prev"), buffer)
	key.nnoremap("]d", key.exec_command("Lspsaga diagnostic_jump_next"), buffer)

	key.nnoremap("<leader>vws", vim.lsp.buf.workspace_symbol, buffer)

	key.nnoremap("<leader><leader>", key.exec_command("Lspsaga code_action"), buffer)
	-- range_code_action removed from lspsaga; code_action works in visual mode
	key.vnoremap("<leader><leader>", key.exec_command("Lspsaga code_action"), buffer)

	key.nnoremap("<leader>vh", key.exec_command("Lspsaga hover_doc"), buffer)
	-- Lspsaga signature_help removed — use native LSP
	key.nnoremap("<leader>vsh", vim.lsp.buf.signature_help, buffer)
	key.nnoremap("<leader>vrn", key.exec_command("Lspsaga rename"), buffer)
end

return M
