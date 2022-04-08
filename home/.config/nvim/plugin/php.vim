" formatter
let g:neoformat_php_phpcsfixer = {
    \ 'exe': 'php-cs-fixer',
    \ 'args': ['fix', '-q'],
    \ 'replace': 1,
    \ }

" manual
let g:php_manual_online_search_shortcut = ''

" ale
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_enter = 0
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_open_list = 1
let g:ale_keep_list_window_open=0
let g:ale_set_quickfix=0
let g:ale_list_window_size = 5
let g:ale_php_phpcbf_standard='PSR2'
let g:ale_php_phpcs_standard='phpcs.xml.dist'
let g:ale_php_phpmd_ruleset='phpmd.xml'
let g:ale_fixers = {
  \ '*': ['remove_trailing_lines', 'trim_whitespace'],
  \ 'php': ['phpcbf', 'php_cs_fixer', 'remove_trailing_lines', 'trim_whitespace'],
  \}
let g:ale_fix_on_save = 1

" mappings
nmap <leader>pt :!sail test<CR>
nmap <leader>rl :!sa route:list<CR>

command! -nargs=1 Silent execute ':silent !'.<q-args> | execute ':redraw!'
map <leader>ff <esc>:w<cr>:Silent php-cs-fixer fix %:p --level=symfony<cr>

function! PHPModify(transformer)
    :update
    let l:cmd = "silent !".g:phpactor_executable." class:transform ".expand('%').' --transform='.a:transformer
    execute l:cmd
endfunction

nnoremap <leader>ic :call PHPModify("implement_contracts")<cr>
