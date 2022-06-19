local key = require("timopruesse.helpers.keymap")
local neogit = require("neogit")

local open = function()
	neogit.open({ kind = "split" })
end

key.nmap("<leader>gg", open)
