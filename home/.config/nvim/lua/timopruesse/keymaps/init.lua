require("pasta").setup({
	converters = {},
	next_key = vim.api.nvim_replace_termcodes("<C-n>", true, true, true),
	prev_key = vim.api.nvim_replace_termcodes("<C-p>", true, true, true),
})

local key = require("timopruesse.helpers.keymap")
local pasta_mappings = require("pasta.mappings")

key.nmap("p", pasta_mappings.p)
key.nmap("P", pasta_mappings.P)

---@diagnostic disable-next-line: different-requires
require("timopruesse.keymaps.telescope")
require("timopruesse.keymaps.git")
require("timopruesse.keymaps.harpoon")
require("timopruesse.keymaps.navigation")
require("timopruesse.keymaps.node")
require("timopruesse.keymaps.rust")
require("timopruesse.keymaps.lsp")
require("timopruesse.keymaps.php")

key.nnoremap("<leader>s", key.exec_command("w"))

--gimme my umlauts
key.inoremap("<M-a>", "ä")
key.inoremap("<M-o>", "ö")
key.inoremap("<M-u>", "ü")

key.nnoremap("Q", "<nop>")

-- FIXME: Broken mappings after lua update
-- key.nnoremap("<leader>ghw", key.exec_command('h <C-R>=expand("<cword>")'))
-- key.nnoremap("<leader>bs", key.exec_command('/<C-R>=escape(expand("<cword>"), "/")'))
-- key.nnoremap("<leader><CR>", key.exec_command("so ~/.config/nvim/init.vim"))

key.nnoremap("<leader>u", key.exec_command("UndotreeShow"))
key.nnoremap("<leader>pv", key.exec_command("Ex"))

key.vnoremap("J", key.exec_command("m '>+1<CR>gv=gv"))
key.vnoremap("K", key.exec_command("m '<-2<CR>gv=gv"))

key.vnoremap("<leader>p", '"_dP')

key.nnoremap("<leader>y", '"+y')
key.vnoremap("<leader>y", '"+y')
key.nnoremap("<leader>Y", 'gg"+yG')

key.nnoremap("<leader>d", '"_d')
key.vnoremap("<leader>d", '"_d')

key.nnoremap("Y", "y$")

key.inoremap(",", ",<c-g>u")
key.inoremap(".", ".<c-g>u")
key.inoremap("!", "!<c-g>u")
key.inoremap("?", "?<c-g>u")
key.inoremap("=", "=<c-g>u")

key.nmap("<C-q>", key.exec_command(":NvimTreeToggle"))
key.nnoremap("<leader>tf", key.exec_command("NvimTreeFindFile"))

--preview markdown
key.nnoremap("<leader>md", key.exec_command("Glow"))

--Copy to and from clipboard
key.nnoremap("<leader>yy", '"+y')
key.vnoremap("<leader>yy", '"+y')
key.nnoremap("<leader>pp", '"+p')
key.vnoremap("<leader>pp", '"+p')

--Resizing
key.nmap("<C-M-H>", "2<C-w><")
key.nmap("<C-M-L>", "2<C-w>>")
key.nmap("<C-M-K>", "<C-w>-")
key.nmap("<C-M-J>", "<C-w>+")
