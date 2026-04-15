local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true

local cmp_capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

-- Shared on_attach: generic LSP keymaps registered buffer-locally for every server
local function on_attach(client, bufnr)
	require("timopruesse.keymaps.lsp").setup(bufnr)
end

-- Global defaults applied to all LSP servers
vim.lsp.config("*", {
	capabilities = cmp_capabilities,
	on_attach = on_attach,
})

-- ts_ls: inlay hints + node keymaps
vim.lsp.config("ts_ls", {
	on_attach = function(client, bufnr)
		on_attach(client, bufnr)
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
})

-- svelte: node keymaps
vim.lsp.config("svelte", {
	on_attach = function(client, bufnr)
		on_attach(client, bufnr)
		require("timopruesse.keymaps.node").setup(bufnr)
	end,
})

-- tailwindcss: expanded filetype list
vim.lsp.config("tailwindcss", {
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
})

-- gopls: staticcheck + unused params (no "serve" subcommand — deprecated)
vim.lsp.config("gopls", {
	settings = {
		gopls = {
			analyses = {
				unusedparams = true,
			},
			staticcheck = true,
		},
	},
})

-- lua_ls: runtime/workspace config for nvim development
vim.lsp.config("lua_ls", {
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
})

-- yamlls: schema validation via schemastore
vim.lsp.config("yamlls", {
	settings = {
		yaml = {
			schemaStore = {
				enable = false,
				url = "",
			},
			schemas = require("schemastore").yaml.schemas(),
		},
	},
})

-- jsonls: schema validation via schemastore
vim.lsp.config("jsonls", {
	settings = {
		json = {
			schemas = require("schemastore").json.schemas(),
			validate = { enable = true },
		},
	},
})

require("mason").setup({
	max_concurrent_installers = 6,
})
require("mason-lspconfig").setup({
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
	-- rust_analyzer: managed by rustaceanvim (conflicts if enabled here)
	-- pest_ls: PHP testing LSP, not used
	automatic_enable = {
		exclude = { "rust_analyzer", "pest_ls" },
	},
})
