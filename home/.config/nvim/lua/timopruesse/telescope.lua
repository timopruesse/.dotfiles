local M = {}

M.project_files = function()
	local opts = { hidden = true }

	require("telescope.builtin").find_files(opts)
end

M.search_dotfiles = function()
	require("telescope.builtin").find_files({
		prompt_title = " .DOTFILES ",
		cwd = "$HOME/.config/nvim",
		hidden = true,
		follow = true,
	})
end

M.git_branches = function()
	local actions = require("telescope.actions")

	require("telescope.builtin").git_branches({
		attach_mappings = function(_, map)
			map("i", "<c-d>", actions.git_delete_branch)
			map("n", "<c-d>", actions.git_delete_branch)
			return true
		end,
	})
end

return M
