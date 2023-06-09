-- formatter
vim.g.neoformat_php_phpcsfixer = {
	exe = "php-cs-fixer",
	args = { "fix", "-q" },
	replace = 1,
}
