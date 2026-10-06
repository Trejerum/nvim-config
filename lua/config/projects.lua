local M = {}

local function get_projects_dir()
  local home = vim.fn.expand("~"):gsub("\\", "/")
  return (vim.env.PROJECTS_DIR or (home .. "/Documentos/Proyectos")):gsub("\\", "/")
end

function M.find_projects()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local pdir = get_projects_dir()
  local results = {}

  local handle = (vim.uv or vim.loop).fs_scandir(pdir)
  if handle then
    while true do
      local name, type = (vim.uv or vim.loop).fs_scandir_next(handle)
      if not name then break end
      if type == "directory" and not name:match("^%.") then
        local full_path = pdir .. "/" .. name
        table.insert(results, {
          name = name,
          path = full_path,
        })
      end
    end
  end

  table.sort(results, function(a, b) return a.name:lower() < b.name:lower() end)

  if #results == 0 then
    vim.notify("No se encontraron proyectos en: " .. pdir, vim.log.levels.WARN)
    return
  end

  pickers.new({}, {
    prompt_title = "Proyectos (" .. pdir .. ")",
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        return {
          value = entry.path,
          display = entry.name,
          ordinal = entry.name,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and selection.value then
          vim.cmd("cd " .. vim.fn.fnameescape(selection.value))
          vim.notify("Directorio cambiado: " .. selection.value, vim.log.levels.INFO)
          vim.defer_fn(function()
            require("telescope.builtin").find_files({ cwd = selection.value })
          end, 50)
        end
      end)
      return true
    end,
  }):find()
end

function M.open_daily_note()
  local home = vim.fn.expand("~"):gsub("\\", "/")
  local notes_dir = (vim.env.NOTES_DIR or (home .. "/Documentos/Notes")):gsub("\\", "/")
  if vim.fn.isdirectory(notes_dir) == 0 then
    vim.fn.mkdir(notes_dir, "p")
  end
  local today = os.date("%Y%m%d")
  local note_path = notes_dir .. "/" .. today .. ".md"
  if vim.fn.filereadable(note_path) == 0 then
    local alt = notes_dir .. "/" .. os.date("%Y-%m-%d") .. ".md"
    if vim.fn.filereadable(alt) == 1 then
      note_path = alt
    end
  end
  vim.cmd("edit " .. vim.fn.fnameescape(note_path))
end

return M
