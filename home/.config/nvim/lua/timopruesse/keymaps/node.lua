local key = require("timopruesse.helpers.keymap")

key.nmap("<leader>tt", key.exec_command("!npm run test"))
