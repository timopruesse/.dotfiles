local set_options = function()
	vim.opt_local.ts = 2
	vim.opt_local.sts = 2
	vim.opt_local.sw = 2
	vim.opt_local.expandtab = true
end

vim.api.nvim_create_autocmd({ "FileType" }, {
	pattern = { "yaml" },
	callback = set_options,
	group = vim.api.nvim_create_augroup("timopruesse", { clear = false }),
})

-- yaml-language-server advertises these custom filetypes by default; register
-- filename patterns so :checkhealth stops warning about unknown filetypes and
-- yamlls picks the right schema per file.
vim.filetype.add({
	pattern = {
		[".*/.gitlab%-ci.*%.ya?ml"] = "yaml.gitlab",
		[".*%.gitlab%-ci%.ya?ml"] = "yaml.gitlab",
		[".*docker%-compose.*%.ya?ml"] = "yaml.docker-compose",
		[".*/compose%.ya?ml"] = "yaml.docker-compose",
		[".*/compose%.[^/]*%.ya?ml"] = "yaml.docker-compose",
		[".*/templates/.*%.ya?ml"] = "yaml.helm-values",
		[".*/Chart%.ya?ml"] = "yaml.helm-values",
		[".*/values%.ya?ml"] = "yaml.helm-values",
		[".*/values%.[^/]*%.ya?ml"] = "yaml.helm-values",
	},
	filename = {
		[".gitlab-ci.yml"] = "yaml.gitlab",
		[".gitlab-ci.yaml"] = "yaml.gitlab",
		["docker-compose.yml"] = "yaml.docker-compose",
		["docker-compose.yaml"] = "yaml.docker-compose",
		["compose.yml"] = "yaml.docker-compose",
		["compose.yaml"] = "yaml.docker-compose",
		["Chart.yaml"] = "yaml.helm-values",
		["values.yaml"] = "yaml.helm-values",
	},
})
