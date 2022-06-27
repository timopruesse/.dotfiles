require("timopruesse.snippets.lua")
require("timopruesse.snippets.rust")
require("timopruesse.snippets.javascript")
require("timopruesse.snippets.svelte")

local ls = require("luasnip")

ls.filetype_extend("typescript", { "javascript" })
ls.filetype_extend("svelte", { "javascript", "typescript" })
