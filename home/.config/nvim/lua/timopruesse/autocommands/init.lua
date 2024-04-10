local au_yank = vim.api.nvim_create_augroup("highlight_yank", { clear = true })
vim.api.nvim_create_autocmd({ "TextYankPost" }, {
	pattern = { "*" },
	callback = function()
		require("vim.highlight").on_yank({ timeout = 800 })
	end,
	group = au_yank,
})

local toggle_markdown_preview = function()
	local peek = require("peek")

	if peek.is_open() then
		peek.close()
	else
		peek.open()
	end
end

local preview_markdown = function(cmd)
	local key = require("timopruesse.helpers.keymap")

	local keys = "<leader>md"
	if cmd.event == "BufEnter" then
		key.nnoremap(keys, toggle_markdown_preview, cmd.buf)
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
