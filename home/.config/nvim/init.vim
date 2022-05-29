syntax enable
filetype plugin indent on

let g:loaded_perl_provider = 0
let g:loaded_ruby_provider = 0

if empty(glob('~/.config/nvim/autoload/plug.vim'))
    silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
                \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd!
    autocmd VimEnter * PlugInstall
    autocmd VimEnter * TSInstall html
    autocmd VimEnter * TSInstall css
    autocmd VimEnter * TSInstall scss
    autocmd VimEnter * TSInstall svelte
    autocmd VimEnter * TSInstall rust
    autocmd VimEnter * TSInstall php
    autocmd VimEnter * TSInstall json
    autocmd VimEnter * TSInstall yaml
    autocmd VimEnter * TSInstall javascript
    autocmd VimEnter * TSInstall typescript
    autocmd VimEnter * TSInstall lua
    autocmd VimEnter * TSInstall go
    autocmd VimEnter * TSInstall dockerfile
    autocmd VimEnter * TSInstall python
    autocmd VimEnter * TSInstall dart
    autocmd VimEnter * TSInstall markdown
    autocmd VimEnter * TSInstall tsx
    autocmd VimEnter * TSInstall vim
endif

call plug#begin('~/.vim/plugged')

" theme
Plug 'gruvbox-community/gruvbox'
Plug 'stevearc/dressing.nvim'

Plug 'vim-utils/vim-man'
Plug 'mbbill/undotree'

" debugging
Plug 'mfussenegger/nvim-dap'

" refactoring
Plug 'ThePrimeagen/refactoring.nvim'

" comments
Plug 'terrortylor/nvim-comment'
Plug 'JoosepAlviste/nvim-ts-context-commentstring'

" editorconfig
Plug 'gpanders/editorconfig.nvim'

" telescope
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzy-native.nvim'
Plug 'BurntSushi/ripgrep'

Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-projectionist'
Plug 'tpope/vim-surround'

Plug 'preservim/nerdtree'

" markdown
Plug 'ellisonleao/glow.nvim'

" harpoon
Plug 'ThePrimeagen/harpoon'

" prettier
Plug 'sbdchd/neoformat'

" lsp + autocomplete
Plug 'neovim/nvim-lspconfig'
Plug 'tami5/lspsaga.nvim'
Plug 'nvim-lua/lsp_extensions.nvim'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-nvim-lsp-document-symbol'
Plug 'hrsh7th/cmp-nvim-lsp-signature-help'
Plug 'hrsh7th/cmp-nvim-lua'
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-calc'
Plug 'hrsh7th/cmp-emoji'
Plug 'tzachar/cmp-tabnine', { 'do': './install.sh' }
Plug 'simrat39/symbols-outline.nvim'
Plug 'petertriho/cmp-git'
Plug 'David-Kunz/cmp-npm'
Plug 'j-hui/fidget.nvim'
Plug 'jose-elias-alvarez/null-ls.nvim'

" treesitter
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'nvim-treesitter/playground'

" quickfix
Plug 'kevinhwang91/nvim-bqf'

" status line
Plug 'tamton-aquib/staline.nvim'

" fuzzy finder
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" git
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'f-person/git-blame.nvim'

" npm
Plug 'MunifTanjim/nui.nvim'
Plug 'vuki656/package-info.nvim'

" ts
Plug 'jose-elias-alvarez/nvim-lsp-ts-utils'

" svelte
Plug 'leafOfTree/vim-svelte-plugin'

" rust
Plug 'rust-lang/rust.vim'
Plug 'simrat39/rust-tools.nvim'
Plug 'saecki/crates.nvim'

" php
Plug 'alvan/vim-php-manual', {'for': 'php'}
Plug 'w0rp/ale'

" golang
Plug 'fatih/vim-go'

" python
Plug 'ambv/black'

" rfc
Plug 'mhinz/vim-rfc'

" copilot
Plug 'github/copilot.vim'

" github
Plug 'kyazdani42/nvim-web-devicons'
Plug 'pwntester/octo.nvim'

" QOL
Plug 'arnamak/stay-centered.nvim'

call plug#end()

" import lua scripts
lua require("timopruesse")
lua require'nvim-treesitter.configs'.setup { highlight = { enable = true }, incremental_selection = { enable = true }, textobjects = { enable = true }}

" remappings
let loaded_matchparen = 1
let mapleader = " "

" keep that goddamn cursor centered!!
lua require("stay-centered")

" gimme my umlauts
inoremap <M-a> ä
inoremap <M-o> ö
inoremap <M-u> ü

nnoremap <silent> Q <nop>
nnoremap <leader>ghw :h <C-R>=expand("<cword>")<CR><CR>
nnoremap <leader>bs /<C-R>=escape(expand("<cWORD>"), "/")<CR><CR>
nnoremap <leader>u :UndotreeShow<CR>
nnoremap <leader>pv :Ex<CR>
nnoremap <Leader><CR> :so ~/.config/nvim/init.vim<CR>
nnoremap <leader>s :%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>

vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

vnoremap <leader>p "_dP

nnoremap <leader>y "+y
vnoremap <leader>y "+y
nnoremap <leader>Y gg"+yG

nnoremap <leader>d "_d
vnoremap <leader>d "_d

nnoremap Y y$

inoremap , ,<c-g>u
inoremap . .<c-g>u
inoremap ! !<c-g>u
inoremap ? ?<c-g>u
inoremap = =<c-g>u

nmap <C-q> :NERDTreeToggle<CR>
nnoremap <leader>tf :NERDTreeFind<CR>

" preview markdown
noremap <leader>md :Glow<CR>

" Copy to and from clipboard
nnoremap <leader>yy "+y
vnoremap <leader>yy "+y
nnoremap <leader>pp "+p
vnoremap <leader>pp "+p

" Resizing
nmap <C-M-H> 2<C-w><
nmap <C-M-L> 2<C-w>>
nmap <C-M-K> <C-w>-
nmap <C-M-J> <C-w>+

augroup fmt
  autocmd!
  au BufWritePre * try | undojoin | Neoformat | catch /E790/ | Neoformat | endtry
augroup END

augroup highlight_yank
    autocmd!
    autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank({timeout = 1000})
augroup END

augroup TIMOPRUESSE
    autocmd!
    autocmd BufEnter,BufWinEnter,TabEnter *.rs :lua require'lsp_extensions'.inlay_hints{}
augroup END
