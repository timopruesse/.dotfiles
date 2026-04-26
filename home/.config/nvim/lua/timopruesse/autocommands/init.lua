local au_yank = vim.api.nvim_create_augroup("highlight_yank", { clear = true })
vim.api.nvim_create_autocmd({ "TextYankPost" }, {
	pattern = { "*" },
	callback = function()
		vim.highlight.on_yank({ timeout = 800 })
	end,
	group = au_yank,
})

vim.api.nvim_create_user_command("MarkdownPreview", function()
	vim.fn.system({ "wslview", vim.fn.expand("%:p") })
end, { desc = "Open current markdown file in WSL default browser" })

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	group = vim.api.nvim_create_augroup("markdown", { clear = true }),
	callback = function(args)
		vim.keymap.set("n", "<leader>md", "<cmd>MarkdownPreview<cr>", {
			buffer = args.buf,
			silent = true,
			desc = "Markdown preview (wslview)",
		})
	end,
})

require("timopruesse.autocommands.yaml")
