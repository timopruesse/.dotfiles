local packer = require("packer")
local use = packer.use

packer.startup(function()
	use("wbthomason/packer.nvim")

	-- theme
	use("gruvbox-community/gruvbox")
	use("stevearc/dressing.nvim")

	use("kyazdani42/nvim-web-devicons")
	use({
		"kyazdani42/nvim-tree.lua",
		requires = {
			"kyazdani42/nvim-web-devicons",
		},
		tag = "nightly",
	})

	use("nvim-lua/plenary.nvim")

	-- formatting
	use("sbdchd/neoformat")

	-- debugging
	use("mfussenegger/nvim-dap")

	-- refactoring
	use({
		"ThePrimeagen/refactoring.nvim",
		config = function()
			require("refactoring").setup({})
		end,
	})

	-- harpoon
	use("ThePrimeagen/harpoon")

	-- comments
	use("JoosepAlviste/nvim-ts-context-commentstring")
	use({
		"terrortylor/nvim-comment",
		config = function()
			require("nvim_comment").setup({
				hook = function()
					require("ts_context_commentstring.internal").update_commentstring()
				end,
			})
		end,
	})

	-- telescope
	use("BurntSushi/ripgrep")
	use({
		"nvim-telescope/telescope.nvim",
		requires = { { "nvim-lua/plenary.nvim" } },
		config = function()
			require("timopruesse.telescope")
		end,
	})
	use("nvim-telescope/telescope-fzy-native.nvim")
	use("nvim-lua/popup.nvim")

	-- lsp + autocomplete
	use("neovim/nvim-lspconfig")
	use({
		"tami5/lspsaga.nvim",
		branch = "main",
		config = function()
			require("lspsaga").init_lsp_saga({
				code_action_icon = "",
				code_action_prompt = {
					enable = true,
					sign = true,
					sign_priority = 20,
					virtual_text = false,
				},
			})
		end,
	})
	use("nvim-lua/lsp_extensions.nvim")
	use("hrsh7th/nvim-cmp")
	use("hrsh7th/cmp-cmdline")
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/cmp-nvim-lsp-document-symbol")
	use("hrsh7th/cmp-nvim-lsp-signature-help")
	use("hrsh7th/cmp-nvim-lua")
	use("hrsh7th/cmp-path")
	use("hrsh7th/cmp-buffer")
	use("hrsh7th/cmp-calc")
	use("hrsh7th/cmp-emoji")
	use({ "tzachar/cmp-tabnine", run = "./install.sh", requires = "hrsh7th/nvim-cmp" })
	use("simrat39/symbols-outline.nvim")
	use("petertriho/cmp-git")
	use("David-Kunz/cmp-npm")
	use("j-hui/fidget.nvim")
	use("jose-elias-alvarez/null-ls.nvim")

	-- snippets
	use({
		"L3MON4D3/LuaSnip",
		config = function()
			---@diagnostic disable-next-line: different-requires
			local ls = require("luasnip")
			local types = require("luasnip.util.types")

			ls.config.set_config({
				history = true,
				updateevents = "TextChanged,TextChangedI",
				enable_autosnippets = true,
				ext_opts = {
					[types.choiceNode] = {
						active = {
							virt_text = { { " ← Current", "NonTest" } },
						},
					},
				},
			})
		end,
	})
	use({ "saadparwaiz1/cmp_luasnip", requires = "L3MON4D3/LuaSnip" })

	-- treesitter
	use({
		"nvim-treesitter/nvim-treesitter",
		run = function()
			vim.api.nvim_command("TSUpdate html")
			vim.api.nvim_command("TSUpdate css")
			vim.api.nvim_command("TSUpdate scss")
			vim.api.nvim_command("TSUpdate svelte")
			vim.api.nvim_command("TSUpdate rust")
			vim.api.nvim_command("TSUpdate php")
			vim.api.nvim_command("TSUpdate json")
			vim.api.nvim_command("TSUpdate yaml")
			vim.api.nvim_command("TSUpdate javascript")
			vim.api.nvim_command("TSUpdate typescript")
			vim.api.nvim_command("TSUpdate lua")
			vim.api.nvim_command("TSUpdate go")
			vim.api.nvim_command("TSUpdate dockerfile")
			vim.api.nvim_command("TSUpdate python")
			vim.api.nvim_command("TSUpdate dart")
			vim.api.nvim_command("TSUpdate markdown")
			vim.api.nvim_command("TSUpdate tsx")
			vim.api.nvim_command("TSUpdate vim")
			vim.api.nvim_command("TSUpdate toml")
			vim.api.nvim_command("TSUpdate regex")
		end,
		config = function()
			require("nvim-treesitter.configs").setup({
				highlight = { enable = true },
				incremental_selection = { enable = true },
				textobjects = { enable = true },
				context_commentstring = {
					enable = true,
				},
			})
			require("nvim-treesitter.parsers").get_parser_configs().markdown.filetype_to_parsername = "octo"
		end,
	})
	-- use("nvim-treesitter/playground")

	-- status line
	use("tamton-aquib/staline.nvim")

	-- git
	use({ "sindrets/diffview.nvim", requires = "nvim-lua/plenary.nvim" })
	use({
		"TimUntersberger/neogit",
		requires = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim" },
		config = function()
			require("neogit").setup({
				disable_commit_confirmation = true,
				integrations = { diffview = true },
			})
		end,
	})

	-- quickfix
	use("kevinhwang91/nvim-bqf")

	use("tpope/vim-surround")

	-- fuzzy
	use({ "junegunn/fzf", dir = "~/.fzf", run = "./install --all" })
	use("junegunn/fzf.vim")

	-- npm
	use("MunifTanjim/nui.nvim")
	use({
		"vuki656/package-info.nvim",
		event = { "BufRead package.json" },
		requires = "MunifTanjim/nui.nvim",
		config = function()
			require("package-info").setup()
		end,
	})

	-- ts
	use("jose-elias-alvarez/nvim-lsp-ts-utils")

	-- svelte
	use("leafOfTree/vim-svelte-plugin")

	-- rust
	use("rust-lang/rust.vim")
	use("simrat39/rust-tools.nvim")
	use({
		"saecki/crates.nvim",
		event = { "BufRead Cargo.toml" },
		requires = { { "nvim-lua/plenary.nvim" } },
		config = function()
			require("crates").setup()
		end,
	})

	-- php
	use("w0rp/ale")

	-- go
	use("fatih/vim-go")

	-- python
	use("ambv/black")

	-- todo
	use({
		"folke/todo-comments.nvim",
		requires = "nvim-lua/plenary.nvim",
		config = function()
			require("todo-comments").setup({})
		end,
	})

	-- QOL
	use({
		"arnamak/stay-centered.nvim",
		config = function()
			require("stay-centered")
		end,
	})
	use("hrsh7th/nvim-pasta")
	use("antoinemadec/FixCursorHold.nvim")

	-- markdown
	use({ "ellisonleao/glow.nvim", branch = "main" })

	-- databases
	use("tpope/vim-dadbod")
	use({ "kristijanhusak/vim-dadbod-ui", requires = "tpope/vim-dadbod" })
end)
