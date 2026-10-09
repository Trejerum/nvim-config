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

function M.add_task_note()
  local lnum = vim.fn.line(".")
  local time_str = os.date("%H:%M")
  local note_prefix = string.format("    [%s] ", time_str)
  vim.api.nvim_buf_set_lines(0, lnum, lnum, false, { note_prefix })
  vim.api.nvim_win_set_cursor(0, { lnum + 1, #note_prefix })
  vim.cmd("startinsert!")
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
    local base_task = task:match("^%s*%[%>%s*%d%d%d%d%d%d%d%d%]%s*(.*)$") or task
    if not today_content:find(base_task, 1, true) then
      table.insert(to_add, string.format("- [ ] [> %s] %s", prev.name, base_task))
    end
  end

  if #to_add > 0 then
    -- Encontrar la posición de inserción: justo después de # YYYYMMDD y líneas vacías
    local insert_idx = 0
    for idx, line in ipairs(today_lines) do
      if line:match("^#%s+") then
        insert_idx = idx
        while insert_idx < #today_lines and today_lines[insert_idx + 1] == "" do
          insert_idx = insert_idx + 1
        end
        break
      end
    end
    vim.api.nvim_buf_set_lines(0, insert_idx, insert_idx, false, to_add)
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

-- ==============================================================================
-- CRONÓMETRO DE TAREAS & CONTROL DE HORAS (Sinergia con profile.d/35-bluemine.ps1)
-- ==============================================================================

local function get_timer_file()
  local home = vim.fn.expand("~"):gsub("\\", "/")
  return home .. "/.active_task_timer.json"
end

local function read_timer()
  local path = get_timer_file()
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  if not content or content == "" then return nil end
  local ok, data = pcall(vim.json.decode, content)
  if ok and data then return data end
  return nil
end

local function write_timer(data)
  local path = get_timer_file()
  local ok, json_str = pcall(vim.json.encode, data)
  if not ok then return false end
  local f = io.open(path, "w")
  if not f then return false end
  f:write(json_str)
  f:close()
  return true
end

local function remove_timer()
  local path = get_timer_file()
  os.remove(path)
end

local function parse_iso_time(str)
  if not str then return os.time() end
  local y, m, d, H, M, S = str:match("(%d+)-(%d+)-(%d+)[T ](%d+):(%d+):(%d+)")
  if y and m and d and H and M and S then
    return os.time({
      year = tonumber(y),
      month = tonumber(m),
      day = tonumber(d),
      hour = tonumber(H),
      min = tonumber(M),
      sec = tonumber(S)
    })
  end
  return os.time()
end

local function record_time_entry(timer, hours, minutes, comment)
  local start_time = parse_iso_time(timer.StartTime)
  local start_hm = os.date("%H:%M", start_time)
  local end_hm = os.date("%H:%M")
  local comment_str = (comment and comment ~= "") and (" | " .. comment) or ""
  local entry_line = string.format("    [%s - %s] %.2fh%s", start_hm, end_hm, hours, comment_str)

  local target_path = timer.File
  if not target_path or target_path == "" then
    local notes_dir = get_notes_dir()
    local today_str = os.date("%Y%m%d")
    target_path = notes_dir .. "/" .. (timer.FileName or (today_str .. ".md"))
  end

  local inserted = false
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local bname = vim.api.nvim_buf_get_name(buf):gsub("\\", "/")
      if bname == target_path:gsub("\\", "/") then
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local target_lnum = nil
        if timer.LineNumber and lines[timer.LineNumber] and lines[timer.LineNumber]:find(timer.TaskText, 1, true) then
          target_lnum = timer.LineNumber
        else
          for idx, l in ipairs(lines) do
            if l:find(timer.TaskText, 1, true) then
              target_lnum = idx
              break
            end
          end
        end

        if target_lnum then
          local insert_at = target_lnum
          while insert_at < #lines and lines[insert_at + 1]:match("^%s%s%s%s+") do
            insert_at = insert_at + 1
          end
          vim.api.nvim_buf_set_lines(buf, insert_at, insert_at, false, { entry_line })
          inserted = true
          break
        end
      end
    end
  end

  if not inserted then
    if vim.fn.filereadable(target_path) == 1 then
      local lines = vim.fn.readfile(target_path)
      local target_lnum = nil
      for idx, l in ipairs(lines) do
        if l:find(timer.TaskText, 1, true) then
          target_lnum = idx
          break
        end
      end
      if target_lnum then
        local insert_at = target_lnum
        while insert_at < #lines and lines[insert_at + 1]:match("^%s%s%s%s+") do
          insert_at = insert_at + 1
        end
        table.insert(lines, insert_at + 1, entry_line)
        vim.fn.writefile(lines, target_path)
        inserted = true
      else
        table.insert(lines, entry_line)
        vim.fn.writefile(lines, target_path)
        inserted = true
      end
    end
  end

  return entry_line
end

function M.task_start()
  local line = vim.api.nvim_get_current_line()
  local task_text = line:match("^%s*[-*+]%s*%[[ xX>~-]%s*%]%s*(.*)$") or line:match("^%s*[-*+]%s*%[%s*%]%s*(.*)$")
  local lnum = vim.fn.line(".")
  local cur_file = vim.api.nvim_buf_get_name(0):gsub("\\", "/")
  local fname = vim.fn.fnamemodify(cur_file, ":t")

  local function do_start(target_text)
    if not target_text or target_text == "" then
      vim.notify("No se indicó ninguna tarea para iniciar el cronómetro.", vim.log.levels.WARN)
      return
    end

    local prev_timer = read_timer()
    if prev_timer then
      local start_time = parse_iso_time(prev_timer.StartTime)
      local elapsed_sec = math.max(0, os.time() - start_time)
      local elapsed_min = math.max(1, math.floor(elapsed_sec / 60))
      local hours = math.max(0.05, math.floor((elapsed_min / 60) * 100 + 0.5) / 100)
      record_time_entry(prev_timer, hours, elapsed_min, "Cambio de tarea")
      vim.notify(string.format("● Tarea anterior cerrada: %.2fh registradas.", hours), vim.log.levels.INFO)
    end

    local ticket_id = target_text:match("#(%d%d%d%d%d+)")
    local new_timer = {
      TaskIdx = 0,
      TaskText = target_text,
      TicketId = ticket_id,
      File = cur_file,
      FileName = fname,
      LineNumber = lnum,
      StartTime = os.date("%Y-%m-%dT%H:%M:%S"),
      Comment = "",
    }
    write_timer(new_timer)
    vim.notify(string.format("⏱ Cronómetro INICIADO a las %s:\n  %s", os.date("%H:%M:%S"), target_text), vim.log.levels.INFO)
  end

  if task_text and task_text ~= "" then
    do_start(task_text)
  else
    vim.ui.input({ prompt = "Tarea o ticket para cronometrar: " }, function(input)
      if input and input ~= "" then
        do_start(input)
      end
    end)
  end
end

function M.task_stop()
  local timer = read_timer()
  if not timer then
    vim.notify("ℹ No hay ningún cronómetro de tarea activo.", vim.log.levels.WARN)
    return
  end

  local start_time = parse_iso_time(timer.StartTime)
  local elapsed_sec = math.max(0, os.time() - start_time)
  local elapsed_min = math.max(1, math.floor(elapsed_sec / 60))
  local hours = math.max(0.05, math.floor((elapsed_min / 60) * 100 + 0.5) / 100)

  local prompt_msg = string.format("Comentario para %.2fh en '%s' (opcional): ", hours, timer.TaskText:sub(1, 40))
  vim.ui.input({ prompt = prompt_msg }, function(comment)
    local entry_line = record_time_entry(timer, hours, elapsed_min, comment)
    remove_timer()
    vim.notify(string.format("✓ Cronómetro DETENIDO: %.2fh (%d min) registradas:\n  ↳ %s", hours, elapsed_min, entry_line:gsub("^%s*", "")), vim.log.levels.INFO)
  end)
end

function M.task_status()
  local timer = read_timer()
  if not timer then
    vim.notify("● No hay ninguna tarea activa en el cronómetro.", vim.log.levels.INFO)
    return
  end

  local start_time = parse_iso_time(timer.StartTime)
  local elapsed_sec = math.max(0, os.time() - start_time)
  local elapsed_min = math.floor(elapsed_sec / 60)
  local rem_sec = elapsed_sec % 60
  local hours = math.floor((elapsed_min / 60) * 100 + 0.5) / 100

  vim.notify(string.format("⏱ Cronómetro Activo: %d min %d seg (~%.2fh)\n  Tarea: %s\n  Inicio: %s",
    elapsed_min, rem_sec, hours, timer.TaskText, os.date("%H:%M:%S", start_time)), vim.log.levels.INFO)
end

function M.show_hours()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.min(math.floor(vim.o.columns * 0.85), 84)
  local height = math.min(math.floor(vim.o.lines * 0.8), 24)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Control de Jornada & Horas (hours) ",
    title_pos = "center",
  })

  local cmd = "powershell -NoLogo -NoProfile -Command \". $HOME/.dotfiles/powershell/Microsoft.PowerShell_profile.ps1; hours; Write-Host '`nPresiona una tecla para cerrar...' -ForegroundColor DarkGray; [Console]::ReadKey($true) | Out-Null\""
  if vim.fn.executable("pwsh") == 1 then
    cmd = "pwsh -NoLogo -NoProfile -Command \". $HOME/.dotfiles/powershell/Microsoft.PowerShell_profile.ps1; hours; Write-Host '`nPresiona una tecla para cerrar...' -ForegroundColor DarkGray; [Console]::ReadKey($true) | Out-Null\""
  end

  vim.fn.termopen(cmd, {
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })
  vim.cmd("startinsert")

  local close_fn = function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.keymap.set("n", "q", close_fn, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close_fn, { buffer = buf, nowait = true })
end

return M
