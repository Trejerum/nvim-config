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

function M.set_task_priority(level)
  local line = vim.api.nvim_get_current_line()
  if not line:match("^%s*[-*+]%s*%[[ xX>~-]%s*%]") then
    vim.notify("La línea actual no es una tarea Markdown (- [ ]).", vim.log.levels.WARN)
    return
  end

  local clean_line = line:gsub("(%[%s*[xX>~-]%s*%]%s*)%[P%d%]%s*", "%1")
  local str_level = tostring(level or "0")

  if str_level == "1" or str_level == "2" or str_level == "3" then
    local new_line = clean_line:gsub("^(%s*[-*+]%s*%[[ xX>~-]%s*%]%s*)", "%1[P" .. str_level .. "] ")
    vim.api.nvim_set_current_line(new_line)
    vim.notify("✓ Prioridad [P" .. str_level .. "] asignada.", vim.log.levels.INFO)
  else
    vim.api.nvim_set_current_line(clean_line)
    vim.notify("✓ Prioridad retirada.", vim.log.levels.INFO)
  end
end

function M.cycle_task_priority()
  local line = vim.api.nvim_get_current_line()
  if not line:match("^%s*[-*+]%s*%[[ xX>~-]%s*%]") then
    vim.notify("La línea actual no es una tarea Markdown (- [ ]).", vim.log.levels.WARN)
    return
  end

  local cur_pri = line:match("%[P(%d)%]")
  local next_level = 1
  if not cur_pri then
    next_level = 1
  elseif cur_pri == "1" then
    next_level = 2
  elseif cur_pri == "2" then
    next_level = 3
  else
    next_level = 0
  end
  M.set_task_priority(next_level)
end

function M.roll_notes(include_notes)
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
  local pending_subnotes = {}

  for idx, l in ipairs(prev_lines) do
    local task_text = l:match("^%s*[-*+]%s*%[%s%]%s*(.*)$")
    if task_text and task_text ~= "" then
      table.insert(pending_tasks, task_text)
      table.insert(pending_indices, idx)
      local sub = {}
      local j = idx + 1
      while j <= #prev_lines and (prev_lines[j]:match("^%s%s%s%s%S") or prev_lines[j]:match("^\t%S")) do
        table.insert(sub, prev_lines[j])
        j = j + 1
      end
      table.insert(pending_subnotes, sub)
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
  for k, task in ipairs(pending_tasks) do
    local base_task = task:match("^%s*%[%>%s*[^%]]+%]%([^%)]+%)%s*(.*)$")
      or task:match("^%s*%[%>%s*[^%]]+%]%s*(.*)$")
      or task
    if not today_content:find(base_task, 1, true) then
      table.insert(to_add, string.format("- [ ] [> %s](%s.md) %s", prev.name, prev.name, base_task))
      if include_notes and pending_subnotes[k] and #pending_subnotes[k] > 0 then
        for _, sn in ipairs(pending_subnotes[k]) do
          table.insert(to_add, sn)
        end
      end
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

  local with_notes_label = include_notes and " (con apuntes)" or ""
  if #to_add > 0 then
    vim.notify(string.format("✓ %d tarea(s) migrada(s)%s de %s.md a hoy (marcadas como [>] en el origen).", #to_add, with_notes_label, prev.name), vim.log.levels.INFO)
  else
    vim.notify(string.format("ℹ Las tareas pendientes de %s.md ya estaban en hoy (marcadas como [>] en el origen).", prev.name), vim.log.levels.INFO)
  end
end

function M.goto_task_origin()
  local line = vim.api.nvim_get_current_line()
  local notes_dir = get_notes_dir()

  -- 1. Buscar referencia a archivo de origen en la línea actual
  -- Formatos soportados:
  --   a) [> 20261012](20261012.md) o [texto](archivo.md)
  --   b) [> 20261012] o [> 2026-10-12]
  --   c) [[20261012]] o [[20261012.md]]
  local target_file = nil

  -- Caso a: Enlace markdown estándar tipo (...*.md)
  local md_link = line:match("%(%s*([%w%-_]+%.md)%s*%)")
  if md_link then
    target_file = md_link
  else
    -- Caso b: Etiqueta [> YYYYMMDD] o [> YYYY-MM-DD]
    local tag_date = line:match("%[%>%s*([%w%-_]+)%]")
    if tag_date then
      target_file = tag_date .. ".md"
    else
      -- Caso c: Wiki-link [[YYYYMMDD]]
      local wiki_link = line:match("%[%[([%w%-_]+)%]%]")
      if wiki_link then
        target_file = wiki_link:match("%.md$") and wiki_link or (wiki_link .. ".md")
      end
    end
  end

  if not target_file then
    vim.notify("No se encontró ningún enlace o referencia de origen ([> YYYYMMDD](...) o [> YYYYMMDD]) en la línea actual.", vim.log.levels.WARN)
    return
  end

  local full_path = notes_dir .. "/" .. target_file
  if vim.fn.filereadable(full_path) == 0 then
    local found = vim.fn.globpath(notes_dir, "**/" .. target_file, false, true)
    if #found > 0 then
      full_path = found[1]
    else
      vim.notify("No se encontró el archivo de notas de origen: " .. target_file, vim.log.levels.ERROR)
      return
    end
  end

  -- Extraer el texto base de la tarea para ubicarla en el origen
  local task_desc = line:match("^%s*[-*+]%s*%[[ xX>~-]%s*%]%s*(.*)$") or line
  local base_task = task_desc:gsub("^%[%>%s*[^%]]+%]%([^%)]+%)%s*", "")
                             :gsub("^%[%>%s*[^%]]+%]%s*", "")
                             :gsub("^%[%[[^%]]+%]%]%s*", "")
                             :gsub("^%s+", ""):gsub("%s+$", "")

  -- Guardar posición actual en el jumplist para volver fácil con <Ctrl-o>
  vim.cmd("normal! m'")

  -- Abrir archivo origen
  vim.cmd("edit " .. vim.fn.fnameescape(full_path))

  -- Localizar línea de la tarea original
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local target_lnum = nil

  if base_task and base_task ~= "" then
    for idx, l in ipairs(lines) do
      if l:find(base_task, 1, true) then
        target_lnum = idx
        break
      end
    end
  end

  if target_lnum then
    vim.api.nvim_win_set_cursor(0, { target_lnum, 0 })
    vim.cmd("normal! zz")
    vim.notify(string.format("✓ Origen en %s (Línea %d). Usa <Ctrl-o> para volver.", target_file, target_lnum), vim.log.levels.INFO)
  else
    vim.notify(string.format("ℹ Abierto %s. Usa <Ctrl-o> para volver a la nota de hoy.", target_file), vim.log.levels.INFO)
  end
