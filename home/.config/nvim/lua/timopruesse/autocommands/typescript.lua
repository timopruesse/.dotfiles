require("timopruesse.helpers.autocommands.run_on_save").run_on_save({
	au_group = "npm_test",
	pattern = { "*.ts" },
	fileTypes = { "typescript", "typescriptreact" },
	command = { "npm", "run", "test" },
	testAllCommandName = "ToggleNpmTestAll",
	testFileCommandName = "ToggleNpmTestFile",
	message = "Testing...",
})
