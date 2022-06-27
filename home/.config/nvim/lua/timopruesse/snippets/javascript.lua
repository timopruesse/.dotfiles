local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local h = require("timopruesse.helpers.snippets")

local s = ls.s
local i = ls.insert_node

ls.add_snippets("javascript", {
	s(
		"cl",
		fmt([[console.log("{}", {});]], {
			h.mirror(1),
			i(1),
		})
	),
})
