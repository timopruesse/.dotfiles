local key = require("timopruesse.helpers.keymap")
local ui = require("harpoon.ui")

key.nnoremap("<leader>a", require("harpoon.mark").add_file)
key.nnoremap("<C-e>", ui.toggle_quick_menu)

local go_to_file = function(i)
	return function()
		ui.nav_file(i)
	end
end

key.nnoremap("<C-h>", go_to_file(1))
key.nnoremap("<C-j>", go_to_file(2))
key.nnoremap("<C-k>", go_to_file(3))
key.nnoremap("<C-l>", go_to_file(4))
