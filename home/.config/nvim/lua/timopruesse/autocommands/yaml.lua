local set_options = function()
	vim.opt_local.ts = 2
	vim.opt_local.sts = 2
	vim.opt_local.sw = 2
	vim.opt_local.expandtab = true
end

vim.api.nvim_create_autocmd({ "FileType" }, {
	pattern = { "yaml" },
	callback = set_options,
	group = vim.api.nvim_create_augroup("timopruesse", { clear = false }),
})
