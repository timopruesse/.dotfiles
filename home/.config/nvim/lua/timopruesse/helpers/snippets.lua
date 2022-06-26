local ls = require("luasnip")
local f = ls.function_node

local M = {}

M.mirror = function(index)
	return f(function(arg)
		return arg[1]
	end, { index })
end

return M
