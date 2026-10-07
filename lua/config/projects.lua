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

local function toggle_line(line)
  if line:match("%[%s%]") then
    local res = line:gsub("%[%s%]", "[x]", 1)
    return res
  elseif line:match("%[[xX]%]") then
    local res = line:gsub("%[[xX]%]", "[ ]", 1)
    return res
  elseif line:match("^%s*[-*+]%s+") then
    local res = line:gsub("^(%s*[-*+]%s+)", "%1[ ] ", 1)
    return res
  elseif line:match("%S") then
    return "- [ ] " .. line
  end
  return line
end

function M.toggle_markdown_task()
  local line = vim.api.nvim_get_current_line()
  local new_line = toggle_line(line)
  if new_line ~= line then
    vim.api.nvim_set_current_line(new_line)
  end
end

function M.toggle_markdown_task_range(start_line, end_line)
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local new_lines = {}
  for _, line in ipairs(lines) do
    new_lines[#new_lines + 1] = toggle_line(line)
  end
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, new_lines)
end

return M
