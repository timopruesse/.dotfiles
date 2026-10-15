-- Shared Pi-first resolution; explicit legacy CLI overrides remain available.
-- Mirrors ~/.config/herdr/scripts/coding_agent_resolve.sh.

local M = {}

--- @param cwd string|nil
--- @return "pi"|"claude"|"codex"|"agent"|"agy"
function M.resolve_cli(cwd)
	cwd = cwd or vim.fn.getcwd()
	local script = vim.fn.expand("~/.config/herdr/scripts/coding_agent_resolve.sh")
	local result = vim.trim(vim.fn.system({ script, cwd }))
	if result == "pi" or result == "codex" or result == "claude" or result == "agent" or result == "agy" then
		return result
	end
	return "pi"
end

return M
