return {
	{
		"kdheepak/lazygit.nvim",
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
		},
	},
	{
		-- Walk a diff range file by file. The native Herdr app's PR panel opens
		-- `nvim -c "DiffviewOpen <base>...<head>"` on fetched refs/herdr/* refs.
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles", "DiffviewFocusFiles" },
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview: working tree against HEAD" },
			{ "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: history of this file" },
		},
		opts = {},
	},
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("gitsigns").setup()
		end,
	},
}
