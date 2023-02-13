vim.g.gruvbox_transparent_bg = 1
vim.g.gruvbox_contrast_dark = "hard"
vim.g.gruvbox_invert_selection = "0"

vim.cmd("colorscheme moonbow")

vim.api.nvim_set_hl(0, "CursorLine", { bg = "#292929" })
vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#292929" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "CursorLineNR", { bg = "none" })
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "LineNr", { fg = "#5eacd3" })
vim.api.nvim_set_hl(0, "netrwDir", { fg = "#5eacd3" })
vim.api.nvim_set_hl(0, "qfFileName", { fg = "#aed75f" })
vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = "#5eacd3" })
