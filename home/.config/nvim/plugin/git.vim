nnoremap <leader>ga :Git fetch --all<CR>
nnoremap <leader>grum :Git rebase upstream/master<CR>
nnoremap <leader>grom :Git rebase origin/master<CR>

nmap <leader>gh :diffget //3<CR>
nmap <leader>gf :diffget //2<CR>
nmap <leader>gg :G<CR>
nmap <leader>gs :G status<CR>
" nmap <leader>gb :GBranches<CR> // use telescope for this :)
nmap <leader>gc :G commit<CR>
nmap <leader>gp :G push<CR>

" blame
nmap <leader>gt :GitBlameToggle<CR>
nmap <leader>go :GitBlameOpenCommitURL<CR>

" disable git blame initially
let g:gitblame_enabled = 0

let g:fzf_layout = { 'window': { 'width': 0.8, 'height': 0.8 } }
let $FZF_DEFAULT_OPTS='--reverse'
