nnoremap <leader>pl :lua require('telescope.builtin').live_grep()<CR>
nnoremap <leader>ps :lua require('telescope.builtin').grep_string()<CR>
nnoremap <C-p> :lua require('telescope.builtin').git_files()<CR>
nnoremap <Leader>pf :lua require('telescope.builtin').find_files()<CR>

nnoremap <leader>pb :lua require('telescope.builtin').buffers()<CR>
nnoremap <leader>qf :lua require('telescope.builtin').quickfix()<CR>
nnoremap <leader>ll :lua require('telescope.builtin').loclist()<CR>
nnoremap <leader>jl :lua require('telescope.builtin').jumplist()<CR>
nnoremap <leader>rl :lua require('telescope.builtin').registers()<CR>

nnoremap <leader>ds :lua require('telescope.builtin').lsp_document_symbols()<CR>
nnoremap <leader>wss :lua require('telescope.builtin').lsp_workspace_symbols()<CR>
nnoremap <leader>ts :lua require('telescope.builtin').treesitter()<CR>

nnoremap <leader>vrc :lua require('timopruesse.telescope').search_dotfiles()<CR>
nnoremap <leader>gb :lua require('timopruesse.telescope').git_branches()<CR>

