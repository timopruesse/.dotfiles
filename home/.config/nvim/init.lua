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

-- Ensure nvm-managed node is in PATH (nvm is not loaded in non-interactive shells,
-- so LSP servers and mason tools that need node won't find it otherwise)
do
	local node_dirs = vim.fn.glob(vim.fn.expand("~/.nvm/versions/node/*/bin"), false, true)
	if #node_dirs > 0 then
		table.sort(node_dirs)
		vim.env.PATH = node_dirs[#node_dirs] .. ":" .. vim.env.PATH
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
		"tamton-aquib/staline.nvim",
		event = "VeryLazy",
		config = function()
			vim.opt.laststatus = 3

			require("staline").setup({
				sections = {
					left = { "  ", "mode", " ", "file_name", " ", "lsp" },
					mid = { "git_branch" },
					right = {
						function()
							local diff = vim.b.gitsigns_status
							if diff and diff ~= "" then
								return diff .. " | "
							end
							return ""
						end,
						"lsp_name",
						" ",
						"line_column",
						"  ",
					},
				},
				defaults = {
					true_colors = true,
					line_column = "[%l/%L] %-02c",
					branch_symbol = " ",
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
		"ThePrimeagen/refactoring.nvim",
		config = function()
			require("refactoring").setup({})
		end,
		lazy = true,
	},
	{
		"numToStr/Comment.nvim",
		event = "BufReadPost",
		config = function()
			require("Comment").setup()
		end,
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"BurntSushi/ripgrep",
			"nvim-telescope/telescope-fzy-native.nvim",
		},
		config = function()
			require("timopruesse.telescope")
		end,
		lazy = true,
	},
	{
		"nvim-telescope/telescope-file-browser.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim",
		},
		lazy = true,
	},
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
			formatters_by_ft = {
				javascript = { { "prettierd", "prettier" } },
				typescript = { { "prettierd", "prettier" } },
				javascriptreact = { { "prettierd", "prettier" } },
				typescriptreact = { { "prettierd", "prettier" } },
				svelte = { { "prettierd", "prettier" } },
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
				go = { "goimports", "gofmt" },
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
			"hrsh7th/cmp-nvim-lsp",
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
	{
		"nvimdev/lspsaga.nvim",
		event = "LspAttach",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("lspsaga").setup({})
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
		end,
	},
	{ "hrsh7th/cmp-nvim-lsp", lazy = true },
	{ "hrsh7th/cmp-buffer", lazy = true },
	{ "hrsh7th/cmp-cmdline", lazy = true },
	{ "hrsh7th/cmp-nvim-lsp-document-symbol", lazy = true },
	{ "hrsh7th/cmp-nvim-lsp-signature-help", lazy = true },
	{ "hrsh7th/cmp-nvim-lua", lazy = true },
	{ "hrsh7th/cmp-path", lazy = true },
	{ "hrsh7th/cmp-calc", lazy = true },
	{ "hrsh7th/cmp-emoji", lazy = true },
	{ "petertriho/cmp-git", lazy = true },
	{ "David-Kunz/cmp-npm", lazy = true },
	{ "saadparwaiz1/cmp_luasnip", lazy = true, dependencies = { "L3MON4D3/LuaSnip" } },
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp-document-symbol",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-calc",
			"hrsh7th/cmp-emoji",
			"petertriho/cmp-git",
			"David-Kunz/cmp-npm",
			"saadparwaiz1/cmp_luasnip",
			"windwp/nvim-autopairs",
		},
		config = function()
			local cmp = require("cmp")
			local source_mapping = {
				buffer = "[BUF]",
				nvim_lsp = "[LSP]",
				nvim_lua = "[LUA]",
				path = "[PATH]",
			}

			cmp.setup({
				experimental = { ghost_text = true },
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-u>"] = cmp.mapping.scroll_docs(-4),
					["<C-d>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<C-x>"] = cmp.mapping({
						i = cmp.mapping.abort(),
						c = cmp.mapping.close(),
					}),
				}),
				formatting = {
					format = function(entry, vim_item)
						vim_item.menu = source_mapping[entry.source.name]
						return vim_item
					end,
				},
				sources = {
					{ name = "nvim_lsp_signature_help" },
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
					{ name = "nvim_lua" },
					{ name = "emoji" },
					{ name = "npm", keyword_length = 3 },
					{ name = "buffer", keyword_length = 4 },
				},
			})

			cmp.setup.cmdline("/", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "nvim_lsp_document_symbol" },
					{ name = "buffer" },
				},
			})

			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{ name = "cmdline" },
				}),
			})

			cmp.setup.filetype("gitcommit", {
				sources = cmp.config.sources({
					{ name = "git" },
				}, {
					{ name = "buffer" },
				}),
			})

			require("cmp_git").setup({})

			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
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
	{ "junegunn/fzf", build = "./install --all", lazy = true },
	{
		"junegunn/fzf.vim",
		dependencies = { "junegunn/fzf" },
		cmd = { "Files", "Rg", "Buffers", "BLines", "GFiles", "Commits", "Commands" },
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
			local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
			if ok then
				capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
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
	{ "tpope/vim-obsession", lazy = true },
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
