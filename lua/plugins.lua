return {
        -- Arbol de directorios
	"https://github.com/scrooloose/nerdtree",

        -- Barra de informacion
        {
            'nvim-lualine/lualine.nvim',
	    config = function()
	      require("config.lualine")
	    end,
        },
        'nvim-tree/nvim-web-devicons',

        -- Git functionalities
	"https://tpope.io/vim/fugitive.git",

        -- Command completion for nvim
	"folke/which-key.nvim",

        -- Telescope for file,buffer and grep search
	'nvim-telescope/telescope.nvim',

	'nvim-lua/plenary.nvim',

        -- Surround + Comments 
	'tpope/vim-surround',
	{
		'numToStr/Comment.nvim',
		opts = {
		},
		lazy = false,
	},
        -- Formatter
	'sbdchd/neoformat',

	{ "folke/neoconf.nvim", cmd = "Neoconf" },

        -- Color scheme
	"folke/neodev.nvim",
	{
		"folke/tokyonight.nvim",
		lazy = false, -- make sure we load this during startup if it is your main colorscheme
		priority = 1000, -- make sure to load this before all the other start plugins
		config = function()
		-- load the colorscheme here
		vim.cmd([[colorscheme tokyonight]])
		end,
	},

	-- Hop
	{
	    "smoka7/hop.nvim",
	    event = "VeryLazy",
	    config = function()
	      require("config.nvim_hop")
	    end,
	},

	-- Show git change signs
	-- {
	--     "lewis6991/gitsigns.nvim",
	--     config = function()
	--       require("config.gitsigns")
	--     end,
	-- }
}
