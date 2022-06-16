local key = require("timopruesse.helpers.keymap")

key.nmap("<leader>cr", require("rust-tools.runnables").runnables)
