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
    "**/.git/*",
}

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

vim.opt.updatetime = 300
vim.opt.shortmess:append("c")

vim.opt.cursorline = true
vim.opt.colorcolumn = "80"
vim.opt.signcolumn = "yes"

vim.opt.list = true
vim.opt.listchars = { tab = "|-", trail = "·" }

vim.opt.splitright = true
vim.opt.laststatus = 3

vim.opt.hlsearch = false
vim.opt.showmode = false
vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.expand("~/.vim/undodir")
vim.opt.undofile = true

vim.g.undotree_WindowLayout = 4
