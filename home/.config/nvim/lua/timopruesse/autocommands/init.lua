local show_highlight = function()
	require("vim.highlight").on_yank({ timeout = 1000 })
end

local au_yank = vim.api.nvim_create_augroup("highlight_yank", { clear = true })
vim.api.nvim_create_autocmd({ "TextYankPost" }, { pattern = { "*" }, callback = show_highlight, group = au_yank })

local au_fmt = vim.api.nvim_create_augroup("fmt", { clear = true })
vim.api.nvim_create_autocmd(
	{ "BufWritePre" },
	{ pattern = { "*" }, command = "try | undojoin | Neoformat | catch /E790/ | Neoformat | endtry", group = au_fmt }
)

local preview_markdown = function(cmd)
	local key = require("timopruesse.helpers.keymap")

	local keys = "<leader>md"
	if cmd.event == "BufEnter" then
		key.nnoremap(keys, key.exec_command("Glow"), cmd.buf)
	else
		key.nremovemap(keys, cmd.buf)
	end
end

local au_md = vim.api.nvim_create_augroup("markdown", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufLeave" }, {
	pattern = { "*.md" },
	callback = function(cmd)
		preview_markdown(cmd)
	end,
	group = au_md,
})

require("timopruesse.autocommands.yaml")
