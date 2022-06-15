-- completion
vim.g.completion_matching_strategy_list = { "exact", "substring", "fuzzy" }

-- NERDTree
vim.g.NERDTreeWinSize = 80
vim.g.NERDTreeWinPos = "right"

-- netrw
vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
vim.g.netrw_localrmdir = "rm -r"

-- svelte
vim.g.vim_svelte_plugin_use_typescript = 1
vim.g.vim_svelte_plugin_use_sass = 1

-- additional variables
require("timopruesse.variables.neoformat")
