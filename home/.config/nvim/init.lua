local init = require("timopruesse.packer.init")

if init() then
	return
end

vim.g.mapleader = " "

require("timopruesse.packer.plugins")
require("timopruesse.init")
