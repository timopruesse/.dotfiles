local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt

local s = ls.s
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node

ls.add_snippets("rust", {
	s(
		"modtest",
		fmt(
			[[
            #[cfg(test)]
            mod test {{
            {}

                {}
            }}
            ]],
			{
				c(1, { t("  use super::*;"), t("") }),
				i(0),
			}
		)
	),
	s(
		{ trig = "test" },
		fmt(
			[[
            #[test]
            fn {}(){{
                {}
            }}
            ]],
			{
				i(1, "testname"),
				i(0),
			}
		)
	),
	s("eq", fmt("assert_eq!({}, {});{}", { i(1), i(2), i(0) })),
})
