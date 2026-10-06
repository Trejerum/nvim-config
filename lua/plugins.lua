return {
    -- Arbol de directorios
    "https://github.com/scrooloose/nerdtree",

    -- Debug print statements
    {
        "andrewferrier/debugprint.nvim",
        config = function()
            require("debugprint").setup(require("config.debugprint"))
        end,
        dependencies = {
            "echasnovski/mini.nvim", -- Needed to enable :ToggleCommentDebugPrints for NeoVim <= 0.9
            "nvim-treesitter/nvim-treesitter" -- Needed to enable treesitter for NeoVim 0.8
        },
        version = "*"
    },

    -- Barra de informacion
    {
        'nvim-lualine/lualine.nvim',
        config = function()
            require("config.lualine")
        end,
    },

    -- Git functionalities
    "https://tpope.io/vim/fugitive.git",
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
            { "<Leader>gl", "<cmd>LazyGit<cr>", desc = "Git: Abrir Lazygit flotante" },
        },
    },

    -- Command completion for nvim
    "folke/which-key.nvim",

    -- Telescope for file, buffer and grep search
    {
        'nvim-telescope/telescope.nvim',
        branch = '0.1.x',
        cmd = "Telescope",
        keys = {
            { "<Leader>tf", "<cmd>Telescope find_files<cr>", desc = "Buscar archivos (fd)" },
            { "<Leader>tg", "<cmd>Telescope live_grep<cr>", desc = "Buscar texto en vivo (rg)" },
            { "<Leader>tb", "<cmd>Telescope buffers<cr>", desc = "Buffers abiertos" },
            { "<Leader>th", "<cmd>Telescope help_tags<cr>", desc = "Ayuda de Neovim" },
            { "<Leader>ts", "<cmd>Telescope grep_string<cr>", desc = "Buscar palabra actual (rg)" },
            { "<Leader>tr", "<cmd>Telescope resume<cr>", desc = "Reanudar última búsqueda" },
            { "<Leader>gs", "<cmd>Telescope git_status<cr>", desc = "Git: Archivos modificados" },
            { "<Leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Git: Historial de commits" },
            { "<Leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Git: Ramas" },
        },
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()
            require("config.telescope").setup()
        end,
    },

    -- Surround + Comments 
    'tpope/vim-surround',
    {
        -- :help comment-nvim
        'numToStr/Comment.nvim',
        opts = {},
        lazy = false,
    },

    -- Formatter
    'sbdchd/neoformat',

    { "folke/neoconf.nvim", cmd = "Neoconf" },

    -- Color scheme
    {
        "folke/tokyonight.nvim",
        lazy = false, -- Cargar al inicio como tema principal
        priority = 1000, -- Cargar antes que los demás plugins
        config = function()
            vim.cmd([[colorscheme tokyonight]])
        end,
    },

    -- Hop (Movimiento rapido)
    {
        "smoka7/hop.nvim",
        event = "VeryLazy",
        config = function()
            require("config.nvim_hop")
        end,
    },

    -- Show git change signs
    {
        "lewis6991/gitsigns.nvim",
        tag = "release",
        config = function()
            require("config.gitsigns")
        end,
    },
}
