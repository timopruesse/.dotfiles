local prefix = "<leader>i"

return {
	{
		"omaclaren/pi-nvim-context",
		tag = "v0.4.0",
		event = "VeryLazy",
		main = "pi-nvim-context",
		opts = {
			accept_with_tab = false,
			-- The upstream prefix guards Visual mode but does not relocate the default mappings.
			keymaps = {
				prefix = prefix,
				pick = prefix .. "p",
				file = prefix .. "f",
				location = prefix .. "l",
				selection = prefix .. "s",
				selection_comment = prefix .. "S",
				diagnostics = prefix .. "d",
				buffer = prefix .. "b",
				status = prefix .. "i",
				annotation_header = false,
				suggest = prefix .. "c",
				guided = false,
				rewrite = prefix .. "r",
				accept = prefix .. "a",
				again = false,
				dismiss = prefix .. "x",
				preview = prefix .. "v",
			},
		},
	},
}
