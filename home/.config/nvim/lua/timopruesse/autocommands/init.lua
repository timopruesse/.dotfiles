local au_yank = vim.api.nvim_create_augroup("highlight_yank", { clear = true })
vim.api.nvim_create_autocmd({ "TextYankPost" }, {
	pattern = { "*" },
	callback = function()
		vim.highlight.on_yank({ timeout = 800 })
	end,
	group = au_yank,
})

-- Live markdown preview: pandoc → HTML with <meta http-equiv="refresh">
-- Cross-platform opener; requires `pandoc` on PATH.
local md_preview = { html_path = nil, augroup = nil, source = nil }

local function open_cmd()
	if vim.uv.os_uname().sysname == "Darwin" then
		return "open"
	end
	if vim.env.WSL_DISTRO_NAME or vim.fn.executable("wslview") == 1 then
		return "wslview"
	end
	return "xdg-open"
end

local function render_html()
	if not (md_preview.html_path and md_preview.source) then
		return
	end
	vim.system({
		"pandoc",
		md_preview.source,
		"-o",
		md_preview.html_path,
		"--standalone",
		"--metadata",
		"title=Preview",
	}):wait()
end

vim.api.nvim_create_user_command("MarkdownPreview", function()
	if vim.fn.executable("pandoc") == 0 then
		vim.notify("MarkdownPreview: pandoc not found (install via apt/brew)", vim.log.levels.ERROR)
		return
	end
	md_preview.source = vim.fn.expand("%:p")
	if md_preview.source == "" then
		vim.notify("MarkdownPreview: buffer has no file", vim.log.levels.WARN)
		return
	end
	md_preview.html_path = vim.fn.tempname() .. ".html"
	render_html()

	vim.system({ open_cmd(), md_preview.html_path })

	md_preview.augroup = vim.api.nvim_create_augroup("MarkdownPreviewLive", { clear = true })
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = md_preview.augroup,
		pattern = md_preview.source,
		callback = render_html,
	})
end, { desc = "Markdown preview — regenerates on :w; refresh browser to see updates" })

vim.api.nvim_create_user_command("MarkdownPreviewStop", function()
	if md_preview.augroup then
		vim.api.nvim_del_augroup_by_id(md_preview.augroup)
		md_preview.augroup = nil
	end
	md_preview.html_path = nil
	md_preview.source = nil
end, { desc = "Stop live markdown preview" })

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	group = vim.api.nvim_create_augroup("markdown", { clear = true }),
	callback = function(args)
		vim.keymap.set("n", "<leader>md", "<cmd>MarkdownPreview<cr>", {
			buffer = args.buf,
			silent = true,
			desc = "Markdown preview",
		})
	end,
})

require("timopruesse.autocommands.yaml")
