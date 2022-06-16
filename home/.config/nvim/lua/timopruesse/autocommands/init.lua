local show_diagnostics = function()
	vim.diagnostic.open_float(nil, { focusable = false })
end

local show_highlight = function()
	require("vim.highlight").on_yank({ timeout = 1000 })
end

local au_tpr = vim.api.nvim_create_augroup("TIMOPRUESSE", {})
local au_yank = vim.api.nvim_create_augroup("highlight_yank", {})
local au_fmt = vim.api.nvim_create_augroup("fmt", {})

vim.api.nvim_create_autocmd({ "CursorHold" }, {
	pattern =  {"*"},
	callback = show_diagnostics,
 group = au_tpr })

vim.api.nvim_create_autocmd(
	{ "TextYankPost" },
	{ pattern = {"*"}, callback = show_highlight , group = au_yank }
)

vim.api.nvim_create_autocmd(
	{ "BufWritePre" },
	{ pattern = {"*"}, command = "try | undojoin | Neoformat | catch /E790/ | Neoformat | endtry" , group = au_fmt }
)

require("timopruesse.autocommands.yaml")
