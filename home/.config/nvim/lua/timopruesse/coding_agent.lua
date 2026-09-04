-- Shared Claude Code vs Antigravity (agy) vs Cursor Agent resolution for Neovim integrations.
-- Mirrors ~/.config/herdr/scripts/coding_agent_resolve.sh (env → remote org → path).

local M = {}

--- @param cwd string|nil
--- @return "claude"|"agent"|"agy"
function M.resolve_cli(cwd)
	cwd = cwd or vim.fn.getcwd()
	local script = vim.fn.expand("~/.config/herdr/scripts/coding_agent_resolve.sh")
	local result = vim.trim(vim.fn.system({ script, cwd }))
	if result == "claude" or result == "agent" or result == "agy" then
		return result
	end
	return "agy"
end

return M
