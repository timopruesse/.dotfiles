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
	s(
		"sty",
		fmt(
			[[
			<style {}>
				{}
			</style>
			]],
			{
				c(1, { t(""), t('lang="scss"') }),
				i(0),
			}
		)
	),
	s(
		"each",
		fmt(
			[[
			{{#each {} as {}}}
				{}
			{{/each}}
			]],
			{ i(1, "items"), i(2, "item"), i(0) }
		)
	),
	s(
		"eachi",
		fmt(
			[[
			{{#each {} as {}, {}}}
				{}
			{{/each}}
			]],
			{ i(1, "items"), i(2, "item"), i(3, "i"), i(0) }
		)
	),
	s(
		"sif",
		fmt(
			[[
			{{#if {}}}
				{}
			{{/if}}
			]],
			{ i(1), i(0) }
		)
	),
	s(
		"sife",
		fmt(
			[[
			{{#if {}}}
				{}
			{{:else}}
				{}
			{{/if}}
			]],
			{ i(1), i(2), i(0) }
		)
	),
	s(
		"await",
		fmt(
			[[
			{{#await {}}}
				{}
			{{:then {}}}
				{}
			{{/await}}
			]],
			{ i(1, "promise"), i(2), i(3, "value"), i(0) }
		)
	),
	s(
		"snip",
		fmt(
			[[
			{{#snippet {}({})}}
				{}
			{{/snippet}}
			]],
			{ i(1, "name"), i(2), i(0) }
		)
	),
	s("$st", fmt([[let {} = $state({});]], { i(1, "name"), i(0) })),
	s("$de", fmt([[let {} = $derived({});]], { i(1, "name"), i(0) })),
	s(
		"$ef",
		fmt(
			[[
			$effect(() => {{
				{}
			}});
			]],
			{ i(0) }
		)
	),
	s("$pr", fmt([[let {{ {} }} = $props();]], { i(0) })),
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
