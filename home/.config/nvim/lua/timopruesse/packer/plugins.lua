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

	use("mbbill/undotree")
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
	use("terrortylor/nvim-comment")
	use("JoosepAlviste/nvim-ts-context-commentstring")

	-- editorconfig
	use("gpanders/editorconfig.nvim")

	-- telescope
	use("BurntSushi/ripgrep")
	use({
		"nvim-telescope/telescope.nvim",
		requires = { { "nvim-lua/plenary.nvim" } },
	})
	use("nvim-telescope/telescope-fzy-native.nvim")
	use("nvim-lua/popup.nvim")

	-- lsp + autocomplete
	use("neovim/nvim-lspconfig")
	use({ "tami5/lspsaga.nvim", branch = "main" })
	use("nvim-lua/lsp_extensions.nvim")
	use("hrsh7th/nvim-cmp")
	use("hrsh7th/cmp-cmdline")
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/cmp-nvim-lsp-document-symbol")
	use("hrsh7th/cmp-nvim-lsp-signature-help")
	use("hrsh7th/cmp-nvim-lua")
	use("hrsh7th/cmp-vsnip")
	use("hrsh7th/vim-vsnip")
	use("hrsh7th/vim-vsnip-integ")
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

	-- treesitter
	use({
		"nvim-treesitter/nvim-treesitter",
		run = function()
			vim.api.nvim_command("TSInstall html")
			vim.api.nvim_command("TSInstall css")
			vim.api.nvim_command("TSInstall scss")
			vim.api.nvim_command("TSInstall svelte")
			vim.api.nvim_command("TSInstall rust")
			vim.api.nvim_command("TSInstall php")
			vim.api.nvim_command("TSInstall json")
			vim.api.nvim_command("TSInstall yaml")
			vim.api.nvim_command("TSInstall javascript")
			vim.api.nvim_command("TSInstall typescript")
			vim.api.nvim_command("TSInstall lua")
			vim.api.nvim_command("TSInstall go")
			vim.api.nvim_command("TSInstall dockerfile")
			vim.api.nvim_command("TSInstall python")
			vim.api.nvim_command("TSInstall dart")
			vim.api.nvim_command("TSInstall markdown")
			vim.api.nvim_command("TSInstall tsx")
			vim.api.nvim_command("TSInstall vim")
			vim.api.nvim_command("TSInstall toml")
			vim.api.nvim_command("TSInstall regex")
		end,
		config = function()
			require("nvim-treesitter.configs").setup({
				highlight = { enable = true },
				incremental_selection = { enable = true },
				textobjects = { enable = true },
			})
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

	-- copilot
	use("github/copilot.vim")

	-- github
	-- use({
	-- 	"pwntester/octo.nvim",
	-- 	requires = {
	-- 		"nvim-lua/plenary.nvim",
	-- 		"nvim-telescope/telescope.nvim",
	-- 		"kyazdani42/nvim-web-devicons",
	-- 	},
	-- 	config = function()
	-- 		require("octo").setup()
	-- 	end,
	-- })

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
end)
