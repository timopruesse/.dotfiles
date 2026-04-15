local key = require("timopruesse.helpers.keymap")

key.nnoremap("<leader>a", function()
	require("harpoon.mark").add_file()
end)
key.nnoremap("<C-e>", function()
	require("harpoon.ui").toggle_quick_menu()
end)

local go_to_file = function(i)
	return function()
		require("harpoon.ui").nav_file(i)
	end
end

key.nnoremap("<C-h>", go_to_file(1))
key.nnoremap("<C-j>", go_to_file(2))
key.nnoremap("<C-k>", go_to_file(3))
key.nnoremap("<C-l>", go_to_file(4))
