require("timopruesse.sets")
require("timopruesse.variables.init")
require("timopruesse.keymaps.init")
require("timopruesse.autocommands.init")
require("timopruesse.snippets.init")


require("tabnine").setup({
    disable_auto_comment = true,
    accept_keymap = "<Tab>",
    dismiss_keymap = "<C-]>",
    debounce_ms = 800,
    suggestion_color = { gui = "#808080", cterm = 244 },
    exclude_filetypes = { "TelescopePrompt" },
})
