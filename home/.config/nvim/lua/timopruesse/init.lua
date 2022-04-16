function CreateNoremap(type, opts)
	return function(lhs, rhs, bufnr)
		bufnr = bufnr or 0
		vim.api.nvim_buf_set_keymap(bufnr, type, lhs, rhs, opts)
	end
end

Nnoremap = CreateNoremap("n", { noremap = true })
Inoremap = CreateNoremap("i", { noremap = true })

require("lualine").setup({
	icons_enabled = true,
	theme = "auto",
	globalstatus = true,
	extensions = { "fugitive", "quickfix", "nerdtree", "symbols-outline" },
	options = {
		component_separators = "",
		section_separators = "",
	},
	sections = {
		lualine_y = {},
		lualine_z = {},
	},
})

require("timopruesse.telescope")
require("timopruesse.lsp")

if pcall(require, "plenary") then
	RELOAD = require("plenary.reload").reload_module

	R = function(name)
		RELOAD(name)
		return require(name)
	end
end

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
