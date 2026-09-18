-- 99 reads the result file requested in its prompt via BaseProvider.
local Provider = setmetatable({}, { __index = require("99.providers").BaseProvider })

function Provider._build_command(_, query, context)
	local command = { "codex", "exec", "--sandbox", "workspace-write" }
	if context.model and context.model ~= "default" then
		vim.list_extend(command, { "--model", context.model })
	end
	vim.list_extend(command, { "--", query })
	return command
end

function Provider._get_provider_name()
	return "CodexProvider"
end

function Provider._get_default_model()
	return "default" -- Let Codex use the user's configured model.
end

return Provider
