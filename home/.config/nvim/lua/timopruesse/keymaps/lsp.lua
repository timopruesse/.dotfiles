local key = require("timopruesse.helpers.keymap")
local provider = require("lspsaga.provider")

local scroll = function(dir)
	return function()
		require("lspsaga.action").smart_scroll_with_saga(dir, "<c-u>")
	end
end

key.nnoremap("<leader>vd", vim.lsp.buf.definition)
key.nnoremap("<leader>vi", vim.lsp.buf.implementation)
key.nnoremap("<leader>vrr", vim.lsp.buf.references)
key.nnoremap("<leader>ee", vim.diagnostic.open_float)
key.nnoremap("<leader>[d", key.exec_command("Lspsaga diagnostic_jump_next"))
key.nnoremap("<leader>]d", key.exec_command("Lspsaga diagnostic_jump_prev"))
key.nnoremap("<leader>vws", vim.lsp.buf.workspace_symbol)

key.nnoremap("<leader><leader>", key.exec_command("Lspsaga code_action"))
key.vnoremap("<C-s>", key.exec_command("<C-U>Lspsaga range_code_action"))

key.nnoremap("<leader>vh", key.exec_command("Lspsaga hover_doc"))
key.nnoremap("<C-f>", scroll(1))
key.nnoremap("<C-b>", scroll(-1))

key.nnoremap("<leader>vsh", key.exec_command("Lspsaga signature_help"))
key.nnoremap("<leader>vrn", key.exec_command("Lspsaga rename"))

key.nnoremap("<leader>pd", provider.preview_definition)
key.nnoremap("<leader>wf", provider.lsp_finder)
