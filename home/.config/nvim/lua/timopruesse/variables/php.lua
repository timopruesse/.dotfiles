-- TODO: Replace ale with lua alternative...

-- formatter
vim.g.neoformat_php_phpcsfixer = {
	exe = "php-cs-fixer",
	args = { "fix", "-q" },
	replace = 1,
}

-- ale
vim.g.ale_lint_on_text_changed = "never"
vim.g.ale_lint_on_enter = 0
vim.g.ale_echo_msg_format = "[%linter%] %s [%severity%]"
vim.g.ale_open_list = 1
vim.g.ale_keep_list_window_open = 0
vim.g.ale_set_quickfix = 0
vim.g.ale_list_window_size = 5
vim.g.ale_php_phpcbf_standard = "PSR2"
vim.g.ale_php_phpcs_standard = "phpcs.xml.dist"
vim.g.ale_php_phpmd_ruleset = "phpmd.xml"
vim.g.ale_fixers = {
	lua = { "remove_trailing_lines", "trim_whitespace" },
	php = { "phpcbf", "php_cs_fixer", "remove_trailing_lines", "trim_whitespace" },
}
vim.g.ale_fix_on_save = 1
