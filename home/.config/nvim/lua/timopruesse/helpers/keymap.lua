local M = {}

local createNoRemap = function(mode)
	return function(keys, callback)
		vim.keymap.set(mode, keys, callback, { noremap = true })
	end
end

local createMap = function(mode)
	return function(keys, callback)
		vim.keymap.set(mode, keys, callback, { noremap = false })
	end
end

M.nnoremap = createNoRemap("n")
M.inoremap = createNoRemap("i")
M.vnoremap = createNoRemap("v")
M.nmap = createMap("n")
M.imap = createMap("i")
M.vmap = createMap("v")

M.exec_command = function(cmd)
	return function()
		return vim.api.nvim_command(cmd)
	end
end

return M
