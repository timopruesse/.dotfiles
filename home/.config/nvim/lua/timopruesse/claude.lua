local M = {}

local coding_agent = require("timopruesse.coding_agent")

local last_agent_pane = nil

local function herdr_json_pane_id(json)
	local ok, data = pcall(vim.json.decode, json)
	if not ok or type(data) ~= "table" then
		return nil
	end
	local result = data.result or {}
	local pane = result.pane or result.root_pane
	if type(pane) == "table" and type(pane.pane_id) == "string" and pane.pane_id ~= "" then
		return pane.pane_id
	end
	if type(pane) == "string" and pane ~= "" then
		return pane
	end
	return nil
end

local function herdr_pane(mode, cwd)
	local cmd
	if mode == "window" then
		cmd = { "herdr", "tab", "create", "--cwd", cwd, "--focus" }
	elseif mode == "vsplit" then
		cmd = { "herdr", "pane", "split", "--current", "--direction", "right", "--cwd", cwd, "--focus" }
	elseif mode == "hsplit" then
		cmd = { "herdr", "pane", "split", "--current", "--direction", "down", "--cwd", cwd, "--focus" }
	else
		vim.notify("herdr: unknown mode " .. tostring(mode), vim.log.levels.ERROR)
		return nil
	end

	local resp = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		vim.notify("herdr: " .. resp, vim.log.levels.ERROR)
		return nil
	end

	local pane_id = herdr_json_pane_id(resp)
	if not pane_id then
		vim.notify("herdr: failed to parse pane id\n" .. resp, vim.log.levels.ERROR)
		return nil
	end
	return pane_id
end

local function herdr_run(pane_id, command)
	vim.fn.jobstart({ "herdr", "pane", "run", pane_id, command })
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

function M.get_visual_selection()
	local lines = vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = vim.fn.visualmode() })
	return table.concat(lines, "\n")
end

function M.send_to_claude(text, opts)
	opts = opts or {}

	if opts.existing and last_agent_pane and pane_exists(last_agent_pane) then
		-- agent prompt submits text + Enter atomically when the pane hosts an agent.
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

	local mode = opts.mode or "vsplit"
	local cwd = vim.fn.getcwd()
	local cli = coding_agent.resolve_cli(cwd)

	local tmpfile = write_temp(text)
	if not tmpfile then
		return
	end

	local pane_id = herdr_pane(mode, cwd)
	if not pane_id then
		return
	end

	last_agent_pane = pane_id

	local cmd = string.format("__cp=$(cat %s) && rm -f %s && %s \"$__cp\"", vim.fn.shellescape(tmpfile), vim.fn.shellescape(tmpfile), cli)
	herdr_run(pane_id, cmd)
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
		vim.ui.input({ prompt = "Agent: " }, function(input)
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
		vim.ui.input({ prompt = "Agent: " }, function(input)
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
	local cli = coding_agent.resolve_cli(cwd)

	local pane_id = herdr_pane(mode, cwd)
	if not pane_id then
		return
	end

	last_agent_pane = pane_id
	herdr_run(pane_id, cli)
end

return M
