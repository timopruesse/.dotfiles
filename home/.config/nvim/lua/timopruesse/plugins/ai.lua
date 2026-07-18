return {
	{
		"ThePrimeagen/99",
		event = "VeryLazy",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			{ "saghen/blink.compat", version = "2.*", opts = {} },
		},
		config = function()
			local _99 = require("99")
			local coding_agent = require("timopruesse.coding_agent")
			local basename = vim.fs.basename(vim.uv.cwd() or "")

			local function provider_for_cli(cli)
				if cli == "claude" then
					return _99.Providers.ClaudeCodeProvider
				end
				return _99.Providers.CursorAgentProvider
			end

			-- Match shell/tmux/Neovim <leader>z* routing: chewielabs → Claude,
			-- otherwise Cursor Agent. Re-apply on DirChanged so project switches
			-- pick up the right CLI (manual <leader>9p still works until then).
			local function apply_resolved_provider()
				local provider = provider_for_cli(coding_agent.resolve_cli(vim.fn.getcwd()))
				if _99.get_provider() ~= provider then
					_99.set_provider(provider)
				end
			end

			_99.setup({
				provider = provider_for_cli(coding_agent.resolve_cli(vim.fn.getcwd())),
				completion = { source = "blink" },
				logger = {
					level = _99.DEBUG,
					path = "/tmp/" .. basename .. ".99.debug",
					print_on_error = true,
				},
				tmp_dir = "./tmp",
				md_files = { "AGENT.md", "CLAUDE.md" },
			})

			vim.api.nvim_create_autocmd("DirChanged", {
				callback = apply_resolved_provider,
			})

			vim.keymap.set("v", "<leader>9v", function()
				_99.visual()
			end, { desc = "replace selection" })

			vim.keymap.set("n", "<leader>9s", function()
				_99.search()
			end, { desc = "search codebase" })

			vim.keymap.set("n", "<leader>9o", function()
				_99.open()
			end, { desc = "open last result" })

			vim.keymap.set("n", "<leader>9x", function()
				_99.stop_all_requests()
			end, { desc = "stop all requests" })

			vim.keymap.set("n", "<leader>9c", function()
				_99.clear_previous_requests()
			end, { desc = "clear previous requests" })

			vim.keymap.set("n", "<leader>9l", function()
				_99.view_logs()
			end, { desc = "view logs" })

			vim.keymap.set("n", "<leader>9m", function()
				require("99.extensions.telescope").select_model()
			end, { desc = "select model" })

			vim.keymap.set("n", "<leader>9p", function()
				require("99.extensions.telescope").select_provider()
			end, { desc = "select provider" })
		end,
	},
}
