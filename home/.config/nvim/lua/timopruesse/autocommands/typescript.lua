local attach_to_buffer = function(output_bufnr, pattern, npm_command)
	npm_command = npm_command or "test"
	pattern = pattern or { "*.ts" }

	local command = { "npm", "run", npm_command }

	local run_tests = function()
		local write_to_file = function(_, data)
			if data then
				vim.api.nvim_buf_set_lines(output_bufnr, -1, -1, false, data)
			end
		end

		vim.api.nvim_buf_set_lines(output_bufnr, 0, -1, false, { "Testing..." })
		vim.fn.jobstart(command, {
			stdout_buffered = true,
			on_stdout = write_to_file,
			on_stderr = write_to_file,
		})
	end

	local au_npm_test = vim.api.nvim_create_augroup("npm_test", { clear = false })

	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		pattern = pattern,
		callback = run_tests,
		group = au_npm_test,
	})

	vim.api.nvim_create_autocmd({ "BufHidden" }, {
		buffer = output_bufnr,
		callback = function()
			vim.api.nvim_buf_delete(output_bufnr, { force = true })
		end,
		group = au_npm_test,
	})

	vim.api.nvim_buf_set_lines(output_bufnr, 0, -1, false, { "Waiting for save..." })
end

local close_old_split = function()
	local commands = vim.api.nvim_get_autocmds({
		group = vim.api.nvim_create_augroup("npm_test", { clear = false }),
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
		vim.api.nvim_create_augroup("npm_test", { clear = true })
		vim.api.nvim_buf_delete(scratch_bufnr, { force = true })
	end

	return { closed = closed, pattern = pattern }
end

local toggle_tests = function(file_name)
	local split = close_old_split()

	if split.closed and file_name == split.pattern then
		return false
	end

	vim.cmd("vsplit")
	local win = vim.api.nvim_get_current_win()
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(win, bufnr)

	if file_name then
		attach_to_buffer(bufnr, { file_name })
	else
		attach_to_buffer(bufnr)
	end

	vim.cmd("wincmd p")

	return true
end

vim.api.nvim_create_user_command("ToggleNpmTestAll", function()
	if toggle_tests() then
		print("Tests now run on every save...")
	else
		print("Stopped testing...")
	end
end, {})

vim.api.nvim_create_user_command("ToggleNpmTestFile", function()
	if vim.bo.filetype == "typescript" or vim.bo.filetype == "typescriptreact" then
		local file_path = vim.fn.expand("%")

		if toggle_tests(file_path) then
			print(string.format("%s: Run tests on save...", file_path))
		else
			print(string.format("%s: Stopped testing...", file_path))
		end
	else
		print("This is not a TS file, you dummy!")
	end
end, {})
