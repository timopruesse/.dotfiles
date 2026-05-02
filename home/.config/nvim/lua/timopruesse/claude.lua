local M = {}

local last_claude_pane = nil

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

local function pane_exists(pane_id)
	local result = vim.fn.system(
		string.format("tmux list-panes -a -F '#{pane_id}' | grep -qF '%s' && echo ok || echo no", pane_id)
	)
	return vim.trim(result) == "ok"
end

local function write_temp(text)
	local tmpfile = vim.fn.tempname()
	local f = io.open(tmpfile, "w")
	if not f then
		vim.notify("Failed to create temp file", vim.log.levels.ERROR)
		return nil
	end
	f:write(text)
	f:close()
	return tmpfile
end

function M.get_visual_selection()
	local lines = vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = vim.fn.visualmode() })
	return table.concat(lines, "\n")
end

function M.send_to_claude(text, opts)
	opts = opts or {}

	if opts.existing and last_claude_pane and pane_exists(last_claude_pane) then
		local tmpfile = write_temp(text)
		if not tmpfile then
			return
		end
		vim.fn.system({ "tmux", "load-buffer", tmpfile })
		vim.fn.system({ "tmux", "paste-buffer", "-t", last_claude_pane })
		vim.defer_fn(function()
			vim.fn.system({ "tmux", "send-keys", "-t", last_claude_pane, "Enter" })
			os.remove(tmpfile)
		end, 100)
		return
	end

	if opts.existing then
		vim.notify("No active Claude pane — opening new one.", vim.log.levels.INFO)
	end

	local mode = opts.mode or "vsplit"
	local cwd = vim.fn.getcwd()

	local tmpfile = write_temp(text)
	if not tmpfile then
		return
	end

	local pane_id = tmux_pane(mode, cwd)
	if not pane_id then
		return
	end

	last_claude_pane = pane_id

	local cmd = string.format("__cp=$(cat '%s') && rm -f '%s' && claude \"$__cp\"", tmpfile, tmpfile)
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

function M.send_git_diff(opts)
	local filepath = vim.fn.expand("%:.")
	local diff = vim.fn.system({ "git", "diff", "--", filepath })

	if vim.trim(diff) == "" then
		diff = vim.fn.system({ "git", "diff", "--staged", "--", filepath })
	end

	if vim.trim(diff) == "" then
		vim.notify("No git changes for current file", vim.log.levels.INFO)
		return
	end

	local prompt = string.format("Review the following changes in %s:\n\n```diff\n%s\n```", filepath, diff)
	M.send_to_claude(prompt, opts)
end

function M.prompt_and_send_git_diff(opts)
	local filepath = vim.fn.expand("%:.")
	local diff = vim.fn.system({ "git", "diff", "--", filepath })

	if vim.trim(diff) == "" then
		diff = vim.fn.system({ "git", "diff", "--staged", "--", filepath })
	end

	if vim.trim(diff) == "" then
		vim.notify("No git changes for current file", vim.log.levels.INFO)
		return
	end

	vim.schedule(function()
		vim.ui.input({ prompt = "Claude: " }, function(input)
			if not input or input == "" then
				return
			end

			local prompt = string.format("%s\n\n%s\n\n```diff\n%s\n```", input, filepath, diff)
			M.send_to_claude(prompt, opts)
		end)
	end)
end

function M.open_claude(opts)
	opts = opts or {}
	local mode = opts.mode or "vsplit"
	local cwd = vim.fn.getcwd()

	local pane_id = tmux_pane(mode, cwd)
	if not pane_id then
		return
	end

	last_claude_pane = pane_id
	tmux_send(pane_id, "claude")
end

return M
