local M = {}

function M.setup()
  local status, telescope = pcall(require, "telescope")
  if not status then
    return
  end

  telescope.setup({
    defaults = {
      prompt_prefix = "> ",
      selection_caret = "> ",
      entry_prefix = "  ",
      sorting_strategy = "ascending",
      layout_strategy = "horizontal",
      layout_config = {
        prompt_position = "top",
        preview_width = 0.55,
      },
      file_ignore_patterns = {
        "%.git[/\\]",
        "node_modules[/\\]",
        "bin[/\\]",
        "obj[/\\]",
        "%.vs[/\\]",
        "dist[/\\]",
      },
    },
    pickers = {
      find_files = {
        find_command = { "fd", "--type", "f", "--hidden", "--exclude", ".git" },
        hidden = true,
      },
      live_grep = {
        additional_args = function()
          return { "--hidden", "--glob", "!.git/*" }
        end,
      },
      buffers = {
        sort_lastused = true,
        ignore_current_buffer = true,
      },
    },
  })
end

return M
