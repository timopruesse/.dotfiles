require("catppuccin").setup({
    flavour = "mocha",
    transparent_background = true,
    show_end_of_buffer = true,
    term_colors = true,
    default_integrations = true,
    integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = true,
        mini = {
            enabled = true,
            indentscope_color = "",
        },
    },
})

vim.cmd.colorscheme "catppuccin"
