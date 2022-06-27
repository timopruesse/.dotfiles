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
})
