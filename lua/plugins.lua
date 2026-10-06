return {
    -- Arbol de directorios
    {
        "scrooloose/nerdtree",
        cmd = { "NERDTree", "NERDTreeToggle", "NERDTreeFind", "NERDTreeCWD" },
        keys = {
            { "<Leader><TAB>", "<cmd>NERDTreeToggle<cr>", desc = "Toggle árbol de directorios" },
            { "<Leader>r", "<cmd>NERDTreeFind<cr>", desc = "Ubicar archivo en árbol" },
        },
    },

    -- Resaltado y análisis de sintaxis AST
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        cmd = { "TSInstall", "TSInstallSync", "TSUpdate", "TSUpdateSync", "TSUninstall", "TSModuleInfo" },
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("config.treesitter").setup()
        end,
    },

    -- Debug print statements
    {
        "andrewferrier/debugprint.nvim",
        cmd = { "ToggleCommentDebugPrints", "DeleteDebugPrints" },
        keys = {
            { "g?p", desc = "debugprint: variable abajo" },
            { "g?P", desc = "debugprint: variable arriba" },
        },
        config = function()
            require("debugprint").setup(require("config.debugprint"))
        end,
        dependencies = {
            "echasnovski/mini.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
        version = "*",
    },

    -- Barra de informacion
    {
        'nvim-lualine/lualine.nvim',
        event = "VeryLazy",
        config = function()
            require("config.lualine")
        end,
    },

    -- Git functionalities
    {
        "tpope/vim-fugitive",
        cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete" },
        keys = {
            { "<Leader>gg", "<cmd>Git<cr>", desc = "Git: Fugitive" },
            { "<Leader>gd", "<cmd>Gdiffsplit<cr>", desc = "Git: Diff en split" },
            { "<Leader>gp", "<cmd>Git push<cr>", desc = "Git: Push al remoto" },
        },
    },
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
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
    },

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
    {
        'tpope/vim-surround',
        event = "VeryLazy",
    },
    {
        'numToStr/Comment.nvim',
        event = { "BufReadPost", "BufNewFile" },
        opts = {},
    },

    -- Formatter
    {
        'sbdchd/neoformat',
        cmd = "Neoformat",
    },

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
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("config.gitsigns")
        end,
    },
}
