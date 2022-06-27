local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt

local s = ls.s
local i = ls.insert_node
local c = ls.choice_node
local t = ls.text_node

ls.add_snippets("svelte", {
	s(
		"script",
		fmt(
			[[
                <script {}>
                    {}
                </script>
            ]],
			{
				c(1, { t('lang="ts"'), t('context="module"') }),
				i(0),
			}
		)
	),
})
