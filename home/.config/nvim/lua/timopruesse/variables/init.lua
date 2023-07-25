vim.g.loaded_matchparen = 1

-- disable unneeded providers
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- completion
vim.g.completion_matching_strategy_list = { "exact", "substring", "fuzzy" }

-- netrw
vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
vim.g.netrw_localrmdir = "rm -r"

-- svelte
vim.g.vim_svelte_plugin_use_typescript = 1
vim.g.vim_svelte_plugin_use_sass = 1

-- additional variables
require("timopruesse.variables.php")
