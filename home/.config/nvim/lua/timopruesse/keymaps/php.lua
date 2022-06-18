local key = require("timopruesse.helpers.keymap")

key.nmap("<leader>pt", key.exec_command("!sail test"))
key.nmap("<leader>rl", key.exec_command("!sa route:list"))
