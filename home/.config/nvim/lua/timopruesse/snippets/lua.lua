local ls = require("luasnip")

ls.add_snippets("lua", {
	ls.parser.parse_snippet("lf", "local $1 = function($2)\n  $0\nend"),
})
