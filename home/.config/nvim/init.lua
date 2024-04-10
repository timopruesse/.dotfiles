local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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
		config = function()
			vim.opt.laststatus = 3

			local function tabnine_status()
				return require("tabnine.status").status()
			end

			require("staline").setup({
				sections = {
					left = { "  ", "mode", "[", "cwd", "]", "file_name", "lsp", "line_column" },
					mid = { "git_branch" },
					right = { tabnine_status, "  ", "lsp_name", "  " },
				},
				defaults = {
					true_colors = true,
					line_column = "| %-02c",
				},
			})
		end,
	},
	{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },
	{ "stevearc/dressing.nvim", event = "VeryLazy" },
	{ "nvim-tree/nvim-web-devicons", lazy = true },
	{ "mbbill/undotree", lazy = true },
	{
		"andymass/vim-matchup",
		config = function()
			vim.g.matchup_matchparen_offscreen = { method = "popup" }
		end,
	},
	{ "ThePrimeagen/harpoon" },
	{
		"ThePrimeagen/refactoring.nvim",
		config = function()
			require("refactoring").setup({})
		end,
		lazy = true,
	},
	{
		"terrortylor/nvim-comment",
		config = function()
			require("nvim_comment").setup()
		end,
	},
	{ "JoosepAlviste/nvim-ts-context-commentstring" },
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
					require("conform").format({ async = true, lsp_fallback = true })
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
				go = { "goimports", "gofmt" },
				python = { "black" },
				["_"] = { "trim_whitespace" },
			},
			format_on_save = {
				async = true,
				lsp_fallback = true,
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
	{ "williamboman/mason.nvim" },
	{ "neovim/nvim-lspconfig", dependencies = { "simrat39/rust-tools.nvim" } },
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
		ensure_installed = {
			"lua_ls",
			"rust_analyzer",
			"bashls",
			"cssls",
			"eslint",
			"gopls",
			"html",
			"jsonls",
			"tsserver",
			"intelephense",
			"pest_ls",
			"jedi_language_server",
			"somesass_ls",
			"svelte",
			"tailwindcss",
			"yamlls",
		},
	},
	{ "simrat39/rust-tools.nvim", lazy = true },
	{
		"nvimdev/lspsaga.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
			"neovim/nvim-lspconfig",
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
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter-context",
		},
		config = function()
			require("nvim-treesitter.configs").setup({
				auto_install = true,
				ensure_installed = {
					"lua",
					"rust",
					"html",
					"css",
					"scss",
					"svelte",
					"php",
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
				},
				highlight = { enable = true },
				incremental_selection = { enable = true },
				textobjects = { enable = true },
				matchup = {
					enable = true,
				},
			})
			require("nvim-treesitter.parsers").get_parser_configs().markdown.filetype_to_parsername = "octo"
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
		},
		lazy = true,
	},
	{
		"tzachar/cmp-tabnine",
		build = "./install.sh",
		dependencies = "hrsh7th/nvim-cmp",
		lazy = true,
	},
	{ "codota/tabnine-nvim", build = "./dl_binaries.sh", lazy = true },
	{
		"simrat39/symbols-outline.nvim",
		config = function()
			require("symbols-outline").setup({
				highlight_hovered_item = true,
				show_guides = true,
			})
		end,
		lazy = true,
	},
	{
		"j-hui/fidget.nvim",
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
	{ "junegunn/fzf", dir = "~/.fzf", build = "./install --all", lazy = true },
	{ "junegunn/fzf.vim", dependencies = { "junegunn/fzf" }, lazy = true },
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
	{ "leafOfTree/vim-svelte-plugin", lazy = true },
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
		dependencies = { "nvim-lua/plenary.nvim" },
		lazy = true,
	},
	{ "ambv/black", lazy = true },
	{
		"folke/todo-comments.nvim",
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
			require("peek").setup()
			vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
			vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
		end,
		lazy = true,
	},
	{ "tpope/vim-dadbod", lazy = true },
	{ "kristijanhusak/vim-dadbod-ui", dependencies = { "tpope/vim-dadbod" }, lazy = true },
})

require("timopruesse.init")
