local M = {}

local function tmux_pane(mode, cwd)
	local tmux_arg
	if mode == "window" then
		tmux_arg = "new-window"
	elseif mode == "vsplit" then
		tmux_arg = "split-window -h"
	elseif mode == "hsplit" then
		tmux_arg = "split-window -v"
	end

	local cmd = string.format("tmux %s -c %s -P -F '#{pane_id}'", tmux_arg, vim.fn.shellescape(cwd))
	local pane_id = vim.trim(vim.fn.system(cmd))
	if vim.v.shell_error ~= 0 then
		vim.notify("tmux: " .. pane_id, vim.log.levels.ERROR)
		return nil
	end
	return pane_id
end

local function tmux_send(pane_id, keys)
	vim.fn.jobstart({ "tmux", "send-keys", "-t", pane_id, keys, "Enter" })
end

function M.get_visual_selection()
	local lines = vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = vim.fn.visualmode() })
	return table.concat(lines, "\n")
end

function M.send_to_claude(text, opts)
	opts = opts or {}
	local mode = opts.mode or "vsplit"
	local cwd = vim.fn.getcwd()

	local tmpfile = vim.fn.tempname()
	local f = io.open(tmpfile, "w")
	if not f then
		vim.notify("Failed to create temp file", vim.log.levels.ERROR)
		return
	end
	f:write(text)
	f:close()

	local pane_id = tmux_pane(mode, cwd)
	if not pane_id then
		return
	end

	local cmd = string.format("claude \"$(cat '%s')\" ; rm -f '%s'", tmpfile, tmpfile)
	tmux_send(pane_id, cmd)
end

function M.send_selection(opts)
	local text = M.get_visual_selection()
	if text == "" then
		vim.notify("No selection", vim.log.levels.WARN)
		return
	end

	local filepath = vim.fn.expand("%:.")
	local srow = vim.fn.line("'<")
	local erow = vim.fn.line("'>")
	local ft = vim.bo.filetype

	local prompt = string.format("%s:%d-%d\n\n```%s\n%s\n```", filepath, srow, erow, ft, text)
	M.send_to_claude(prompt, opts)
end

function M.prompt_and_send(opts)
	local text = M.get_visual_selection()
	if text == "" then
		vim.notify("No selection", vim.log.levels.WARN)
		return
	end

	local filepath = vim.fn.expand("%:.")
	local srow = vim.fn.line("'<")
	local erow = vim.fn.line("'>")
	local ft = vim.bo.filetype

	vim.schedule(function()
		vim.ui.input({ prompt = "Claude: " }, function(input)
			if not input or input == "" then
				return
			end

			local prompt =
				string.format("%s\n\n%s:%d-%d\n\n```%s\n%s\n```", input, filepath, srow, erow, ft, text)
			M.send_to_claude(prompt, opts)
		end)
	end)
end

function M.send_file(opts)
	local filepath = vim.fn.expand("%:.")
	local ft = vim.bo.filetype

	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local content = table.concat(lines, "\n")

	local prompt = string.format("File: %s\n\n```%s\n%s\n```", filepath, ft, content)
	M.send_to_claude(prompt, opts)
end

function M.send_diagnostics(opts)
	local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
	local diagnostics = vim.diagnostic.get(0, { lnum = lnum })

	if #diagnostics == 0 then
		vim.notify("No diagnostics on current line", vim.log.levels.INFO)
		return
	end

	local filepath = vim.fn.expand("%:.")
	local ft = vim.bo.filetype

	local diag_texts = {}
	for _, d in ipairs(diagnostics) do
		local severity = vim.diagnostic.severity[d.severity]
		table.insert(diag_texts, string.format("[%s] %s", severity, d.message))
	end

	local start = math.max(0, lnum - 5)
	local stop = math.min(vim.api.nvim_buf_line_count(0), lnum + 6)
	local context_lines = vim.api.nvim_buf_get_lines(0, start, stop, false)

	local prompt = string.format(
		"Fix the following diagnostics in %s:%d\n\n%s\n\nContext:\n```%s\n%s\n```",
		filepath,
		lnum + 1,
		table.concat(diag_texts, "\n"),
		ft,
		table.concat(context_lines, "\n")
	)

	M.send_to_claude(prompt, opts)
end

function M.open_claude(opts)
	opts = opts or {}
	local mode = opts.mode or "vsplit"
	local cwd = vim.fn.getcwd()

	local pane_id = tmux_pane(mode, cwd)
	if not pane_id then
		return
	end
	tmux_send(pane_id, "claude")
end

return M
