local ls = require("luasnip")

ls.add_snippets("svelte", {
	ls.parser.parse_snippet("scr", '<script lang="ts">\n$0\n</script>'),
	ls.parser.parse_snippet("mod", '<script context="module">\n$0\n</script>'),
})
