require("timopruesse.sets")
require("timopruesse.theme")
require("timopruesse.variables.init")
require("timopruesse.keymaps.init")
require("timopruesse.autocommands.init")

-- Snippets are deferred to first InsertEnter for faster startup
vim.api.nvim_create_autocmd("InsertEnter", {
	once = true,
	callback = function()
		require("timopruesse.snippets.init")
	end,
})

-- LSP setup is now triggered by nvim-lspconfig's lazy event (BufReadPre/BufNewFile)
