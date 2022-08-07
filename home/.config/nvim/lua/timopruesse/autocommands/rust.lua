vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "TabEnter" }, {
	pattern = { "*.rs" },
	callback = require("lsp_extensions").inlay_hints,
}, { group = "TIMOPRUESSE" })

vim.api.nvim_create_autocmd(
	{ "FileType" },
	{
		pattern = { "toml" },
		callback = require("cmp").setup.buffer({ sources = { { name = "crates" } } }),
		group = vim.api.nvim_create_augroup("timopruesse", { clear = false }),
	}
)
