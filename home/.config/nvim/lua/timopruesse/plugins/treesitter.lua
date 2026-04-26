return {
	{ "nvim-treesitter/nvim-treesitter-context", lazy = true },
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = { "nvim-treesitter/nvim-treesitter-context" },
		lazy = false,
		build = ":TSUpdate",
		config = function()
			-- setup() must be called with install_dir to register it in runtimepath
			require("nvim-treesitter").setup({
				install_dir = vim.fn.stdpath("data") .. "/site",
			})
			require("nvim-treesitter").install({
				"lua",
				"rust",
				"html",
				"css",
				"scss",
				"svelte",
				"json",
				"yaml",
				"javascript",
				"typescript",
				"go",
				"dockerfile",
				"python",
				"markdown",
				"markdown_inline",
				"vim",
				"toml",
				"regex",
				"vimdoc",
			})

			-- The main branch of nvim-treesitter does not auto-enable highlighting;
			-- it must be started per buffer. Also enable folds and treesitter-based indent.
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
				callback = function(args)
					local ft = vim.bo[args.buf].filetype
					local lang = vim.treesitter.language.get_lang(ft) or ft
					if pcall(vim.treesitter.start, args.buf, lang) then
						vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
						vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end
				end,
			})
		end,
	},
}
