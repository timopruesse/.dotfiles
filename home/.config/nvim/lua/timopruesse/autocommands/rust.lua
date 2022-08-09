vim.api.nvim_create_autocmd({ "FileType" }, {
	pattern = { "toml" },
	callback = function()
		require("cmp").setup.buffer({ sources = { { name = "crates" } } })
	end,
	group = vim.api.nvim_create_augroup("timopruesse", { clear = false }),
})
