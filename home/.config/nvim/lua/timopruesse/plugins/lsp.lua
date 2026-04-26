return {
	{ "williamboman/mason.nvim", lazy = true },
	{ "williamboman/mason-lspconfig.nvim", lazy = true },
	{ "b0o/schemastore.nvim", lazy = true },
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
				shfmt = { prepend_args = { "-i", "2" } },
			},
		},
		init = function()
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
	},
}
