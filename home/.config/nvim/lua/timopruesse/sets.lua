vim.opt.shell = "/bin/zsh"

vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Nice menu when typing `:find *.ts`
vim.opt.wildmode = { "longest", "list", "full" }
vim.opt.wildmenu = true
vim.opt.wildignore = {
	"*.pyc",
	"*_build/*",
	"**/coverage/*",
	"**/node_modules/*",
	"**/android/*",
	"**/ios/*",
	"**/.git/*",
}

vim.opt.background = "dark"
vim.opt.visualbell = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.nu = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 10
vim.opt.lazyredraw = true

vim.opt.cmdheight = 1
vim.opt.updatetime = 300
vim.opt.shortmess:append("c")

vim.opt.cursorline = true
vim.opt.colorcolumn = "80"
vim.opt.signcolumn = "yes"

vim.opt.list = true
vim.opt.listchars = { tab = "|-", trail = "·" }

vim.opt.splitright = true

vim.cmd("set nohlsearch")
vim.cmd("set noshowmode")
vim.cmd("set nowrap")

vim.cmd("set noswapfile")
vim.cmd("set nobackup")
vim.cmd("set undodir=$HOME/.vim/undodir")
vim.cmd("set undofile")