end

function M.show_task_history()
  local line = vim.api.nvim_get_current_line()
  local notes_dir = get_notes_dir()
  local lnum = vim.fn.line(".")
  local current_buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Si el cursor está en un apunte identado, subir a la tarea padre
  if line:match("^%s%s%s%s%S") or line:match("^\t%S") then
    for k = lnum - 1, 1, -1 do
      if current_buf_lines[k]:match("^%s*[-*+]%s*%[[ xX>~-]%s*%]") then
        line = current_buf_lines[k]
        lnum = k
        break
      end
    end
  end

  if not line:match("^%s*[-*+]%s*%[[ xX>~-]%s*%]") then
    vim.notify("La línea actual no es una tarea Markdown (- [ ]).", vim.log.levels.WARN)
    return
  end

  -- Extraer texto base eliminando marcas de migración y prioridad
  local task_desc = line:match("^%s*[-*+]%s*%[[ xX>~-]%s*%]%s*(.*)$") or line
  local base_task = task_desc:gsub("^%[P%d%]%s*", "")
                             :gsub("^%[%>%s*[^%]]+%]%([^%)]+%)%s*", "")
                             :gsub("^%[%>%s*[^%]]+%]%s*", "")
                             :gsub("^%[%[[^%]]+%]%]%s*", "")
                             :gsub("^%s+", ""):gsub("%s+$", "")

  if not base_task or base_task == "" then
    vim.notify("No se pudo identificar la descripción base de la tarea.", vim.log.levels.WARN)
    return
  end

  local current_file_path = vim.api.nvim_buf_get_name(0):gsub("\\", "/")
  local current_file_name = vim.fn.fnamemodify(current_file_path, ":t")
  local current_base_name = vim.fn.fnamemodify(current_file_path, ":t:r")

  local chain = {}
  local visited = {}

  -- Nodo inicial (buffer actual)
  local cur_subnotes = {}
  local j = lnum + 1
  while j <= #current_buf_lines and (current_buf_lines[j]:match("^%s%s%s%s%S") or current_buf_lines[j]:match("^\t%S")) do
    table.insert(cur_subnotes, (current_buf_lines[j]:gsub("^%s+", "")))
    j = j + 1
  end

  local cur_marker = line:match("^%s*[-*+]%s*%[([ xX>~-])%]") or " "
  table.insert(chain, {
    file = current_file_path,
    name = current_file_name,
    base_name = current_base_name,
    marker = cur_marker,
    line_num = lnum,
    subnotes = cur_subnotes,
    raw_line = line
  })
  visited[current_file_path] = true

  local search_line = line
  while true do
    local prev_file = search_line:match("%(%s*([%w%-_]+%.md)%s*%)")
    if not prev_file then
      local tag_date = search_line:match("%[%>%s*([%w%-_]+)%]")
      if tag_date then
        prev_file = tag_date .. ".md"
      else
        local wiki_link = search_line:match("%[%[([%w%-_]+)%]%]")
        if wiki_link then
          prev_file = wiki_link:match("%.md$") and wiki_link or (wiki_link .. ".md")
        end
      end
    end

    if not prev_file then break end

    local full_path = notes_dir .. "/" .. prev_file
    if vim.fn.filereadable(full_path) == 0 then
      local found = vim.fn.globpath(notes_dir, "**/" .. prev_file, false, true)
      if #found > 0 then full_path = found[1] else break end
    end

    if visited[full_path] then break end
    visited[full_path] = true

    local prev_lines = vim.fn.readfile(full_path)
    local found_idx = nil
    for idx, l in ipairs(prev_lines) do
      if l:match("^%s*[-*+]%s*%[[ xX>~-]%s*%]") and l:find(base_task, 1, true) then
        found_idx = idx
        break
      end
    end

    if found_idx then
      local p_line = prev_lines[found_idx]
      local p_marker = p_line:match("^%s*[-*+]%s*%[([ xX>~-])%]") or " "
      local p_sub = {}
      local m = found_idx + 1
      while m <= #prev_lines and (prev_lines[m]:match("^%s%s%s%s%S") or prev_lines[m]:match("^\t%S")) do
        table.insert(p_sub, (prev_lines[m]:gsub("^%s+", "")))
        m = m + 1
      end

      table.insert(chain, {
        file = full_path,
        name = prev_file,
        base_name = vim.fn.fnamemodify(prev_file, ":r"),
        marker = p_marker,
        line_num = found_idx,
        subnotes = p_sub,
        raw_line = p_line
      })

      search_line = p_line
    else
      break
    end
  end

  -- Invertir la cadena para orden cronológico (Origen -> Hoy)
  local chrono = {}
  for i = #chain, 1, -1 do
    table.insert(chrono, chain[i])
  end

  local display_lines = {}
  table.insert(display_lines, " Hilo Histórico: " .. base_task)
  local dates = {}
  for _, n in ipairs(chrono) do table.insert(dates, n.base_name) end
  table.insert(display_lines, " Cadena: " .. table.concat(dates, " → "))
  table.insert(display_lines, string.rep("─", 68))

  local line_to_target = {}

  for _, node in ipairs(chrono) do
    local is_today = (node.base_name == os.date("%Y%m%d"))
    local is_origin = (node.base_name == chrono[1].base_name and #chrono > 1)
    local tag = is_today and " (Hoy)" or (is_origin and " (Origen)" or "")
    local box = "[" .. node.marker .. "]"

    local header = string.format(" ● %s%s  %s  (L:%d en %s)", node.base_name, tag, box, node.line_num, node.name)
    table.insert(display_lines, header)
    line_to_target[#display_lines] = { file = node.file, line_num = node.line_num }

    if #node.subnotes > 0 then
      for _, sn in ipairs(node.subnotes) do
        table.insert(display_lines, "     ↳ " .. sn)
        line_to_target[#display_lines] = { file = node.file, line_num = node.line_num }
      end
    else
      table.insert(display_lines, "     ↳ (Sin apuntes en esta fecha)")
      line_to_target[#display_lines] = { file = node.file, line_num = node.line_num }
    end
    table.insert(display_lines, "")
  end

  table.insert(display_lines, string.rep("─", 68))
  table.insert(display_lines, " [Enter]: Saltar a fecha seleccionada | [q/Esc]: Cerrar")

  -- Crear buffer flotante
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")

  local width = math.min(math.floor(vim.o.columns * 0.9), 92)
  local height = math.min(#display_lines + 2, math.floor(vim.o.lines * 0.85))
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
    title = " Historial de Tarea (:TodoHistory) ",
    title_pos = "center",
  })

  local close_fn = function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.keymap.set("n", "q", close_fn, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close_fn, { buffer = buf, nowait = true })

  -- Saltar a la fecha / archivo al pulsar Enter
  vim.keymap.set("n", "<CR>", function()
    local cur_l = vim.fn.line(".")
    local target = line_to_target[cur_l]
    close_fn()
    if target and vim.fn.filereadable(target.file) == 1 then
      vim.cmd("normal! m'")
      vim.cmd("edit " .. vim.fn.fnameescape(target.file))
      if target.line_num then
        vim.api.nvim_win_set_cursor(0, { target.line_num, 0 })
        vim.cmd("normal! zz")
      end
    end
  end, { buffer = buf, nowait = true })
end

-- Configurar búsqueda de notas para salto con comando 'gf' nativo de Vim y colores de prioridades
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    local ndir = get_notes_dir()
    vim.opt_local.suffixesadd:prepend(".md")
    if vim.fn.isdirectory(ndir) == 1 then
      vim.opt_local.path:prepend(ndir)
    end
    vim.cmd([[
      syntax match TodoPriP1 "\[P1\]"
      syntax match TodoPriP2 "\[P2\]"
      syntax match TodoPriP3 "\[P3\]"
      highlight default TodoPriP1 guifg=#ff5555 gui=bold ctermfg=Red cterm=bold
      highlight default TodoPriP2 guifg=#ffb86c gui=bold ctermfg=Yellow cterm=bold
      highlight default TodoPriP3 guifg=#8be9fd gui=bold ctermfg=Cyan cterm=bold
    ]])
  end,
})

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
  local entry_line = string.format("    [%s - %s] %gh%s", start_hm, end_hm, hours, comment_str)

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
      local quarters = math.max(1, math.ceil(elapsed_min / 15.0))
      local hours = quarters * 0.25
      record_time_entry(prev_timer, hours, elapsed_min, "Cambio de tarea")
      vim.notify(string.format("● Tarea anterior cerrada: %gh registradas.", hours), vim.log.levels.INFO)
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
  local quarters = math.max(1, math.ceil(elapsed_min / 15.0))
  local hours = quarters * 0.25

  local prompt_msg = string.format("Comentario para %gh en '%s' (opcional): ", hours, timer.TaskText:sub(1, 40))
  vim.ui.input({ prompt = prompt_msg }, function(comment)
    local entry_line = record_time_entry(timer, hours, elapsed_min, comment)
    remove_timer()
    vim.notify(string.format("✓ Cronómetro DETENIDO: %gh (%d min) registradas:\n  ↳ %s", hours, elapsed_min, entry_line:gsub("^%s*", "")), vim.log.levels.INFO)
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
  local quarters = math.max(1, math.ceil(math.max(1, elapsed_min) / 15.0))
  local hours = quarters * 0.25

  vim.notify(string.format("⏱ Cronómetro Activo: %d min %d seg (~%gh)\n  Tarea: %s\n  Inicio: %s",
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

function M.open_in_browser(is_time_entry, target_id)
  local function do_open(id)
    if not id or id == "" then
      vim.notify("No se especificó ningún número de ticket.", vim.log.levels.WARN)
      return
    end
    local clean_id = id:gsub("[#%s]", "")
    local base_url = "https://bluemine.pkf-attest.es/issues/" .. clean_id
    local url = is_time_entry and (base_url .. "/time_entries/new") or base_url
    vim.ui.open(url)
    local desc = is_time_entry and "formulario de tiempo" or "ticket"
    vim.notify(string.format("✓ Abriendo %s #%s en Bluemine...", desc, clean_id), vim.log.levels.INFO)
  end

  if target_id and target_id ~= "" then
    do_open(target_id)
    return
  end

  local line = vim.api.nvim_get_current_line()
  local found_id = line:match("#(%d%d%d%d+)") or line:match("(%d%d%d%d%d+)")

  if not found_id then
    local cur_lnum = vim.fn.line(".")
    for l = cur_lnum - 1, math.max(1, cur_lnum - 15), -1 do
      local prev_l = vim.fn.getline(l)
      found_id = prev_l:match("#(%d%d%d%d+)")
      if found_id then break end
    end
  end

  if found_id then
    do_open(found_id)
  else
    vim.ui.input({ prompt = "Número de ticket Bluemine a abrir: " }, function(input)
      if input and input ~= "" then
        do_open(input)
      end
    end)
  end
end

function M.hours_step()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.min(math.floor(vim.o.columns * 0.9), 92)
  local height = math.min(math.floor(vim.o.lines * 0.85), 26)
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
    title = " Asistente Guiado de Imputación Bluemine (:HoursStep) ",
    title_pos = "center",
  })

  local cmd = "powershell -NoLogo -NoProfile -Command \". $HOME/.dotfiles/powershell/Microsoft.PowerShell_profile.ps1; hours -Step\""
  if vim.fn.executable("pwsh") == 1 then
    cmd = "pwsh -NoLogo -NoProfile -Command \". $HOME/.dotfiles/powershell/Microsoft.PowerShell_profile.ps1; hours -Step\""
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

function M.todo_wizard()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.min(math.floor(vim.o.columns * 0.9), 92)
  local height = math.min(math.floor(vim.o.lines * 0.85), 26)
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
    title = " Asistente de Revisión de Tareas (:TodoWizard) ",
    title_pos = "center",
  })

  local cmd = "powershell -NoLogo -NoProfile -Command \". $HOME/.dotfiles/powershell/Microsoft.PowerShell_profile.ps1; todo -Wizard\""
  if vim.fn.executable("pwsh") == 1 then
    cmd = "pwsh -NoLogo -NoProfile -Command \". $HOME/.dotfiles/powershell/Microsoft.PowerShell_profile.ps1; todo -Wizard\""
  end

  vim.fn.termopen(cmd, {
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      vim.cmd("checktime")
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

