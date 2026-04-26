local key = require("timopruesse.helpers.keymap")

local M = {}

M.setup = function(bufnr)
	local buffer = bufnr or false

	key.nnoremap("<leader>vd", vim.lsp.buf.definition, buffer)
	key.nnoremap("<leader>vi", vim.lsp.buf.implementation, buffer)
	key.nnoremap("<leader>vrr", vim.lsp.buf.references, buffer)
	key.nnoremap("<leader>ee", vim.diagnostic.open_float, buffer)

	-- [ = backward (prev), ] = forward (next)
	key.nnoremap("[d", function()
		vim.diagnostic.jump({ count = -1, float = true })
	end, buffer)
	key.nnoremap("]d", function()
		vim.diagnostic.jump({ count = 1, float = true })
	end, buffer)

	key.nnoremap("<leader>vws", vim.lsp.buf.workspace_symbol, buffer)

	key.nnoremap("<leader><leader>", vim.lsp.buf.code_action, buffer)
	key.vnoremap("<leader><leader>", vim.lsp.buf.code_action, buffer)

	key.nnoremap("<leader>vh", vim.lsp.buf.hover, buffer)
	key.nnoremap("<leader>vsh", vim.lsp.buf.signature_help, buffer)
	key.nnoremap("<leader>vrn", vim.lsp.buf.rename, buffer)
end

return M
