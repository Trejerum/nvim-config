local M = {}

function M.setup()
  local status, configs = pcall(require, "nvim-treesitter.configs")
  if not status then
    return
  end

  configs.setup({
    ensure_installed = {
      "c_sharp",
      "typescript",
      "javascript",
      "html",
      "css",
      "sql",
      "json",
      "lua",
      "vim",
      "vimdoc",
      "markdown",
      "markdown_inline",
    },
    sync_install = false,
    auto_install = true,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = true,
    },
  })
end

return M
