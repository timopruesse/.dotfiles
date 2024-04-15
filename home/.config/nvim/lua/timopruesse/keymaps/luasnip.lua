local key = require("timopruesse.helpers.keymap")
local ls = require("luasnip")

key.imap("<c-k>", function()
	if ls.expand_or_jumpable() then
		ls.expand_or_jump()
	end
end)

key.imap("<c-j>", function()
	if ls.jumpable(-1) then
		ls.jump(-1)
	end
end)

key.imap("<c-l>", function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end)

key.imap("<c-u>", require("luasnip.extras.select_choice"))

key.nmap("<leader>rs", key.exec_command("source ~/.config/nvim/lua/timopruesse/snippets/init.lua"))
