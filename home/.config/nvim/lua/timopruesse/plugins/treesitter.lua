return {
	{
		-- Default mode = "cursor" recomputes the context tree on every CursorMoved,
		-- which is a measurable hot spot on big TS/JS files. "topline" only updates
		-- when the visible top line changes, and capping max_lines keeps redraw work
		-- bounded.
		"nvim-treesitter/nvim-treesitter-context",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			mode = "topline",
			max_lines = 3,
			trim_scope = "outer",
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = { "nvim-treesitter/nvim-treesitter-context" },
		event = { "BufReadPre", "BufNewFile" },
		build = ":TSUpdate",
		config = function()
			-- setup() must be called with install_dir to register it in runtimepath
			local ts = require("nvim-treesitter")
			ts.setup({
				install_dir = vim.fn.stdpath("data") .. "/site",
			})

			-- Only install missing parsers — skip the async install sweep when
			-- everything is already present (common after the first :TSUpdate).
			local wanted = {
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
			}
			local installed = {}
			for _, lang in ipairs(ts.get_installed()) do
				installed[lang] = true
			end
			local missing = vim.tbl_filter(function(lang)
				return not installed[lang]
			end, wanted)
			if #missing > 0 then
				ts.install(missing)
			end

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
