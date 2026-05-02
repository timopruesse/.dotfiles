local key = require("timopruesse.helpers.keymap")

key.nnoremap("<leader>a", function()
	local harpoon = require("harpoon")
	harpoon:list():add()
end, { desc = "Harpoon: add file" })

key.nnoremap("<C-e>", function()
	local harpoon = require("harpoon")
	harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Harpoon: toggle quick menu" })

local go_to_file = function(i)
	return function()
		require("harpoon"):list():select(i)
	end
end

key.nnoremap("<C-h>", go_to_file(1), { desc = "Harpoon: go to file 1" })
key.nnoremap("<C-j>", go_to_file(2), { desc = "Harpoon: go to file 2" })
key.nnoremap("<C-k>", go_to_file(3), { desc = "Harpoon: go to file 3" })
key.nnoremap("<C-l>", go_to_file(4), { desc = "Harpoon: go to file 4" })
