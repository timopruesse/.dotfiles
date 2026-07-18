-- Shared Claude Code vs Cursor Agent resolution for Neovim integrations.
-- Mirrors ~/.tmux/scripts/coding_agent_resolve.sh (env → remote org → path).

local M = {}

--- @param cwd string|nil
--- @return "claude"|"agent"
function M.resolve_cli(cwd)
	cwd = cwd or vim.fn.getcwd()
	local script = vim.fn.expand("~/.tmux/scripts/coding_agent_resolve.sh")
	local result = vim.trim(vim.fn.system({ script, cwd }))
	if result == "claude" or result == "agent" then
		return result
	end
	return "agent"
end

return M
