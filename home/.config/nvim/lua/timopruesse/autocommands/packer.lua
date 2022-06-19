local au_packer = vim.api.nvim_create_augroup("packer", {})

vim.api.nvim_create_autocmd(
	{ "BufWritePost" },
	{ pattern = "plugins.lua", command = "PackerCompile", group = au_packer }
)
