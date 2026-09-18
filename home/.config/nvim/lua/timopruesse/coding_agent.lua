-- Shared Claude Code vs Codex (Cursor and Antigravity overrides) resolution for Neovim integrations.
-- Mirrors ~/.config/herdr/scripts/coding_agent_resolve.sh (env → remote org → path).

local M = {}

--- @param cwd string|nil
--- @return "claude"|"codex"|"agent"|"agy"
function M.resolve_cli(cwd)
	cwd = cwd or vim.fn.getcwd()
	local script = vim.fn.expand("~/.config/herdr/scripts/coding_agent_resolve.sh")
	local result = vim.trim(vim.fn.system({ script, cwd }))
	if result == "codex" or result == "claude" or result == "agent" or result == "agy" then
		return result
	end
	return "codex"
end

return M
