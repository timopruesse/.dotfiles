function CreateNoremap(type, opts)
	return function(lhs, rhs, bufnr)
		bufnr = bufnr or 0
		vim.api.nvim_buf_set_keymap(bufnr, type, lhs, rhs, opts)
	end
end

Nnoremap = CreateNoremap("n", { noremap = true })
Inoremap = CreateNoremap("i", { noremap = true })

if pcall(require, "plenary") then
	RELOAD = require("plenary.reload").reload_module

	R = function(name)
		RELOAD(name)
		return require(name)
	end
end

require("timopruesse.sets")
require("timopruesse.theme")
require("timopruesse.statusline")
require("timopruesse.telescope")
require("timopruesse.lsp")

require("nvim_comment").setup({
	hook = function()
		require("ts_context_commentstring.internal").update_commentstring()
	end,
})

require("nvim-treesitter.configs").setup({
	context_commentstring = {
		enable = true,
	},
})

local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.markdown.filetype_to_parsername = "octo"

require("package-info").setup()
require("crates").setup()

require("refactoring").setup({})

vim.keymap.set("n", "p", require("pasta.mappings").p)
vim.keymap.set("n", "P", require("pasta.mappings").P)

require("pasta").setup({
	converters = {},
	next_key = vim.api.nvim_replace_termcodes("<C-n>", true, true, true),
	prev_key = vim.api.nvim_replace_termcodes("<C-p>", true, true, true),
})

-- NERDTree
vim.g.NERDTreeWinSize = 80
vim.g.NERDTreeWinPos = "right"
