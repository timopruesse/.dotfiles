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
	{
		"kdheepak/lazygit.nvim",
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		keys = {
			{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
		},
	},
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			vim.opt.laststatus = 3
			require("lualine").setup({
				options = {
					theme = "catppuccin-mocha",
					globalstatus = true,
					section_separators = "",
					component_separators = "",
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { { "branch", icon = "" }, "diff" },
					lualine_c = { { "filename", path = 1 } },
					lualine_x = {
						{
							function()
								local names = {}
								for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
									table.insert(names, c.name)
								end
								return table.concat(names, ",")
							end,
							icon = " ",
						},
						"filetype",
					},
					lualine_y = { "progress" },
					lualine_z = { { "location", fmt = function(s) return "[" .. s .. "]" end } },
				},
			})
		end,
	},
	{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("gitsigns").setup()
		end,
	},
	{ "stevearc/dressing.nvim", event = "VeryLazy" },
	{ "nvim-tree/nvim-web-devicons", lazy = true },
	{ "mbbill/undotree", cmd = "UndotreeToggle" },
	{
		"andymass/vim-matchup",
		event = "BufReadPost",
		init = function()
			vim.g.matchup_matchparen_offscreen = { method = "popup" }
		end,
	},
	{ "ThePrimeagen/harpoon", lazy = true },
	{
		"numToStr/Comment.nvim",
		event = "BufReadPost",
		config = function()
			require("Comment").setup()
		end,
	},
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"BurntSushi/ripgrep",
			"nvim-telescope/telescope-fzy-native.nvim",
			"nvim-telescope/telescope-file-browser.nvim",
		},
		config = function()
			local actions = require("telescope.actions")
			local telescope = require("telescope")

			telescope.setup({
				defaults = {
					file_sorter = require("telescope.sorters").get_fzy_sorter,
					prompt_prefix = "🔍 ",
					color_devicons = true,

					file_previewer = require("telescope.previewers").vim_buffer_cat.new,
					grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
					qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,

					mappings = {
						i = {
							["<C-x>"] = false,
							["<C-f>"] = actions.send_to_qflist + actions.open_qflist,
							["<M-f>"] = actions.send_selected_to_qflist + actions.open_qflist,
							["<C-h>"] = "which_key",
						},
					},
				},
				extensions = {
					fzy_native = {
						override_generic_sorter = false,
						override_file_sorter = true,
					},
					file_browser = {},
				},
			})

			telescope.load_extension("fzy_native")
			telescope.load_extension("file_browser")
		end,
	},
	{ "nvim-telescope/telescope-file-browser.nvim", lazy = true },
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		lazy = true,
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = "",
				desc = "Format buffer",
			},
		},
		opts = {
			default_format_opts = {
				stop_after_first = true,
			},
			formatters_by_ft = {
				javascript = { "prettierd", "prettier" },
				typescript = { "prettierd", "prettier" },
				javascriptreact = { "prettierd", "prettier" },
				typescriptreact = { "prettierd", "prettier" },
				svelte = { "prettierd", "prettier" },
				css = { "prettierd", "prettier" },
				html = { "prettierd", "prettier" },
				json = { "prettierd", "prettier" },
				yaml = { "prettierd", "prettier" },
				markdown = { "prettierd", "prettier" },
				graphql = { "prettierd", "prettier" },
				lua = { "stylua" },
				rust = { "rustfmt" },
				bash = { "shfmt" },
				sh = { "shfmt" },
				go = { "goimports", "gofmt", stop_after_first = false },
				python = { "black" },
				["_"] = { "trim_whitespace" },
			},
			format_on_save = {
				lsp_format = "fallback",
			},
			formatters = {
				shfmt = {
					prepend_args = { "-i", "2" },
				},
			},
		},
		init = function()
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"saghen/blink.cmp",
			"b0o/schemastore.nvim",
		},
		config = function()
			require("timopruesse.lsp")
		end,
	},
	{ "williamboman/mason.nvim", lazy = true },
	{ "williamboman/mason-lspconfig.nvim", lazy = true },
	{
		"mrcjkb/rustaceanvim",
		version = "^4",
		ft = { "rust" },
		lazy = true,
		config = function()
			vim.g.rustaceanvim = {
				server = {
					on_attach = function(_, bufnr)
						require("timopruesse.keymaps.rust").setup(bufnr)
					end,
					default_settings = {
						rust = {
							unstable_features = true,
							build_on_save = false,
							all_features = true,
							auto_inlay_hints = true,
						},
						["rust-analyzer"] = {
							checkOnSave = {
								command = "clippy",
							},
							diagnostics = {
								enable = true,
								disabled = { "unresolved-proc-macro" },
								enableExperimental = true,
							},
						},
					},
				},
			}
			require("timopruesse.autocommands.rust")
		end,
	},
	{ "nvim-lua/plenary.nvim", lazy = true },
	{ "nvim-treesitter/nvim-treesitter-context", lazy = true },
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-context",
		},
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
				"dart",
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
	{
		"saghen/blink.cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		version = "*",
		dependencies = { "L3MON4D3/LuaSnip", "windwp/nvim-autopairs" },
		opts = {
			snippets = { preset = "luasnip" },
			keymap = {
				preset = "enter",
				["<C-p>"] = { "select_prev", "fallback" },
				["<C-n>"] = { "select_next", "fallback" },
				["<C-u>"] = { "scroll_documentation_up", "fallback" },
				["<C-d>"] = { "scroll_documentation_down", "fallback" },
				["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-x>"] = { "cancel", "fallback" },
			},
			sources = {
				default = { "lsp", "snippets", "path", "buffer" },
				providers = {
					lsp = { name = "LSP" },
					snippets = { name = "SNIP" },
					path = { name = "PATH" },
					buffer = { name = "BUF", min_keyword_length = 4 },
				},
			},
			completion = {
				ghost_text = { enabled = true },
				accept = { auto_brackets = { enabled = true } },
				documentation = { auto_show = true, auto_show_delay_ms = 200 },
			},
			signature = { enabled = true },
			cmdline = {
				keymap = { preset = "cmdline" },
				completion = { menu = { auto_show = true } },
			},
		},
		opts_extend = { "sources.default" },
	},
	{
		"j-hui/fidget.nvim",
		event = "LspAttach",
		config = function()
			require("fidget").setup({
				notification = {
					override_vim_notify = true,
					window = {
						winblend = 0,
					},
				},
			})
		end,
	},
	{
		"L3MON4D3/LuaSnip",
		config = function()
			local ls = require("luasnip")
			local types = require("luasnip.util.types")

			ls.config.set_config({
				history = true,
				updateevents = "TextChanged,TextChangedI",
				enable_autosnippets = true,
				ext_opts = {
					[types.choiceNode] = {
						active = {
							virt_text = { { " ← choice", "NonTest" } },
						},
					},
				},
			})
		end,
		lazy = true,
	},
	{ "kevinhwang91/nvim-bqf", ft = { "qf" } },
	{ "MunifTanjim/nui.nvim", event = "BufEnter package.json" },
	{
		"vuki656/package-info.nvim",
		event = "BufRead package.json",
		dependencies = { "MunifTanjim/nui.nvim" },
		config = function()
			local package_info = require("package-info")
			local key = require("timopruesse.helpers.keymap")

			package_info.setup({ autostart = true })

			key.nmap("<leader>pu", package_info.update)
			key.nmap("<leader>pd", package_info.delete)
			key.nmap("<leader>pi", package_info.install)
			key.nmap("<leader>pc", package_info.change_version)
		end,
	},
	{
		"saecki/crates.nvim",
		event = "BufRead Cargo.toml",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("crates").setup()
		end,
		lazy = true,
	},
	{ "fatih/vim-go", lazy = true },
	{
		"akinsho/flutter-tools.nvim",
		ft = "dart",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities.textDocument.completion.completionItem.snippetSupport = true
			capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true
			local ok, blink = pcall(require, "blink.cmp")
			if ok then
				capabilities = blink.get_lsp_capabilities(capabilities)
			end

			require("flutter-tools").setup({
				fvm = true,
				widget_guides = { enabled = false },
				lsp = {
					on_attach = function(_, bufnr)
						require("timopruesse.keymaps.lsp").setup(bufnr)
					end,
					capabilities = capabilities,
					color = {
						enabled = true,
						background = false,
						foreground = false,
						virtual_text = true,
						virtual_text_str = "■",
					},
				},
			})
		end,
	},
	{
		"folke/todo-comments.nvim",
		event = "BufReadPost",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("todo-comments").setup({})
		end,
	},
	{
		"toppair/peek.nvim",
		event = { "VeryLazy" },
		build = "deno task --quiet build:fast",
		config = function()
			-- TODO: remove wslview workaround once the upstream dependency is updated
			require("peek").setup({ app = "wslview" })
			vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
			vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
		end,
		lazy = true,
	},
	{ "tpope/vim-dadbod", lazy = true },
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = { "tpope/vim-dadbod" },
		cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		config = function()
			local wk = require("which-key")
			wk.setup({})
			wk.add({
				{ "<leader>v", group = "LSP" },
				{ "<leader>z", group = "Claude" },
				{ "<leader>p", group = "Search/Package" },
				{ "<leader>b", group = "Buffers" },
				{ "<leader>t", group = "Todo/Test" },
				{ "<leader>d", group = "Diagnostics" },
				{ "<leader>y", group = "Yank" },
				{ "<leader>g", group = "Git" },
				{ "<leader>c", group = "Commits" },
				{ "<leader>r", group = "References" },
				{ "<leader>s", group = "Swap" },
			})
		end,
	},
	{
		"kylechui/nvim-surround",
		version = "*",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			require("nvim-autopairs").setup({
				check_ts = true,
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		event = "BufReadPost",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("nvim-treesitter-textobjects").setup({
				select = {
					lookahead = true,
					keymaps = {
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						["ac"] = "@class.outer",
						["ic"] = "@class.inner",
						["aa"] = "@parameter.outer",
						["ia"] = "@parameter.inner",
						["ai"] = "@conditional.outer",
						["ii"] = "@conditional.inner",
						["al"] = "@loop.outer",
						["il"] = "@loop.inner",
					},
				},
				move = {
					set_jumps = true,
					goto_next_start = {
						["]m"] = "@function.outer",
						["]a"] = "@parameter.outer",
					},
					goto_next_end = {
						["]M"] = "@function.outer",
					},
					goto_previous_start = {
						["[m"] = "@function.outer",
						["[a"] = "@parameter.outer",
					},
					goto_previous_end = {
						["[M"] = "@function.outer",
					},
				},
				swap = {
					swap_next = {
						["<leader>sn"] = "@parameter.inner",
					},
					swap_previous = {
						["<leader>sp"] = "@parameter.inner",
					},
				},
			})
		end,
	},
	{ "b0o/schemastore.nvim", lazy = true },
})

require("timopruesse.init")
