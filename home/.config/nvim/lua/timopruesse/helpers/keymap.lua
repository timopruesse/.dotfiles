local M = {}

local function resolve_opts(opts)
	if type(opts) == "table" then
		return opts.buffer or false, opts.desc
	end
	return opts or false, nil
end

local createNoRemap = function(mode)
	return function(keys, callback, opts)
		local buffer, desc = resolve_opts(opts)
		vim.keymap.set(mode, keys, callback, { noremap = true, silent = true, buffer = buffer, desc = desc })
	end
end

local createMap = function(mode)
	return function(keys, callback, opts)
		local buffer, desc = resolve_opts(opts)
		vim.keymap.set(mode, keys, callback, { noremap = false, silent = true, buffer = buffer, desc = desc })
	end
end

local removeMap = function(mode)
	return function(keys, buffer)
		buffer = buffer or false
		pcall(vim.keymap.del, mode, keys, { buffer = buffer })
	end
end

M.nnoremap = createNoRemap("n")
M.inoremap = createNoRemap("i")
M.vnoremap = createNoRemap("v")
M.nmap = createMap("n")
M.imap = createMap("i")
M.vmap = createMap("v")
M.nremovemap = removeMap("n")
M.iremovemap = removeMap("i")
M.vremovemap = removeMap("v")

M.escape = function(str)
	return vim.api.nvim_replace_termcodes(str, true, true, true)
end

M.exec_command = function(cmd, replace_term)
	if replace_term == nil then
		replace_term = true
	end

	if replace_term then
		cmd = M.escape(cmd)
	end

	return function()
		return vim.api.nvim_command(cmd)
	end
end

return M
