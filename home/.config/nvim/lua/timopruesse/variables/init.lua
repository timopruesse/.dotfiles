vim.g.loaded_matchparen = 1

-- disable unneeded providers
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- pin python3 provider to a dedicated venv so we get latest pynvim,
-- bypassing the distro's apt-managed (often stale) python3-pynvim
local nvim_python = vim.fn.expand("~/.local/share/nvim/venv/bin/python")
if vim.fn.executable(nvim_python) == 1 then
    vim.g.python3_host_prog = nvim_python
end

-- pin node provider via fnm's stable "default" alias so version bumps
-- don't break the path, and skip auto-detection (which can fail with fnm).
-- nosuf=1 is required because wildignore filters out anything in node_modules.
local nvim_node_host = vim.fn.expand("~/.local/share/fnm/aliases/default/lib/node_modules/neovim/bin/cli.js", true)
if vim.fn.filereadable(nvim_node_host) == 1 then
    vim.g.node_host_prog = nvim_node_host
end

-- netrw
vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
vim.g.netrw_localrmdir = "rm -r"
