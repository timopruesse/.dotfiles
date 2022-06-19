local au_packer = vim.api.nvim_create_augroup("packer", {})

vim.api.nvim_create_autocmd({ "BufWritePost" }, { pattern = "packer/plugins.lua", command = "PackerCompile", group = au_packer })


