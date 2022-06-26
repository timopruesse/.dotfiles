local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt

local s = ls.s
local f = ls.function_node
local i = ls.insert_node

ls.add_snippets("lua", {
	ls.parser.parse_snippet("lf", "local $1 = function($2)\n  $0\nend"),
	s(
		"req",
		fmt([[local {} = require("{}")]], {
			f(function(import_name)
				local parts = vim.split(import_name[1][1], ".", true)

				return parts[#parts] or ""
			end, { 1 }),
			i(1),
		})
	),
})
