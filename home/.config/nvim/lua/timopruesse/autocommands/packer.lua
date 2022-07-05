local au_packer = vim.api.nvim_create_augroup("packer", {})

vim.api.nvim_create_autocmd({ "BufWritePost" }, { pattern = "plugins.lua", command = "PackerSync", group = au_packer })
