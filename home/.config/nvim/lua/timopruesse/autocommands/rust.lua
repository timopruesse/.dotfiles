vim.api.nvim_create_autocmd({ "FileType" }, {
	pattern = { "toml" },
	callback = function()
		require("cmp").setup.buffer({ sources = { { name = "crates" } } })
	end,
	group = vim.api.nvim_create_augroup("timopruesse", { clear = false }),
})

require("timopruesse.helpers.autocommands.run_on_save").run_on_save({
	au_group = "rust_test",
	pattern = { "*.rs" },
	fileTypes = { "rust" },
	command = { "cargo", "test" },
	testAllCommandName = "ToggleRustTestAll",
	testFileCommandName = "ToggleRustTestFile",
	message = "Testing...",
})
