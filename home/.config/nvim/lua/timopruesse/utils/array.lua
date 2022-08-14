local M = {}

M.has_value = function(list, value)
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end

	return false
end

return M
