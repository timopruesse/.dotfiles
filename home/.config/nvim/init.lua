local init = require("timopruesse.packer.init")

if init() then
	return
end

if pcall(require, "plenary") then
	RELOAD = require("plenary.reload").reload_module

	R = function(name)
		RELOAD(name)
		return require(name)
	end
end

require("timopruesse.packer.plugins")
require("timopruesse.init")
