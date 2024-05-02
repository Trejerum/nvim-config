return {
	"https://github.com/scrooloose/nerdtree",
	"folke/which-key.nvim",
	'nvim-telescope/telescope.nvim',
	'nvim-lua/plenary.nvim',
	'sbdchd/neoformat',
	{ "folke/neoconf.nvim", cmd = "Neoconf" },
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
	{
	    "lewis6991/gitsigns.nvim",
	    config = function()
	      require("config.gitsigns")
	    end,
	}
}
