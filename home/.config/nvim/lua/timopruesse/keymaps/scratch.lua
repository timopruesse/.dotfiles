local key = require("timopruesse.helpers.keymap")

local function open_scratch(direction)
	if direction == "v" then
		vim.cmd("vnew")
	else
		vim.cmd("botright new")
	end
	vim.bo.buftype = "nofile"
	vim.bo.bufhidden = "hide"
	vim.bo.swapfile = false
	vim.bo.filetype = "markdown"
end

local function promote_scratch()
	if vim.bo.buftype ~= "nofile" then
		vim.notify("Not a scratch buffer", vim.log.levels.WARN)
		return
	end

	vim.ui.input({
		prompt = "Save scratch as: ",
		default = vim.fn.getcwd() .. "/",
		completion = "file",
	}, function(path)
		if not path or path == "" then
			return
		end

		local expanded = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
		local dir = vim.fn.fnamemodify(expanded, ":h")
		if vim.fn.isdirectory(dir) == 0 then
			vim.fn.mkdir(dir, "p")
		end

		vim.bo.buftype = ""
		vim.bo.bufhidden = ""
		vim.bo.swapfile = true
		vim.cmd("keepalt saveas " .. vim.fn.fnameescape(expanded))
		vim.cmd("filetype detect")
	end)
end

key.nnoremap("<leader>nv", function()
	open_scratch("v")
end, { desc = "Scratch pad (vertical split)" })

key.nnoremap("<leader>nh", function()
	open_scratch("h")
end, { desc = "Scratch pad (horizontal split)" })

key.nnoremap("<leader>np", promote_scratch, { desc = "Promote scratch to file and save" })
