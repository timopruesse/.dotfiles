-- format unknown file types
vim.g.neoformat_basic_format_align = 1
vim.g.neoformat_basic_format_retab = 1
vim.g.neoformat_basic_format_trim = 1

vim.g.neoformat_enabled_cmake = { "cmakeformat" }
vim.g.neoformat_enabled_cpp = { "uncrustify", "clangformat", "astyle" }
vim.g.neoformat_enabled_cs = { "uncrustify", "astyle", "clangformat" }
vim.g.neoformat_enabled_css = {
	"prettierd",
	"prettier",
	"stylelint",
	"stylefmt",
}
vim.g.neoformat_enabled_csv = { "prettydiff" }
vim.g.neoformat_enabled_dart = { "dartfmt", "format" }
vim.g.neoformat_enabled_go = { "goimports", "gofmt", "gofumports", "gofumpt" }
vim.g.neoformat_enabled_graphql = { "prettierd", "prettier" }
vim.g.neoformat_enabled_html = { "prettierd", "prettier", "htmlbeautify", "tidy", "prettydiff" }
vim.g.neoformat_enabled_javascript = {
	"prettierd",
	"prettier",
	"prettiereslint",
	"eslint_d",
}
vim.g.neoformat_enabled_javascriptreact = {
	"prettierd",
	"prettier",
	"prettiereslint",
	"eslint_d",
}
vim.g.neoformat_enabled_json = { "prettierd", "prettier" }
vim.g.neoformat_enabled_markdown = { "prettierd", "prettier" }
vim.g.neoformat_enabled_lua = { "luaformatter", "luafmt", "luaformat", "stylua" }
vim.g.neoformat_enabled_nginx = { "nginxbeautifier" }
vim.g.neoformat_enabled_php = { "laravel-pint", "php-cs-fixer" }
vim.g.neoformat_enabled_python = { "yapf", "autopep8", "black", "isort", "docformatter", "pyment", "pydevf" }
vim.g.neoformat_enabled_rust = { "rustfmt" }
vim.g.neoformat_enabled_scss = {
	"prettierd",
	"prettier",
	"sassconvert",
	"stylelint",
	"stylefmt",
}
vim.g.neoformat_enabled_sql = { "sqlformat", "pg_format", "sqlfmt" }
vim.g.neoformat_enabled_svelte = { "prettierd", "prettier" }
vim.g.neoformat_enabled_typescript = {
	"prettierd",
	"prettier",
	"prettiereslint",
	"eslint_d",
}
vim.g.neoformat_enabled_typescriptreact = {
	"prettierd",
	"prettier",
	"prettiereslint",
	"eslint_d",
}
vim.g.neoformat_enabled_toml = { "taplo" }
vim.g.neoformat_enabled_vue = { "prettierd", "prettier" }
vim.g.neoformat_enabled_yaml = { "prettierd", "prettier", "pyaml" }
vim.g.neoformat_enabled_zsh = { "shfmt" }
