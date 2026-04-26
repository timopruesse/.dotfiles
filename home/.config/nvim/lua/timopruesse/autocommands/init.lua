local au_yank = vim.api.nvim_create_augroup("highlight_yank", { clear = true })
vim.api.nvim_create_autocmd({ "TextYankPost" }, {
	pattern = { "*" },
	callback = function()
		vim.highlight.on_yank({ timeout = 800 })
	end,
	group = au_yank,
})

-- markview.nvim renders markdown in-buffer; <leader>md toggles it
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	group = vim.api.nvim_create_augroup("markdown", { clear = true }),
	callback = function(args)
		vim.keymap.set("n", "<leader>md", "<cmd>Markview toggle<cr>", {
			buffer = args.buf,
			silent = true,
			desc = "Toggle markdown render",
		})
	end,
})

require("timopruesse.autocommands.yaml")
