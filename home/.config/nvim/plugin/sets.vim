set nocompatible

set path+=**

" Nice menu when typing `:find *.py`
set wildmode=longest,list,full
set wildmenu
" Ignore files
set wildignore+=*.pyc
set wildignore+=*_build/*
set wildignore+=**/coverage/*
set wildignore+=**/node_modules/*
set wildignore+=**/android/*
set wildignore+=**/ios/*
set wildignore+=**/.git/*

set background=dark
set visualbell
set noerrorbells
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set nu
set nowrap
set smartcase
set noswapfile
set nobackup
set undodir=$HOME/.vim/undodir
set undofile
set incsearch
set nohlsearch
set relativenumber
set termguicolors
set scrolloff=10
set noshowmode

set cmdheight=1
set updatetime=50
set shortmess+=c
