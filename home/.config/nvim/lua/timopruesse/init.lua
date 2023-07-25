require("timopruesse.sets")
require("timopruesse.theme")
require("timopruesse.variables.init")
require("timopruesse.keymaps.init")
require("timopruesse.autocommands.init")
require("timopruesse.statusline")
require("timopruesse.lsp")
---@diagnostic disable-next-line: different-requires
require("timopruesse.snippets.init")

require("formatter").setup({
	logging = true,
	log_level = vim.log.levels.WARN,
	filetype = {
		["*"] = {
			require("formatter.filetypes.any").remove_trailing_whitespace,
		},
		css = {
			require("formatter.filetypes.css").prettierd,
		},
		dart = {
			require("formatter.filetypes.dart").dartformat,
		},
		go = {
			require("formatter.filetypes.go").gofmt,
		},
		html = {
			require("formatter.filetypes.html").prettierd,
		},
		javascript = {
			require("formatter.filetypes.javascript").prettierd,
		},
		javascriptreact = {
			require("formatter.filetypes.javascriptreact").prettierd,
		},
		json = {
			require("formatter.filetypes.json").prettierd,
		},
		kotlin = {
			require("formatter.filetypes.kotlin").ktlint,
		},
		lua = {
			require("formatter.filetypes.lua").stylua,
		},
		markdown = {
			require("formatter.filetypes.markdown").prettierd,
		},
		php = {
			require("formatter.filetypes.php").php_cs_fixer,
		},
		python = {
			require("formatter.filetypes.python").black,
		},
		rust = {
			require("formatter.filetypes.rust").rustfmt,
		},
        sh = {
            require("formatter.filetypes.sh").shfmt,
        },
        sql = {
            require("formatter.filetypes.sql").pgformat,
        },
		svelte = {
			require("formatter.filetypes.svelte").prettier,
		},
		typescript = {
			require("formatter.filetypes.typescript").prettierd,
		},
		typescriptreact = {
			require("formatter.filetypes.typescriptreact").prettierd,
		},
		vue = {
			require("formatter.filetypes.vue").prettier,
		},
		yaml = {
			require("formatter.filetypes.yaml").yamlfmt,
		},
	},
})
