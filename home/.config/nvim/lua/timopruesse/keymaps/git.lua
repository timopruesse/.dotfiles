local key = require("timopruesse.helpers.keymap")
local neogit = require("neogit")

key.nnoremap("<leader>ga", key.exec_command(":Git fetch --all"))
key.nnoremap("<leader>grum", key.exec_command(":Git rebase upstream/main"))
key.nnoremap("<leader>grom", key.exec_command(":Git rebase origin/main"))

local open = function()
	neogit.open({ kind = "split" })
end

key.nmap("<leader>gg", open)
key.nmap("<leader>gh", key.exec_command(":diffget //3"))
key.nmap("<leader>gf", key.exec_command(":diffget //2"))
key.nmap("<leader>gc", key.exec_command(":G commit"))
key.nmap("<leader>gp", key.exec_command(":G push"))
