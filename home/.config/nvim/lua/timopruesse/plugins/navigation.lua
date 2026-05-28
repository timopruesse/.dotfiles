return {
	{
		-- seamless navigation between nvim splits and tmux panes via M-h/j/k/l.
		-- mappings are defined in keymaps/navigation.lua, so disable the plugin's
		-- own C-h/j/k/l defaults (those belong to Harpoon).
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
		},
		init = function()
			vim.g.tmux_navigator_no_mappings = 1
		end,
	},
}
