require("timopruesse.sets")
require("timopruesse.theme")
require("timopruesse.variables.init")
require("timopruesse.keymaps.init")
require("timopruesse.autocommands.init")
require("timopruesse.statusline")
require("timopruesse.lsp")
---@diagnostic disable-next-line: different-requires
require("timopruesse.snippets.init")

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
