set completeopt=menu,menuone,noselect
let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']

nnoremap <leader>vd :lua vim.lsp.buf.definition()<CR>
nnoremap <leader>vi :lua vim.lsp.buf.implementation()<CR>
nnoremap <leader>vrr :lua vim.lsp.buf.references()<CR>
nnoremap <leader>ee :lua vim.diagnostic.open_float()<CR>
nnoremap <leader>[d <cmd>Lspsaga diagnostic_jump_next<CR>
nnoremap <leader>]d <cmd>Lspsaga diagnostic_jump_prev<CR>
nnoremap <leader>vws :lua vim.lsp.buf.workspace_symbol()<CR>

nnoremap <C-s> <cmd>Lspsaga code_action<CR>
vnoremap <C-s> :<C-U>Lspsaga range_code_action<CR>

nnoremap <leader>vh <cmd>Lspsaga hover_doc<CR>
nnoremap <C-f> <cmd>lua require('lspsaga.action').smart_scroll_with_saga(1, '<c-u>')<CR>
nnoremap <C-b> <cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1, '<c-u>')<CR>

nnoremap <leader>vsh <cmd>Lspsaga signature_help<CR>

nnoremap <silent>vrn <cmd>Lspsaga rename<CR>

nnoremap <leader>pd <cmd>lua require('lspsaga.provider').preview_definition()<CR>

" svelte
let g:vim_svelte_plugin_use_typescript = 1
let g:vim_svelte_plugin_use_sass = 1