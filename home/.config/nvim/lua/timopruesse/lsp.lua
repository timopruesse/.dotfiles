---@diagnostic disable: different-requires
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

local cmp = require("cmp")
local source_mapping = {
	buffer = "[BUF]",
	nvim_lsp = "[LSP]",
	nvim_lua = "[LUA]",
	cmp_tabnine = "[T9]",
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
			local menu = source_mapping[entry.source.name]
			if entry.source.name == "cmp_tabnine" then
				if entry.completion_item.data ~= nil and entry.completion_item.data.detail ~= nil then
					menu = entry.completion_item.data.detail .. " " .. menu
				end
				vim_item.kind = "🤖"
			end
			vim_item.menu = menu
			return vim_item
		end,
	},

	sources = {
		{ name = "nvim_lsp_signature_help" },
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
		{ name = "cmp_tabnine" },
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

local tabnine = require("cmp_tabnine.config")
tabnine:setup({
	max_lines = 1000,
	max_num_results = 20,
	sort = true,
	run_on_every_keystroke = true,
	snippet_placeholder = "..",
})

local function config(_config)
	return vim.tbl_deep_extend("force", {
		capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities),
	}, _config or {})
end

-- require("lspconfig").denols.setup({})

require("lspconfig").tsserver.setup(config({
	on_attach = function(client, bufnr)
		require("timopruesse.keymaps.node").setup(bufnr)
		require("timopruesse.autocommands.typescript")
	end,
}))

require("lspconfig").ccls.setup(config())

require("lspconfig").jedi_language_server.setup(config())

require("lspconfig").svelte.setup(config({
	on_attach = function(_, bufnr)
		require("timopruesse.keymaps.node").setup(bufnr)
		require("timopruesse.autocommands.typescript")
	end,
}))

require("lspconfig").cssls.setup(config())
require("lspconfig").tailwindcss.setup(config())

require("lspconfig").solang.setup(config())

require("lspconfig").dartls.setup(config())
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

require("lspconfig").gopls.setup(config({
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

require("lspconfig").pylsp.setup(config())

require("lspconfig").intelephense.setup(config({
	on_attach = function(_, bufnr)
		require("timopruesse.keymaps.php").setup(bufnr)
	end,
}))

require("rust-tools").setup(config({
	tools = {
		inlay_hints = {
			auto = true,
		},
	},
	server = {
		settings = {
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
			},
		},
		on_attach = function(_, bufnr)
			require("timopruesse.keymaps.rust").setup(bufnr)
			require("timopruesse.autocommands.rust")
		end,
	},
}))

local home_dir = vim.fn.expand("$HOME")
local sumneko_root_path = home_dir .. "/lua-language-server"
local sumneko_binary = sumneko_root_path .. "/bin/lua-language-server"

require("lspconfig").sumneko_lua.setup(config({
	cmd = { sumneko_binary, "-E", sumneko_root_path .. "/main.lua" },
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
				path = vim.split(package.path, ";"),
			},
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = {
					[vim.fn.expand("$VIMRUNTIME/lua")] = true,
					[vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
				},
			},
		},
	},
}))
