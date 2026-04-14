local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt

local s = ls.s
local i = ls.insert_node

ls.add_snippets("typescript", {
	s(
		"int",
		fmt(
			[[
			interface {} {{
				{}
			}}
			]],
			{ i(1, "Name"), i(0) }
		)
	),
	s(
		"eint",
		fmt(
			[[
			export interface {} {{
				{}
			}}
			]],
			{ i(1, "Name"), i(0) }
		)
	),
	s(
		"tp",
		fmt([[type {} = {};]], {
			i(1, "Name"),
			i(0),
		})
	),
	s(
		"etp",
		fmt([[export type {} = {};]], {
			i(1, "Name"),
			i(0),
		})
	),
	s(
		"en",
		fmt(
			[[
			enum {} {{
				{}
			}}
			]],
			{ i(1, "Name"), i(0) }
		)
	),
})
