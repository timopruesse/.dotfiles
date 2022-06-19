vim.g.mapleader = " "

require("timopruesse.sets")
require("timopruesse.theme")
require("timopruesse.variables.init")
require("timopruesse.keymaps.init")
require("timopruesse.autocommands.init")
require("timopruesse.statusline")
require("timopruesse.lsp")
---@diagnostic disable-next-line: different-requires
require("timopruesse.telescope")

require("nvim-tree").setup({
	diagnostics = {
		enable = true,
		show_on_dirs = true,
	},
	view = {
		side = "right",
		centralize_selection = true,
		adaptive_size = true,
	},
	renderer = {
		group_empty = true,
	},
	filters = {
		dotfiles = true,
	},
})

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
