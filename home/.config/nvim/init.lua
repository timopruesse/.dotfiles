local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "

require("lazy").setup({
    {
        "kdheepak/lazygit.nvim",
        cmd = {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        keys = {
            { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
        }
    },
    {
        "tamton-aquib/staline.nvim",
        config = function()
            vim.opt.laststatus = 3

            local function tabnine_status()
                return require("tabnine.status").status()
            end

            require("staline").setup({
                sections = {
                    left = { "  ", "mode", "[", "cwd", "]", "file_name", "lsp", "line_column" },
                    mid = { "git_branch" },
                    right = { tabnine_status, "  ", "lsp_name", "  " },
                },
                defaults = {
                    true_colors = true,
                    line_column = "| %-02c",
                },
            })
        end
    },
    {
        "NLKNguyen/papercolor-theme",
        lazy = false,
        priority = 1000,
        config = function()
            vim.opt.background = "dark"
            vim.cmd("colorscheme PaperColor")
        end,
    },
    { "stevearc/dressing.nvim", event = "VeryLazy" },
    { "nvim-tree/nvim-web-devicons", lazy = true },
    { "mbbill/undotree" },
    { "ThePrimeagen/harpoon" },
    {
        "ThePrimeagen/refactoring.nvim",
        config = function()
            require("refactoring").setup({})
        end,
    },
    { "JoosepAlviste/nvim-ts-context-commentstring" },
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "BurntSushi/ripgrep",
            "nvim-telescope/telescope-fzy-native.nvim"
        },
        config = function()
            require("timopruesse.telescope")
        end,
    },
    {
        "nvim-telescope/telescope-file-browser.nvim",
        dependencies = {
            "nvim-telescope/telescope.nvim",
            "nvim-lua/plenary.nvim"
        }
    },
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup({
                max_concurrent_installers = 6,
            })
        end,
    },
    {
        "nvimdev/lspsaga.nvim",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons"
        },
        config = function()
            require('lspsaga').setup({})
        end,
    },
    { "nvim-lua/plenary.nvim", lazy = true },
    { "nvim-treesitter/nvim-treesitter-context", lazy = true },
    {
        "nvim-treesitter/nvim-treesitter",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter-context",
        },
        build = function()
            vim.api.nvim_command("TSUpdate")
        end,
        config = function()
            require("nvim-treesitter.configs").setup({
                auto_install = true,
                ensure_installed = {
                    "c",
                    "lua",
                    "rust",
                    "html",
                    "css",
                    "scss",
                    "svelte",
                    "php",
                    "json",
                    "yaml",
                    "javascript",
                    "typescript",
                    "go",
                    "dockerfile",
                    "python",
                    "dart",
                    "markdown",
                    "markdown_inline",
                    "tsx",
                    "vim",
                    "toml",
                    "regex",
                    "vimdoc",
                },
                highlight = { enable = true },
                incremental_selection = { enable = true },
                textobjects = { enable = true },
            })
            require("nvim-treesitter.parsers").get_parser_configs().markdown.filetype_to_parsername = "octo"
        end,
    },
    { "hrsh7th/cmp-nvim-lsp", lazy = true },
    { "hrsh7th/cmp-buffer", lazy = true },
    { "hrsh7th/cmp-cmdline", lazy = true },
    { "hrsh7th/cmp-nvim-lsp-document-symbol", lazy = true },
    { "hrsh7th/cmp-nvim-lsp-signature-help", lazy = true },
    { "hrsh7th/cmp-nvim-lua", lazy = true },
    { "hrsh7th/cmp-path", lazy = true },
    { "hrsh7th/cmp-calc", lazy = true },
    { "hrsh7th/cmp-emoji", lazy = true },
    { "petertriho/cmp-git", lazy = true },
    { "David-Kunz/cmp-npm", lazy = true },
    { "saadparwaiz1/cmp_luasnip", lazy = true, dependencies = { "L3MON4D3/LuaSnip" } },
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-cmdline",
            "hrsh7th/cmp-nvim-lsp-document-symbol",
            "hrsh7th/cmp-nvim-lsp-signature-help",
            "hrsh7th/cmp-nvim-lua",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-calc",
            "hrsh7th/cmp-emoji",
            "petertriho/cmp-git",
            "David-Kunz/cmp-npm",
            "saadparwaiz1/cmp_luasnip"
        },
        config = function()
            local cmp = require("cmp")
            local source_mapping = {
                buffer = "[BUF]",
                nvim_lsp = "[LSP]",
                nvim_lua = "[LUA]",
                cmp_tabnine = "[T9]",
                path = "[PATH]",
            }

            cmp.setup({
                experimental = {
                    ghost_text = true,
                },
                snippet = {
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-p>"] = cmp.mapping.select_prev_item(),
                    ["<C-n>"] = cmp.mapping.select_next_item(),
                    ["<C-u>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-d>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<C-x>"] = cmp.mapping({
                        i = cmp.mapping.abort(),
                        c = cmp.mapping.close(),
                    }),
                }),

                formatting = {
                    format = function(entry, vim_item)
                        local menu = source_mapping[entry.source.name]
                        if entry.source.name == "cmp_tabnine" then
                            if entry.completion_item.data ~= nil and entry.completion_item.data.detail ~= nil then
                                menu = entry.completion_item.data.detail .. " " .. menu
                            end
                            vim_item.kind = "🤖"
                        end
                        vim_item.menu = menu
                        return vim_item
                    end,
                },

                sources = {
                    { name = "nvim_lsp_signature_help" },
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "cmp_tabnine" },
                    { name = "path" },
                    { name = "nvim_lua" },
                    { name = "emoji" },
                    { name = "npm", keyword_length = 3 },
                    { name = "buffer", keyword_length = 4 },
                },
            })

            cmp.setup.cmdline("/", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = "nvim_lsp_document_symbol" },
                    { name = "buffer" },
                },
            })

            cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = "path" },
                }, {
                    { name = "cmdline" },
                }),
            })

            cmp.setup.filetype("gitcommit", {
                sources = require("cmp").config.sources({
                    { name = "git" },
                }, {
                    { name = "buffer" },
                }),
            })

            require("cmp_git").setup({})
        end
    },
    {
        'tzachar/cmp-tabnine',
        build = './install.sh',
        dependencies = 'hrsh7th/nvim-cmp',
        config = function()
            local tabnine = require("cmp_tabnine.config")
            tabnine:setup({
                max_lines = 1000,
                max_num_results = 10,
                sort = true,
                run_on_every_keystroke = true,
                snippet_placeholder = "..",
            })
        end
    },
    { 'codota/tabnine-nvim', build = "./dl_binaries.sh" },
    {
        "simrat39/symbols-outline.nvim",
        config = function()
            require("symbols-outline").setup({
                highlight_hovered_item = true,
                show_guides = true,
            })
        end,
    },
    {
        "j-hui/fidget.nvim",
        config = function()
            require("fidget").setup({
                notification = {
                    override_vim_notify = true,
                    window = {
                        winblend = 0
                    },
                }
            })
        end,
    },
    {
        "L3MON4D3/LuaSnip",
        config = function()
            local ls = require("luasnip")
            local types = require("luasnip.util.types")

            ls.config.set_config({
                history = true,
                updateevents = "TextChanged,TextChangedI",
                enable_autosnippets = true,
                ext_opts = {
                    [types.choiceNode] = {
                        active = {
                            virt_text = { { " ← choice", "NonTest" } },
                        },
                    },
                },
            })
        end,
    },
    { "junegunn/fzf", dir = "~/.fzf", build = "./install --all", lazy = true },
    { "junegunn/fzf.vim", dependencies = { "junegunn/fzf" } },
    { "MunifTanjim/nui.nvim", event = "BufEnter package.json" },
    {
        "vuki656/package-info.nvim",
        event = "BufRead package.json",
        dependencies = { "MunifTanjim/nui.nvim" },
        config = function()
            local package_info = require("package-info")
            local key = require("timopruesse.helpers.keymap")

            package_info.setup({ autostart = true })

            key.nmap("<leader>pu", package_info.update)
            key.nmap("<leader>pd", package_info.delete)
            key.nmap("<leader>pi", package_info.install)
            key.nmap("<leader>pc", package_info.change_version)
        end,
    },
    { "leafOfTree/vim-svelte-plugin", lazy = true },
    {
        "saecki/crates.nvim",
        event = "BufRead Cargo.toml",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("crates").setup()
        end,
    },
    { "fatih/vim-go", lazy = true },
    {
        "akinsho/flutter-tools.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        lazy = true
    },
    { "ambv/black", lazy = true },
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("todo-comments").setup({})
        end,
    },
    { "tpope/vim-obsession", lazy = true },
    {
        "toppair/peek.nvim",
        event = { "VeryLazy" },
        build = "deno task --quiet build:fast",
        config = function()
            require("peek").setup()
            vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
            vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
        end
    },
    { "tpope/vim-dadbod", lazy = true },
    { "kristijanhusak/vim-dadbod-ui", dependencies = { "tpope/vim-dadbod" }, lazy = true }
})

require("timopruesse.init")
