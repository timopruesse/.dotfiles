set colorcolumn=80
set signcolumn=yes

let g:timopruesse_colorscheme = "gruvbox"

fun! ColorMyPencils()
    let g:gruvbox_transparent_bg = 1
    let g:gruvbox_contrast_dark = 'hard'
    if exists('+termguicolors')
        let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
        let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    endif
    let g:gruvbox_invert_selection='0'

    set background=dark
    
    call luaeval('vim.cmd("colorscheme " .. _A[1])', [g:timopruesse_colorscheme])

    highlight ColorColumn ctermbg=0 guibg=black
    hi SignColumn guibg=none
    hi CursorLineNR guibg=None
    highlight Normal guibg=none
    highlight LineNr guifg=#5eacd3
    highlight netrwDir guifg=#5eacd3
    highlight qfFileName guifg=#aed75f
    hi TelescopeBorder guifg=#5eacd
endfun

autocmd BufEnter * call ColorMyPencils()

