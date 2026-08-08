-- Herdr coding-agent panes (Claude Code / Cursor Agent).
-- Split/tab + launch policy live in ~/.config/herdr/scripts/coding_agent_herdr.sh

local M = {}

local last_agent_pane = nil

local function herdr_script()
	return vim.fn.expand("~/.config/herdr/scripts/coding_agent_herdr.sh")
end

local function pane_exists(pane_id)
	local result = vim.trim(vim.fn.system({ "herdr", "pane", "get", pane_id }))
	return vim.v.shell_error == 0 and result ~= "" and not result:find('"error"')
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

--- Map nvim mode names to coding_agent_herdr.sh layouts.
local function layout_for(mode)
	if mode == "window" then
		return "window"
	elseif mode == "vsplit" then
		return "hsplit" -- vertical split = pane to the right
	elseif mode == "hsplit" then
		return "vsplit" -- horizontal split = pane down
	end
	return "hsplit"
end

--- Launch via deep herdr module. Returns pane_id or nil.
--- @param opts { mode?: string, resume_mode?: "resume"|"continue"|nil, prompt_file?: string }
local function herdr_launch(opts)
	opts = opts or {}
	local layout = layout_for(opts.mode or "vsplit")
	local cmd = { herdr_script(), layout }
	if opts.resume_mode == "resume" or opts.resume_mode == "continue" then
		table.insert(cmd, opts.resume_mode)
	end
	if opts.prompt_file then
		table.insert(cmd, "--prompt-file")
		table.insert(cmd, opts.prompt_file)
	end

	local resp = vim.trim(vim.fn.system(cmd))
	if vim.v.shell_error ~= 0 then
		vim.notify("herdr coding-agent: " .. resp, vim.log.levels.ERROR)
		return nil
	end

	-- Module prints pane_id on the last line.
	local pane_id = resp:match("([^\n]+)$")
	if not pane_id or pane_id == "" then
		vim.notify("herdr coding-agent: failed to parse pane id\n" .. resp, vim.log.levels.ERROR)
		return nil
	end
	return pane_id
end

function M.get_visual_selection()
	local lines = vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = vim.fn.visualmode() })
	return table.concat(lines, "\n")
end

function M.send(text, opts)
	opts = opts or {}

	if opts.existing and last_agent_pane and pane_exists(last_agent_pane) then
		local result = vim.fn.system({ "herdr", "agent", "prompt", last_agent_pane, text })
		if vim.v.shell_error ~= 0 then
			vim.fn.system({ "herdr", "pane", "send-text", last_agent_pane, text })
			vim.fn.system({ "herdr", "pane", "send-keys", last_agent_pane, "enter" })
			if vim.v.shell_error ~= 0 then
				vim.notify("herdr send failed: " .. result, vim.log.levels.ERROR)
			end
		end
		return
	end

	if opts.existing then
		vim.notify("No active agent pane — opening new one.", vim.log.levels.INFO)
	end

	local tmpfile = write_temp(text)
	if not tmpfile then
		return
	end

	local pane_id = herdr_launch({
		mode = opts.mode or "vsplit",
		prompt_file = tmpfile,
	})
	if pane_id then
		last_agent_pane = pane_id
	end
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
	M.send(prompt, opts)
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
		vim.ui.input({ prompt = "Agent: " }, function(input)
			if not input or input == "" then
				return
			end

			local prompt =
				string.format("%s\n\n%s:%d-%d\n\n```%s\n%s\n```", input, filepath, srow, erow, ft, text)
			M.send(prompt, opts)
		end)
	end)
end

function M.send_file(opts)
	local filepath = vim.fn.expand("%:.")
	local ft = vim.bo.filetype

	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local content = table.concat(lines, "\n")

	local prompt = string.format("File: %s\n\n```%s\n%s\n```", filepath, ft, content)
	M.send(prompt, opts)
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

	M.send(prompt, opts)
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
	M.send(prompt, opts)
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
		vim.ui.input({ prompt = "Agent: " }, function(input)
			if not input or input == "" then
				return
			end

			local prompt = string.format("%s\n\n%s\n\n```diff\n%s\n```", input, filepath, diff)
			M.send(prompt, opts)
		end)
	end)
end

--- Open coding agent (fresh, or resume/continue).
--- @param opts { mode?: string, resume_mode?: "resume"|"continue"|nil }
function M.open(opts)
	opts = opts or {}
	local pane_id = herdr_launch({
		mode = opts.mode or "vsplit",
		resume_mode = opts.resume_mode,
	})
	if pane_id then
		last_agent_pane = pane_id
	end
end

return M
