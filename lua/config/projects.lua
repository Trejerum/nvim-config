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

local function get_notes_dir()
  local home = vim.fn.expand("~"):gsub("\\", "/")
  return (vim.env.NOTES_DIR or (home .. "/Documentos/Notes")):gsub("\\", "/")
end

function M.open_daily_note()
  local notes_dir = get_notes_dir()
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
  -- 1. [ ] -> [x] (completada)
  if line:match("%[%s%]") then
    return line:gsub("%[%s%]", "[x]", 1)
  -- 2. [x] o [X] -> [-] (omitida)
  elseif line:match("%[[xX]%]") then
    return line:gsub("%[[xX]%]", "[-]", 1)
  -- 3. [-] o [~] -> [ ] (reactivada)
  elseif line:match("%[[%-%~]%]") then
    return line:gsub("%[[%-%~]%]", "[ ]", 1)
  -- 4. [>] (migrada) -> [ ] (reactivada)
  elseif line:match("%[%>%]") then
    return line:gsub("%[%>%]", "[ ]", 1)
  -- 5. Viñeta existente -> añadir casilla pendiente [ ]
  elseif line:match("^%s*[-*+]%s+") then
    return line:gsub("^(%s*[-*+]%s+)", "%1[ ] ", 1)
  -- 6. Texto regular -> convertir en tarea pendiente
  elseif line:match("%S") then
    return "- [ ] " .. line
  end
  return line
end

local function omit_line(line)
  -- Si ya está omitida [-] o [~], reactivar a [ ]
  if line:match("%[[%-%~]%]") then
    return line:gsub("%[[%-%~]%]", "[ ]", 1)
  -- Si tiene casilla de cualquier otro tipo ([ ], [x], [X], [>]), pasar a [-]
  elseif line:match("%[%s%]") then
    return line:gsub("%[%s%]", "[-]", 1)
  elseif line:match("%[[xX]%]") then
    return line:gsub("%[[xX]%]", "[-]", 1)
  elseif line:match("%[%>%]") then
    return line:gsub("%[%>%]", "[-]", 1)
  -- Viñeta existente -> añadir casilla omitida [-]
  elseif line:match("^%s*[-*+]%s+") then
    return line:gsub("^(%s*[-*+]%s+)", "%1[-] ", 1)
  -- Texto regular -> convertir en tarea omitida
  elseif line:match("%S") then
    return "- [-] " .. line
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

function M.omit_markdown_task()
  local line = vim.api.nvim_get_current_line()
  local new_line = omit_line(line)
  if new_line ~= line then
    vim.api.nvim_set_current_line(new_line)
  end
end

function M.omit_markdown_task_range(start_line, end_line)
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local new_lines = {}
  for _, line in ipairs(lines) do
    new_lines[#new_lines + 1] = omit_line(line)
  end
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, new_lines)
end

function M.roll_notes()
  local notes_dir = get_notes_dir()
  if vim.fn.isdirectory(notes_dir) == 0 then
    vim.notify("El directorio de notas no existe: " .. notes_dir, vim.log.levels.WARN)
    return
  end

  local today_str = os.date("%Y%m%d")
  local files = vim.fn.globpath(notes_dir, "*.md", false, true)
  local candidates = {}
  for _, f in ipairs(files) do
    local fname = vim.fn.fnamemodify(f, ":t:r")
    if (fname:match("^%d%d%d%d%d%d%d%d$") or fname:match("^%d%d%d%d%-%d%d%-%d%d$")) and fname < today_str then
      table.insert(candidates, { path = f, name = fname })
    end
  end

  table.sort(candidates, function(a, b) return a.name > b.name end)

  if #candidates == 0 then
    vim.notify("No se encontró ninguna nota anterior a hoy (" .. today_str .. ") en " .. notes_dir, vim.log.levels.WARN)
    return
  end

  local prev = candidates[1]
  local prev_lines = vim.fn.readfile(prev.path)
  local pending_tasks = {}
  local pending_indices = {}

  for idx, l in ipairs(prev_lines) do
    local task_text = l:match("^%s*[-*+]%s*%[%s%]%s*(.*)$")
    if task_text and task_text ~= "" then
      table.insert(pending_tasks, task_text)
      table.insert(pending_indices, idx)
    end
  end

  if #pending_tasks == 0 then
    vim.notify("No hay tareas pendientes en la nota anterior (" .. prev.name .. ".md). ¡Todo al día!", vim.log.levels.INFO)
    return
  end

  -- Abrir la nota de hoy para trabajar en ella
  M.open_daily_note()

  local today_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local today_content = table.concat(today_lines, "\n")

  local to_add = {}
  for _, task in ipairs(pending_tasks) do
    if not today_content:find(task, 1, true) then
      table.insert(to_add, "- [ ] " .. task)
    end
  end

  if #to_add > 0 then
    local append_lines = { "", "## Migradas de " .. prev.name }
    for _, item in ipairs(to_add) do
      table.insert(append_lines, item)
    end
    local last_line_idx = #today_lines
    if last_line_idx > 0 and today_lines[last_line_idx] == "" then
      table.remove(append_lines, 1)
    end
    vim.api.nvim_buf_set_lines(0, -1, -1, false, append_lines)
    vim.cmd("silent! write")
  end

  -- Marcar las tareas pendientes en la nota previa como migradas (- [>])
  for _, idx in ipairs(pending_indices) do
    prev_lines[idx] = prev_lines[idx]:gsub("^(%s*[-*+]%s*)%[%s%]", "%1[>]", 1)
  end
  vim.fn.writefile(prev_lines, prev.path)

  if #to_add > 0 then
    vim.notify(string.format("✓ %d tarea(s) migrada(s) de %s.md a hoy (marcadas como [>] en el origen).", #to_add, prev.name), vim.log.levels.INFO)
  else
    vim.notify(string.format("ℹ Las tareas pendientes de %s.md ya estaban en hoy (marcadas como [>] en el origen).", prev.name), vim.log.levels.INFO)
  end
end

return M
