local M = {}

local createNoRemap = function(mode)
	return function(keys, callback, silent)
		silent = silent or false

		vim.keymap.set(mode, keys, callback, { noremap = true, silent = silent })
	end
end

local createMap = function(mode)
	return function(keys, callback, silent)
		silent = silent or false

		vim.keymap.set(mode, keys, callback, { noremap = false, silent = silent })
	end
end

M.nnoremap = createNoRemap("n")
M.inoremap = createNoRemap("i")
M.vnoremap = createNoRemap("v")
M.nmap = createMap("n")
M.imap = createMap("i")
M.vmap = createMap("v")

M.escape = function(str)
	return vim.api.nvim_replace_termcodes(str, true, true, true)
end

M.exec_command = function(cmd, replace_term)
	replace_term = replace_term or true

	if replace_term then
		cmd = M.escape(cmd)
	end

	return function()
		return vim.api.nvim_command(cmd)
	end
end

return M
