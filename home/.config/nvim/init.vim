syntax enable
filetype plugin indent on

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
" Plug 'tpope/vim-rhubarb'

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

" copilot
Plug 'github/copilot.vim'

" github
Plug 'kyazdani42/nvim-web-devicons'
Plug 'pwntester/octo.nvim'

" QOL
Plug 'arnamak/stay-centered.nvim'
Plug 'hrsh7th/nvim-pasta'
Plug 'antoinemadec/FixCursorHold.nvim'

call plug#end()

let loaded_matchparen = 1

lua require("timopruesse")

