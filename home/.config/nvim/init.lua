vim.loader.enable()

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Ensure fnm-managed node is in PATH (interactive shell hooks don't run in nvim's
-- env, so LSP servers and mason tools that need node won't find it otherwise)
do
	local fnm_dir = vim.env.FNM_MULTISHELL_PATH
	if fnm_dir and fnm_dir ~= "" then
		vim.env.PATH = fnm_dir .. ":" .. vim.env.PATH
	else
		local aliases = vim.fn.glob(vim.fn.expand("~/.local/share/fnm/aliases/default/bin"), false, true)
		if #aliases > 0 then
			vim.env.PATH = aliases[1] .. ":" .. vim.env.PATH
		end
	end
end

vim.g.mapleader = " "

require("lazy").setup({
	spec = { { import = "timopruesse.plugins" } },
})

require("timopruesse.init")
