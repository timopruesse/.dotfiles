vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "TabEnter" }, {
	pattern = { "*.rs" },
	callback = require("lsp_extensions").inlay_hints,
}, { group = "TIMOPRUESSE" })
