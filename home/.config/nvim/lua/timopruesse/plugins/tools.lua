return {
	{ "nvim-lua/plenary.nvim", lazy = true },
	{ "mbbill/undotree", cmd = "UndotreeToggle" },
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		lazy = true,
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("harpoon"):setup()
		end,
	},
	{ "kevinhwang91/nvim-bqf", ft = { "qf" } },
	{ "tpope/vim-dadbod", lazy = true },
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = { "tpope/vim-dadbod" },
		cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
	},
	{
		"folke/todo-comments.nvim",
		event = "BufReadPost",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("todo-comments").setup({})
		end,
	},
	{
		"OXY2DEV/markview.nvim",
		ft = { "markdown", "Avante", "codecompanion" },
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
	{ "nvim-telescope/telescope-file-browser.nvim", lazy = true },
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-fzy-native.nvim",
			"nvim-telescope/telescope-file-browser.nvim",
		},
		config = function()
			local actions = require("telescope.actions")
			local telescope = require("telescope")

			telescope.setup({
				defaults = {
					file_sorter = require("telescope.sorters").get_fzy_sorter,
					prompt_prefix = "🔍 ",
					color_devicons = true,

					file_previewer = require("telescope.previewers").vim_buffer_cat.new,
					grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
					qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,

					mappings = {
						i = {
							["<C-x>"] = false,
							["<C-f>"] = actions.send_to_qflist + actions.open_qflist,
							["<M-f>"] = actions.send_selected_to_qflist + actions.open_qflist,
							["<C-h>"] = "which_key",
						},
					},
				},
				extensions = {
					fzy_native = {
						override_generic_sorter = false,
						override_file_sorter = true,
					},
					file_browser = {},
				},
			})

			telescope.load_extension("fzy_native")
			telescope.load_extension("file_browser")
		end,
	},
}
