return {
    {
        "ThePrimeagen/99",
        event = "VeryLazy",
        dependencies = { "nvim-telescope/telescope.nvim" },
        config = function()
            local _99 = require("99")
            local basename = vim.fs.basename(vim.uv.cwd() or "")

            _99.setup({
                provider = _99.Providers.ClaudeCodeProvider,
                model = "claude-opus-4-7",
                logger = {
                    level = _99.DEBUG,
                    path = "/tmp/" .. basename .. ".99.debug",
                    print_on_error = true,
                },
                tmp_dir = "./tmp",
                md_files = { "AGENT.md", "CLAUDE.md" },
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
