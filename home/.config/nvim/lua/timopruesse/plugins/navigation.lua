return {
	{
		-- Seamless navigation between nvim splits and herdr panes via M-h/j/k/l.
		-- Pair with willfish/herdr-navigator herdr plugin (see config.toml).
		"willfish/herdr-navigator.nvim",
		config = function()
			require("herdr-navigator").setup({
				mappings = {
					left = "<M-h>",
					down = "<M-j>",
					up = "<M-k>",
					right = "<M-l>",
				},
				herdr_executable = "herdr",
			})
		end,
	},
}
