local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

local s = ls.s
local i = ls.insert_node

ls.add_snippets("javascript", {
	s(
		"cl",
		fmt([[console.log("{}", {});]], {
			rep(1),
			i(1),
		})
	),
	s(
		"cw",
		fmt([[console.warn("{}", {});]], {
			rep(1),
			i(1),
		})
	),
	s(
		"ce",
		fmt([[console.error("{}", {});]], {
			rep(1),
			i(1),
		})
	),
	s(
		"af",
		fmt(
			[[
			const {} = ({}) => {{
				{}
			}};
			]],
			{ i(1, "name"), i(2), i(0) }
		)
	),
	s(
		"aaf",
		fmt(
			[[
			const {} = async ({}) => {{
				{}
			}};
			]],
			{ i(1, "name"), i(2), i(0) }
		)
	),
	s(
		"imp",
		fmt([[import {{ {} }} from "{}";]], {
			i(2),
			i(1),
		})
	),
	s(
		"impd",
		fmt([[import {} from "{}";]], {
			i(2),
			i(1),
		})
	),
	s(
		"ef",
		fmt(
			[[
			export function {}({}) {{
				{}
			}}
			]],
			{ i(1, "name"), i(2), i(0) }
		)
	),
	s(
		"edf",
		fmt(
			[[
			export default function {}({}) {{
				{}
			}}
			]],
			{ i(1, "name"), i(2), i(0) }
		)
	),
	s(
		"eaf",
		fmt(
			[[
			export const {} = ({}) => {{
				{}
			}};
			]],
			{ i(1, "name"), i(2), i(0) }
		)
	),
	s(
		"try",
		fmt(
			[[
			try {{
				{}
			}} catch ({}) {{
				{}
			}}
			]],
			{ i(1), i(2, "error"), i(0) }
		)
	),
	s(
		"prom",
		fmt(
			[[
			new Promise(({}, {}) => {{
				{}
			}})
			]],
			{ i(1, "resolve"), i(2, "reject"), i(0) }
		)
	),
	s(
		"desc",
		fmt(
			[[
			describe("{}", () => {{
				{}
			}});
			]],
			{ i(1), i(0) }
		)
	),
	s(
		"it",
		fmt(
			[[
			it("{}", () => {{
				{}
			}});
			]],
			{ i(1), i(0) }
		)
	),
	s(
		"ita",
		fmt(
			[[
			it("{}", async () => {{
				{}
			}});
			]],
			{ i(1), i(0) }
		)
	),
})
