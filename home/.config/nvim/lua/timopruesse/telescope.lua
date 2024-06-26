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
        file_browser = {
            -- theme = "ivy",
            -- hijack_netrw = true,
        },
    },
})

telescope.load_extension("fzy_native")
telescope.load_extension("file_browser")
telescope.load_extension("refactoring")
telescope.load_extension("flutter")

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
    require("telescope.builtin").git_branches({
        attach_mappings = function(_, map)
            map("i", "<c-d>", actions.git_delete_branch)
            map("n", "<c-d>", actions.git_delete_branch)
            return true
        end,
    })
end

return M
