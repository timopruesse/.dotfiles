return {
	{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },
	{ "nvim-tree/nvim-web-devicons", lazy = true },
	{ "stevearc/dressing.nvim", event = "VeryLazy" },
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = {
					theme = "catppuccin-mocha",
					globalstatus = true,
					section_separators = "",
					component_separators = "",
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { { "branch", icon = "" }, "diff" },
					lualine_c = { { "filename", path = 1 } },
					lualine_x = {
						{
							function()
								local names = {}
								for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
									table.insert(names, c.name)
								end
								return table.concat(names, ",")
							end,
							icon = " ",
						},
						"filetype",
					},
					lualine_y = { "progress" },
					lualine_z = {
						{ "location", fmt = function(s) return "[" .. s .. "]" end },
					},
				},
			})
		end,
	},
	{
		"j-hui/fidget.nvim",
		event = "LspAttach",
		config = function()
			require("fidget").setup({
				notification = {
					override_vim_notify = true,
					window = { winblend = 0 },
				},
			})
		end,
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			local wk = require("which-key")
			wk.setup({})
			wk.add({
				{ "<leader>v", group = "LSP" },
				{ "<leader>z", group = "Claude" },
				{ "<leader>p", group = "Search/Package" },
				{ "<leader>b", group = "Buffers" },
				{ "<leader>t", group = "Todo/Test" },
				{ "<leader>d", group = "Diagnostics" },
				{ "<leader>y", group = "Yank" },
				{ "<leader>g", group = "Git" },
				{ "<leader>c", group = "Commits" },
				{ "<leader>r", group = "References" },
				{ "<leader>s", group = "Swap" },
			})
		end,
	},
}
