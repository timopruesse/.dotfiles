local key = require("timopruesse.helpers.keymap")

key.nnoremap("<leader>ga", key.exec_command(":Git fetch --all"))
key.nnoremap("<leader>grum", key.exec_command(":Git rebase upstream/main"))
key.nnoremap("<leader>grom", key.exec_command(":Git rebase origin/main"))

key.nmap("<leader>gg", key.exec_command(":G"))
key.nmap("<leader>gh", key.exec_command(":diffget //3"))
key.nmap("<leader>gf", key.exec_command(":diffget //2"))
key.nmap("<leader>gc", key.exec_command(":G commit"))
key.nmap("<leader>gp", key.exec_command(":G push"))
