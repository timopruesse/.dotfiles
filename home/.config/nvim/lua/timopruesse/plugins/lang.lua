return {
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
							checkOnSave = { command = "clippy" },
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
	{ "fatih/vim-go", lazy = true },
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
		lazy = true,
		config = function()
			require("crates").setup()
		end,
	},
}
