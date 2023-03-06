local key = require("timopruesse.helpers.keymap")

---@diagnostic disable-next-line: different-requires
require("timopruesse.keymaps.telescope")
require("timopruesse.keymaps.git")
require("timopruesse.keymaps.harpoon")
require("timopruesse.keymaps.navigation")
require("timopruesse.keymaps.lsp")
---@diagnostic disable-next-line: different-requires
require("timopruesse.keymaps.luasnip")

key.nnoremap("<C-s>", key.exec_command("w"))

-- gimme my umlauts
key.inoremap("<M-a>", "ä")
key.inoremap("<M-o>", "ö")
key.inoremap("<M-u>", "ü")

key.nnoremap("Q", "<nop>")

-- center cursor while moving through file
key.nnoremap("j", "jzz")
key.nnoremap("k", "kzz")
key.nnoremap("<Down>", "jzz")
key.nnoremap("<Up>", "kzz")

-- quickfix
local is_quickfix_open = function()
	for _, v in pairs(vim.fn.getwininfo()) do
		if v.quickfix == 1 then
			return true
		end
	end
	return false
end

key.nnoremap("<M-f>", function()
	if is_quickfix_open() then
		vim.cmd("cclose")
	else
		vim.cmd("copen")
	end
end)

-- database ui
key.nnoremap("<leader>db", key.exec_command("DBUIToggle"))

-- todo
key.nnoremap("<leader>td", key.exec_command("TodoQuickFix"))
key.nnoremap("<leader>tl", key.exec_command("TodoTelescope"))

-- FIXME: Broken mapping after lua update
-- key.nnoremap("<leader><CR>", key.exec_command("so ~/.config/nvim/init.vim"))

key.vnoremap("<leader>p", '"_dP')
key.nnoremap("<leader>p", '"_dP')

key.nnoremap("<leader>d", '"_d')
key.vnoremap("<leader>d", '"_d')

key.nnoremap("Y", "y$")

key.inoremap(",", ",<c-g>u")
key.inoremap(".", ".<c-g>u")
key.inoremap("!", "!<c-g>u")
key.inoremap("?", "?<c-g>u")
key.inoremap("=", "=<c-g>u")

-- copy to and from clipboard
key.nnoremap("<leader>yy", '"+y')
key.vnoremap("<leader>yy", '"+y')
key.nnoremap("<leader>pp", '"+p')
key.vnoremap("<leader>pp", '"+p')

key.nnoremap("<leader>Y", 'gg"+yG')

-- resizing
key.nmap("<C-M-H>", "2<C-w><")
key.nmap("<C-M-L>", "2<C-w>>")
key.nmap("<C-M-K>", "<C-w>-")
key.nmap("<C-M-J>", "<C-w>+")
