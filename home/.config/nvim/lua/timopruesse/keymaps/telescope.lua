---@diagnostic disable-next-line: different-requires
local ts = require("telescope")
local key = require("timopruesse.helpers.keymap")
local builtin = require("telescope.builtin")
---@diagnostic disable-next-line: different-requires
local custom = require("timopruesse.telescope")

key.nnoremap("<leader>pl", builtin.live_grep)
key.nnoremap("<leader>ps", builtin.grep_string)
key.nnoremap("<C-p>", custom.project_files)
key.nnoremap("<Leader>pf", builtin.find_files)

key.nnoremap("<leader>pb", builtin.buffers)
key.nnoremap("<leader>qf", builtin.quickfix)
key.nnoremap("<leader>ll", builtin.loclist)
key.nnoremap("<leader>jl", builtin.jumplist)
key.nnoremap("<leader>rl", builtin.registers)

key.nnoremap("<leader>ds", builtin.lsp_document_symbols)
key.nnoremap("<leader>wss", builtin.lsp_workspace_symbols)
key.nnoremap("<leader>ts", builtin.treesitter)

key.nnoremap("<leader>vrc", custom.search_dotfiles)
key.nnoremap("<leader>gb", custom.git_branches)

key.vnoremap("<leader>rr", ts.extensions.refactoring.refactors)
