local attach_to_buffer = function(output_bufnr, config)
	local run_command = function()
		local write_to_file = function(_, data)
			if data then
				vim.api.nvim_buf_set_lines(output_bufnr, -1, -1, false, data)
			end
		end

		local message = config.message or "Running..."

		vim.api.nvim_buf_set_lines(output_bufnr, 0, -1, false, { message })

		vim.fn.jobstart(config.command, {
			stdout_buffered = true,
			on_stdout = write_to_file,
			on_stderr = write_to_file,
		})
	end

	local au_test = vim.api.nvim_create_augroup(config.au_group, { clear = false })

	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		pattern = config.pattern,
		callback = run_command,
		group = au_test,
	})

	vim.api.nvim_create_autocmd({ "BufHidden" }, {
		buffer = output_bufnr,
		callback = function()
			vim.api.nvim_buf_delete(output_bufnr, { force = true })
		end,
		group = au_test,
	})

	vim.api.nvim_buf_set_lines(output_bufnr, 0, -1, false, { "Waiting for save..." })
end

local close_old_split = function(au_group)
	local commands = vim.api.nvim_get_autocmds({
		group = vim.api.nvim_create_augroup(au_group, { clear = false }),
	})

	local scratch_bufnr
	local pattern

	for _, c in ipairs(commands) do
		if c.event == "BufHidden" then
			scratch_bufnr = tonumber(c.buffer)
		elseif c.event == "BufWritePost" then
			pattern = c.pattern
		end
	end

	local closed = #commands > 0

	if closed then
		vim.api.nvim_create_augroup(au_group, { clear = true })
		vim.api.nvim_buf_delete(scratch_bufnr, { force = true })
	end

	return { closed = closed, pattern = pattern }
end

local M = {}

M.run_on_save = function(config)
	local toggle_command = function(file_name)
		local split = close_old_split(config.au_group)

		if split.closed and file_name == split.pattern then
			return false
		end

		vim.cmd("vsplit")
		local win = vim.api.nvim_get_current_win()
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_win_set_buf(win, bufnr)

		if file_name then
			config.pattern = { file_name }
		end

		attach_to_buffer(bufnr, config)

		vim.cmd("wincmd p")

		return true
	end

	vim.api.nvim_create_user_command(config.testAllCommandName, function()
		if toggle_command() then
			print("Tests now run on every save...")
		else
			print("Stopped testing...")
		end
	end, {})

	vim.api.nvim_create_user_command(config.testFileCommandName, function()
		if require("timopruesse.utils.array").has_value(config.fileTypes, vim.bo.filetype) then
			local file_path = vim.fn.expand("%")

			if toggle_command(file_path) then
				print(string.format("%s: Run tests on save...", file_path))
			else
				print(string.format("%s: Stopped testing...", file_path))
			end
		else
			print("Unsupported file type...")
		end
	end, {})
end

return M
