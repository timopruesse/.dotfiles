local key = require("timopruesse.helpers.keymap")

key.imap("<c-k>", function()
	local ls = require("luasnip")
	if ls.expand_or_jumpable() then
		ls.expand_or_jump()
	end
end)

key.imap("<c-j>", function()
	local ls = require("luasnip")
	if ls.jumpable(-1) then
		ls.jump(-1)
	end
end)

key.imap("<c-l>", function()
	local ls = require("luasnip")
	if ls.choice_active() then
		ls.change_choice(1)
	end
end)

key.imap("<c-u>", function()
	require("luasnip.extras.select_choice")()
end)

key.nmap("<leader>rs", key.exec_command("source ~/.config/nvim/lua/timopruesse/snippets/init.lua"))
