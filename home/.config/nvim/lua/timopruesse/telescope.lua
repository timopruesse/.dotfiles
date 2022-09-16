local actions = require("telescope.actions")
---@diagnostic disable-next-line: different-requires
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
		preview = {
			mime_hook = function(filepath, bufnr, opts)
				local is_image = function(path)
					local image_extensions = { "png", "jpg", "gif" }
					local split_path = vim.split(path:lower(), ".", { plain = true })
					local extension = split_path[#split_path]
					return vim.tbl_contains(image_extensions, extension)
				end

				if is_image(filepath) then
					local term = vim.api.nvim_open_term(bufnr, {})
					local function send_output(_, data, _)
						for _, d in ipairs(data) do
							vim.api.nvim_chan_send(term, d .. "\r\n")
						end
					end

					vim.fn.jobstart({
						"catimg",
						filepath,
					}, { on_stdout = send_output, stdout_buffered = true, pty = true })
				else
					require("telescope.previewers.utils").set_preview_message(
						bufnr,
						opts.winid,
						"File cannot be previewed"
					)
				end
			end,
		},
	},
	extensions = {
		fzy_native = {
			override_generic_sorter = false,
			override_file_sorter = true,
		},
	},
})

telescope.load_extension("fzy_native")
telescope.load_extension("refactoring")
telescope.load_extension("flutter")

local M = {}

M.project_files = function()
	local opts = { hidden = true }

	local ok = pcall(require("telescope.builtin").git_files, opts)
	if not ok then
		require("telescope.builtin").find_files(opts)
	end
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
	require("telescope.builtin").git_branches({
		attach_mappings = function(_, map)
			map("i", "<c-d>", actions.git_delete_branch)
			map("n", "<c-d>", actions.git_delete_branch)
			return true
		end,
	})
end

return M
