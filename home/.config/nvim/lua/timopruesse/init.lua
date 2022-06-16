if pcall(require, "plenary") then
	RELOAD = require("plenary.reload").reload_module

	R = function(name)
		RELOAD(name)
		return require(name)
	end
end

require("timopruesse.sets")
require("timopruesse.theme")
require("timopruesse.variables.init")
require("timopruesse.keymaps.init")
require("timopruesse.autocommands.init")
require("timopruesse.statusline")
require("timopruesse.lsp")
require("timopruesse.telescope")

-- keep that goddamn cursor centered!!
require("stay-centered")

require("nvim-treesitter.configs").setup({
	highlight = { enable = true },
	incremental_selection = { enable = true },
	textobjects = { enable = true },
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

require("package-info").setup()
require("crates").setup()

require("refactoring").setup({})
