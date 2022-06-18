command! -nargs=1 Silent execute ':silent !'.<q-args> | execute ':redraw!'
map <leader>ff <esc>:w<cr>:Silent php-cs-fixer fix %:p --level=symfony<cr>

function! PHPModify(transformer)
    :update
    let l:cmd = "silent !".g:phpactor_executable." class:transform ".expand('%').' --transform='.a:transformer
    execute l:cmd
endfunction

nnoremap <leader>ic :call PHPModify("implement_contracts")<cr>
