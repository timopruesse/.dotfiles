vim.opt.laststatus = 3

local gruvbox = {
	n = "#a89984",
	i = "#83a598",
	c = "#8fbf7f",
	v = "#d65d0e",
	V = "#fe8019",
	s = "#d65d0e",
	S = "#d65d0e",
	r = "#8ec07c",
	R = "#8ec07c",
	t = "#689d6a",
}

local function tabnine_status()
	return require("tabnine.status").status()
end

require("staline").setup({
	sections = {
		left = { "  ", "mode", "[", "cwd", "]", "file_name", "lsp", "line_column" },
		mid = { "branch" },
		right = { tabnine_status, "  ", "lsp_name", "  " },
	},
	mode_colors = gruvbox,
	defaults = {
		true_colors = true,
		line_column = "| %-02c",
	},
})
