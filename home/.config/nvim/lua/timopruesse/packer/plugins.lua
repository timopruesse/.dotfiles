local packer = require("packer")
local use = packer.use

packer.startup(function()
    use("wbthomason/packer.nvim")

    -- theme
    use("arturgoms/moonbow.nvim")
    use("stevearc/dressing.nvim")

    use("kyazdani42/nvim-web-devicons")

    use("nvim-lua/plenary.nvim")

    -- debugging
    use("mfussenegger/nvim-dap")

    -- undo/history
    use("mbbill/undotree")

    -- refactoring
    use({
        "ThePrimeagen/refactoring.nvim",
        config = function()
            require("refactoring").setup({})
        end,
    })

    -- harpoon
    use("ThePrimeagen/harpoon")

    -- comments
    use("JoosepAlviste/nvim-ts-context-commentstring")
    use({
        "terrortylor/nvim-comment",
        config = function()
            require("nvim_comment").setup({
                hook = function()
                    require("ts_context_commentstring.internal").update_commentstring()
                end,
            })
        end,
    })

    -- telescope
    use("BurntSushi/ripgrep")
    use({
        "nvim-telescope/telescope.nvim",
        requires = { { "nvim-lua/plenary.nvim" } },
        config = function()
            ---@diagnostic disable-next-line: different-requires
            require("timopruesse.telescope")
        end,
    })
    use("nvim-telescope/telescope-fzy-native.nvim")
    use({
        "nvim-telescope/telescope-file-browser.nvim",
        requires = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    })
    use("nvim-lua/popup.nvim")

    -- lsp + autocomplete
    use("neovim/nvim-lspconfig")
    use("lvimuser/lsp-inlayhints.nvim")
    use({
        "kkharji/lspsaga.nvim",
        config = function()
            require("lspsaga").init_lsp_saga({
                code_action_icon = "",
                code_action_prompt = {
                    enable = true,
                    sign = true,
                    sign_priority = 20,
                    virtual_text = false,
                },
            })
        end,
    })
    use("hrsh7th/nvim-cmp")
    use("hrsh7th/cmp-cmdline")
    use("hrsh7th/cmp-nvim-lsp")
    use("hrsh7th/cmp-nvim-lsp-document-symbol")
    use("hrsh7th/cmp-nvim-lsp-signature-help")
    use("hrsh7th/cmp-nvim-lua")
    use("hrsh7th/cmp-path")
    use("hrsh7th/cmp-buffer")
    use("hrsh7th/cmp-calc")
    use("hrsh7th/cmp-emoji")
    use({ "tzachar/cmp-tabnine", run = "./install.sh", requires = "hrsh7th/nvim-cmp" })
    use({
        "codota/tabnine-nvim",
        run = "./dl_binaries.sh",
        config = function()
            require("tabnine").setup({
                disable_auto_comment = true,
                accept_keymap = "<Tab>",
                dismiss_keymap = "<C-]>",
                debounce_ms = 800,
                suggestion_color = { gui = "#808080", cterm = 244 },
                exclude_filetypes = { "TelescopePrompt" },
            })
        end,
    })
    use({
        "simrat39/symbols-outline.nvim",
        config = function()
            require("symbols-outline").setup({
                highlight_hovered_item = true,
                show_guides = true,
            })
        end,
    })
    use("petertriho/cmp-git")
    use("David-Kunz/cmp-npm")
    use({
        "j-hui/fidget.nvim",
        config = function()
            require("fidget").setup({ window = { blend = 0 } })
        end,
    })

    -- snippets
    use({
        "L3MON4D3/LuaSnip",
        config = function()
            ---@diagnostic disable-next-line: different-requires
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
    })
    use({ "saadparwaiz1/cmp_luasnip", requires = "L3MON4D3/LuaSnip" })

    -- treesitter
    use({
        "nvim-treesitter/nvim-treesitter",
        run = function()
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
                context_commentstring = {
                    enable = true,
                },
            })
            require("nvim-treesitter.parsers").get_parser_configs().markdown.filetype_to_parsername = "octo"
        end,
    })
    use("nvim-treesitter/nvim-treesitter-context")
    -- use("nvim-treesitter/playground")

    -- status line
    use("tamton-aquib/staline.nvim")

    -- git
    use({
        "sindrets/diffview.nvim",
        requires = "nvim-lua/plenary.nvim",
        config = function()
            require("diffview").setup({})
        end,
    })
    use({
        "NeogitOrg/neogit",
        requires = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim" },
        config = function()
            require("neogit").setup({
                disable_commit_confirmation = true,
                integrations = { diffview = true },
            })
        end,
    })

    -- fuzzy
    use({ "junegunn/fzf", dir = "~/.fzf", run = "./install --all" })
    use({ "junegunn/fzf.vim", requires = { "junegunn/fzf" } })

    -- npm
    use({ "MunifTanjim/nui.nvim", event = { "BufEnter package.json" } })
    use({
        "vuki656/package-info.nvim",
        event = { "BufRead package.json" },
        requires = "MunifTanjim/nui.nvim",
        config = function()
            local package_info = require("package-info")
            local key = require("timopruesse.helpers.keymap")

            package_info.setup({ autostart = true })

            key.nmap("<leader>pu", package_info.update)
            key.nmap("<leader>pd", package_info.delete)
            key.nmap("<leader>pi", package_info.install)
            key.nmap("<leader>pc", package_info.change_version)
        end,
    })

    -- svelte
    use("leafOfTree/vim-svelte-plugin")

    -- rust
    use({ "simrat39/rust-tools.nvim" })
    use({
        "saecki/crates.nvim",
        event = { "BufRead Cargo.toml" },
        requires = { "nvim-lua/plenary.nvim" },
        config = function()
            require("crates").setup()
        end,
    })

    -- go
    use("fatih/vim-go")

    -- dart/flutter
    use({
        "akinsho/flutter-tools.nvim",
        requires = "nvim-lua/plenary.nvim",
    })

    -- python
    use("ambv/black")

    -- todo
    use({
        "folke/todo-comments.nvim",
        requires = "nvim-lua/plenary.nvim",
        config = function()
            require("todo-comments").setup({})
        end,
    })

    -- session
    use("tpope/vim-obsession")

    -- markdown
    use({ "toppair/peek.nvim", run = "deno task --quiet build:fast" })

    -- databases
    use("tpope/vim-dadbod")
    use({ "kristijanhusak/vim-dadbod-ui", requires = "tpope/vim-dadbod" })
end)
