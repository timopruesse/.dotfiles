local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

local cmp = require("cmp")
local source_mapping = {
	buffer = "[BUF]",
	nvim_lsp = "[LSP]",
	nvim_lua = "[LUA]",
	path = "[PATH]",
}

cmp.setup({
	experimental = {
		ghost_text = true,
	},
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
	sources = require("cmp").config.sources({
		{ name = "git" },
	}, {
		{ name = "buffer" },
	}),
})

require("cmp_git").setup({})

local function on_attach(client, bufnr)
	require("timopruesse.keymaps.lsp").setup(bufnr)
end

local function config(_config)
	_config = _config or {}
	local server_on_attach = _config.on_attach
	_config.on_attach = function(client, bufnr)
		on_attach(client, bufnr)
		if server_on_attach then
			server_on_attach(client, bufnr)
		end
	end
	return vim.tbl_deep_extend("force", {
		capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities),
	}, _config)
end

require("mason").setup({
	max_concurrent_installers = 6,
})
require("mason-lspconfig").setup({
	automatic_installation = true,
	ensure_installed = {
		"lua_ls",
		"bashls",
		"cssls",
		"eslint",
		"gopls",
		"html",
		"jsonls",
		"ts_ls",
		"jedi_language_server",
		"somesass_ls",
		"svelte",
		"tailwindcss",
		"yamlls",
	},
})

local lsp = require("lspconfig")

lsp.ts_ls.setup(config({
	on_attach = function(_, bufnr)
		require("timopruesse.keymaps.node").setup(bufnr)
	end,
	settings = {
		typescript = {
			inlayHints = {
				includeInlayParameterNameHints = "all",
				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayVariableTypeHints = true,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayEnumMemberValueHints = true,
			},
		},
		javascript = {
			inlayHints = {
				includeInlayParameterNameHints = "all",
				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayVariableTypeHints = true,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayEnumMemberValueHints = true,
			},
		},
	},
}))

lsp.jedi_language_server.setup(config())

lsp.svelte.setup(config({
	on_attach = function(_, bufnr)
		require("timopruesse.keymaps.node").setup(bufnr)
	end,
}))

lsp.cssls.setup(config())
lsp.tailwindcss.setup(config({
	filetypes = {
		"astro",
		"astro-markdown",
		"edge",
		"eelixir",
		"elixir",
		"gohtml",
		"gohtmltmpl",
		"haml",
		"handlebars",
		"hbs",
		"html",
		"html-eex",
		"heex",
		"markdown",
		"mdx",
		"mustache",
		"razor",
		"slim",
		"twig",
		"css",
		"less",
		"postcss",
		"sass",
		"scss",
		"stylus",
		"javascriptreact",
		"typescriptreact",
		"vue",
		"svelte",
	},
}))

require("flutter-tools").setup(config({
	fvm = true,
	widget_guides = {
		enabled = false,
	},
	lsp = {
		color = {
			enabled = true,
			background = false,
			foreground = false,
			virtual_text = true,
			virtual_text_str = "■",
		},
	},
}))

lsp.gopls.setup(config({
	cmd = { "gopls", "serve" },
	settings = {
		gopls = {
			analyses = {
				unusedparams = true,
			},
			staticcheck = true,
		},
	},
}))

lsp.lua_ls.setup(config({
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			diagnostics = { globals = { "vim" } },
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
			hint = { enable = true },
			telemetry = { enable = false },
		},
	},
}))
