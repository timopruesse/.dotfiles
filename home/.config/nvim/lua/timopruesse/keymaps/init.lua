require("pasta").setup({
	converters = {},
	next_key = vim.api.nvim_replace_termcodes("<C-n>", true, true, true),
	prev_key = vim.api.nvim_replace_termcodes("<C-p>", true, true, true),
})

local key = require("timopruesse.helpers.keymap")
local pasta_mappings = require("pasta.mappings")

key.nmap("p", pasta_mappings.p)
key.nmap("P", pasta_mappings.P)

require("timopruesse.keymaps.git")
