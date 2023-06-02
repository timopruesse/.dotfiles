local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

local s = ls.s
local i = ls.insert_node
local c = ls.choice_node
local sn = ls.snippet_node
local t = ls.text_node

ls.add_snippets("svelte", {
	s(
		"scr",
		fmt(
			[[
                <script {}>
                    {}
                </script>
            ]],
			{
				c(1, { t('lang="ts"'), t('context="module" lang="ts"') }),
				i(0),
			}
		)
	),
	-- the 2nd choice doesn't work as expected, yet...
	s(
		"$cl",
		fmt([[$: console.log({});]], {
			c(1, {
				i(0),
				sn(0, fmt([["{}", ]], { rep(1) })),
			}),
		})
	),
})
