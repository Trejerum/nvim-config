local M = {}

local active_job_id = nil
local results_buf = nil
local results_win = nil
local current_sql_profile = nil -- Perfil SQL seleccionado en Neovim (nil = usa el default de sql-connections.json)

--- Devuelve la ruta absoluta al archivo sql-connections.json de PowerShell
local function get_connections_file()
  local home = vim.fn.expand("~"):gsub("\\", "/")
  local dotfiles_candidate = home .. "/.dotfiles/powershell/sql-connections.json"
  if vim.fn.filereadable(dotfiles_candidate) == 1 then
    return dotfiles_candidate
  end
  local docs_candidate = home .. "/OneDrive - PKF ATTEST/Documentos/WindowsPowerShell/sql-connections.json"
  if vim.fn.filereadable(docs_candidate) == 1 then
    return docs_candidate
  end
  return dotfiles_candidate
end

--- Lee la configuración de conexiones SQL
local function load_sql_config()
  local path = get_connections_file()
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, content)
  if ok and data then return data end
  return nil
end

--- Devuelve información del perfil activo (nombre, servidor, base de datos)
function M.get_active_profile_info()
  local config = load_sql_config()
  if not config or not config.connections then
    return { name = "default", server = "localhost", database = "master" }
  end
  local prof_name = current_sql_profile or config.default or "local"
  local conn = config.connections[prof_name]
  if conn then
    return {
      name = prof_name,
      server = conn.server or "localhost",
      database = conn.database or "master",
      description = conn.description or "",
    }
  end
  return { name = prof_name, server = "localhost", database = "master" }
end

--- Selector interactivo de perfiles SQL mediante Telescope
function M.select_sql_profile()
  local config = load_sql_config()
  if not config or not config.connections then
    vim.notify("No se encontró sql-connections.json o está vacío.", vim.log.levels.WARN)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local items = {}
  local current = current_sql_profile or config.default or "local"
  for name, info in pairs(config.connections) do
    table.insert(items, {
      name = name,
      server = info.server or "",
      database = info.database or "",
      description = info.description or "",
      is_active = (name == current),
    })
  end

  table.sort(items, function(a, b) return a.name:lower() < b.name:lower() end)

  pickers.new({}, {
    prompt_title = "Seleccionar Entorno SQL Server (qenv)",
    finder = finders.new_table({
      results = items,
      entry_maker = function(entry)
        local mark = entry.is_active and "● [Activo] " or "  "
        local disp = string.format("%s%-10s -> %s / %s (%s)", mark, entry.name, entry.server, entry.database, entry.description)
        return {
          value = entry.name,
          display = disp,
          ordinal = entry.name .. " " .. entry.server .. " " .. entry.database,
          entry = entry,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local sel = action_state.get_selected_entry()
        if sel and sel.value then
          current_sql_profile = sel.value
          vim.notify(string.format("Entorno SQL cambiado a [%s] (%s / %s)", sel.value, sel.entry.server, sel.entry.database), vim.log.levels.INFO)
        end
      end)
      return true
    end,
  }):find()
end

--- Extrae el contenido SQL a ejecutar:
--- - Si hay selección visual: el fragmento seleccionado.
--- - Si only_paragraph es true: el bloque o párrafo continuo bajo el cursor delimitado por líneas en blanco.
--- - Si no: todo el buffer.
local function get_sql_content(only_paragraph)
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local _, srow, scol = unpack(vim.fn.getpos("'<"))
    local _, erow, ecol = unpack(vim.fn.getpos("'>"))
    if srow > erow then
      srow, erow = erow, srow
      scol, ecol = ecol, scol
    end
    local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
    if #lines == 0 then return "" end
    if mode == "v" then
      lines[#lines] = string.sub(lines[#lines], 1, ecol)
      lines[1] = string.sub(lines[1], scol)
    end
    return table.concat(lines, "\r\n")
  elseif only_paragraph then
    -- Extraer el bloque continuo delimitado por líneas en blanco alrededor del cursor
    local total = vim.api.nvim_buf_line_count(0)
    local cur = vim.api.nvim_win_get_cursor(0)[1]
    local s = cur
    while s > 1 and vim.api.nvim_buf_get_lines(0, s - 2, s - 1, false)[1]:match("%S") do
      s = s - 1
    end
    local e = cur
    while e < total and vim.api.nvim_buf_get_lines(0, e, e + 1, false)[1]:match("%S") do
      e = e + 1
    end
    local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
    return table.concat(lines, "\r\n")
  else
    -- Modo normal completo
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    return table.concat(lines, "\r\n")
  end
end

local function strip_ansi(str)
  if not str then return "" end
  -- Eliminar retornos de carro de Windows (\r / ^M) que ensucian los buffers en Neovim
  local clean = str:gsub("\r", "")
  -- Eliminar secuencias de escape ANSI tipo \x1b[32;1m o [32;1m
  clean = clean:gsub("\27%[[0-9;]*[a-zA-Z]", "")
  clean = clean:gsub("%[%d+;%d+m", "")
  clean = clean:gsub("%[%d+m", "")
  return clean
end

local function close_sql_window()
  if results_win and vim.api.nvim_win_is_valid(results_win) then
    local wins = vim.api.nvim_tabpage_list_wins(0)
    if #wins > 1 then
      pcall(vim.api.nvim_win_close, results_win, true)
      results_win = nil
      return
    end
  end

  local cur_buf = vim.api.nvim_get_current_buf()
  if results_buf and cur_buf == results_buf then
    local prev_buf = vim.fn.bufnr("#")
    if prev_buf ~= -1 and prev_buf ~= results_buf and vim.api.nvim_buf_is_valid(prev_buf) then
      vim.api.nvim_set_current_buf(prev_buf)
    else
      vim.cmd("enew")
    end
  end
end

local function get_or_create_results_window()
  if not (results_buf and vim.api.nvim_buf_is_valid(results_buf)) then
    results_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(results_buf, "SQL_RESULTS")
    vim.bo[results_buf].buftype = "nofile"
    vim.bo[results_buf].bufhidden = "hide"
    vim.bo[results_buf].swapfile = false
    vim.bo[results_buf].filetype = "markdown"

    -- Atajos en el buffer de resultados
    vim.keymap.set("n", "q", function()
      close_sql_window()
    end, { buffer = results_buf, nowait = true, silent = true, desc = "Cerrar panel SQL" })

    vim.keymap.set("n", "<Esc>", function()
      close_sql_window()
    end, { buffer = results_buf, nowait = true, silent = true, desc = "Cerrar panel SQL" })

    vim.keymap.set("n", "<C-c>", function()
      if active_job_id then
        vim.fn.jobstop(active_job_id)
        active_job_id = nil
        vim.notify("Consulta SQL cancelada.", vim.log.levels.WARN)
        local lines = vim.api.nvim_buf_get_lines(results_buf, 0, -1, false)
        table.insert(lines, "> 🛑 **[CANCELADO]** Ejecución abortada por el usuario.")
        vim.bo[results_buf].modifiable = true
        vim.api.nvim_buf_set_lines(results_buf, 0, -1, false, lines)
        vim.bo[results_buf].modifiable = false
      end
    end, { buffer = results_buf, nowait = true, silent = true, desc = "Cancelar consulta SQL activa" })
  end

  if not (results_win and vim.api.nvim_win_is_valid(results_win)) then
    vim.cmd("botright 14split")
    results_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(results_win, results_buf)
  else
    vim.api.nvim_win_set_buf(results_win, results_buf)
  end

  return results_buf, results_win
end

function M.toggle_results()
  if results_win and vim.api.nvim_win_is_valid(results_win) then
    close_sql_window()
    return
  end

  if not (results_buf and vim.api.nvim_buf_is_valid(results_buf)) then
    vim.notify("No hay resultados de consultas previas para mostrar.", vim.log.levels.INFO)
    return
  end

  vim.cmd("botright 14split")
  results_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(results_win, results_buf)
end

function M.cancel_running_query()
  if active_job_id then
    vim.fn.jobstop(active_job_id)
    active_job_id = nil
    vim.notify("Consulta SQL en curso detenida.", vim.log.levels.WARN)
  else
    vim.notify("No hay ninguna consulta SQL en ejecución.", vim.log.levels.INFO)
  end
end

--- Ejecuta código SQL contra la base de datos
--- @param flags string Flags adicionales para 'q' (ej. -Grid, -Clip, -Rollback)
--- @param query_str string|nil Consulta explícita a ejecutar
--- @param timeout_seconds number|nil Límite en segundos
--- @param only_paragraph boolean|nil Si es true, ejecuta solo el bloque bajo el cursor
function M.execute_sql(flags, query_str, timeout_seconds, only_paragraph)
  flags = flags or ""
  local sql = query_str or get_sql_content(only_paragraph)
  if not sql or sql:match("^%s*$") then
    vim.notify("No hay consulta SQL seleccionada o el bloque está vacío.", vim.log.levels.WARN)
    return
  end

  local prof_info = M.get_active_profile_info()
  local prof_prefix = current_sql_profile and string.format("Set-SqlProfile -Name '%s' -Quiet; ", current_sql_profile) or ""

  local timeout_flag = ""
  local timeout_desc = ""
  if timeout_seconds and tonumber(timeout_seconds) then
    local t = tonumber(timeout_seconds)
    timeout_flag = string.format(" -Timeout %d", t)
    timeout_desc = string.format(" | Timeout: %ds", t)
  end

  local dryrun_desc = flags:match("-Rollback") and " | 🛡️ DRY-RUN (ROLLBACK)" or ""
  local is_special = flags:match("-Grid") or flags:match("-Clip")

  local temp_dir = vim.fn.expand("$TEMP"):gsub("/", "\\")
  local temp_file = temp_dir .. "\\nvim_query_" .. os.date("%H%M%S") .. ".sql"

  local f = io.open(temp_file, "w")
  if not f then
    vim.notify("No se pudo crear archivo temporal SQL: " .. temp_file, vim.log.levels.ERROR)
    return
  end
  f:write(sql)
  f:close()

  local res_buf, res_win

  if not is_special then
    res_buf, res_win = get_or_create_results_window()
    vim.bo[res_buf].modifiable = true
    vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, {
      string.format("### 🗄️ SQL Runner: `[%s]` (%s / %s)%s%s", prof_info.name, prof_info.server, prof_info.database, timeout_desc, dryrun_desc),
      "> ⏳ *Ejecutando consulta en SQL Server... (Pulsa `<C-c>` para cancelar o `q`/`<Esc>` para cerrar)*",
      "",
    })
    vim.bo[res_buf].modifiable = false
    vim.api.nvim_set_current_win(res_win)
  else
    vim.notify(string.format("Ejecutando SQL contra [%s] (%s/%s)%s%s...", prof_info.name, prof_info.server, prof_info.database, timeout_desc, dryrun_desc), vim.log.levels.INFO)
  end

  local shell = vim.fn.executable("pwsh") == 1 and "pwsh.exe" or "powershell.exe"
  local cmd = string.format("%s -Command \"[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; %sq %s%s -QueryOrPath '%s'\"", shell, prof_prefix, flags, timeout_flag, temp_file)
  local stdout_data = {}

  local function append_streaming_lines(lines_to_add)
    if not res_buf or not vim.api.nvim_buf_is_valid(res_buf) then return end
    vim.schedule(function()
      vim.bo[res_buf].modifiable = true
      local cur_lines = vim.api.nvim_buf_get_lines(res_buf, 0, -1, false)
      for _, l in ipairs(lines_to_add) do
        table.insert(cur_lines, l)
      end
      vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, cur_lines)
      vim.bo[res_buf].modifiable = false

      if res_win and vim.api.nvim_win_is_valid(res_win) then
        local count = vim.api.nvim_buf_line_count(res_buf)
        pcall(vim.api.nvim_win_set_cursor, res_win, { count, 0 })
      end
    end)
  end

  active_job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      if data then
        local valid = {}
        for _, line in ipairs(data) do
          local clean_line = strip_ansi(line)
          if clean_line ~= "" then
            table.insert(valid, clean_line)
            table.insert(stdout_data, clean_line)
          end
        end
        if #valid > 0 and not is_special then
          append_streaming_lines(valid)
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        local errs = {}
        for _, line in ipairs(data) do
          local clean_line = strip_ansi(line)
          if clean_line:match("%S") then
            local formatted = "❌ " .. clean_line
            table.insert(errs, formatted)
            table.insert(stdout_data, formatted)
          end
        end
        if #errs > 0 and not is_special then
          append_streaming_lines(errs)
        end
      end
    end,
    on_exit = function(_, exit_code)
      active_job_id = nil
      pcall(os.remove, temp_file)
      if flags:match("-Grid") then
        if exit_code == 0 then
          vim.notify("Ventana Grid cerrada.", vim.log.levels.INFO)
        end
      elseif flags:match("-Clip") then
        if exit_code == 0 then
          vim.notify("Resultado SQL copiado al portapapeles (TSV).", vim.log.levels.INFO)
        else
          vim.notify("Error al exportar consulta al portapapeles.", vim.log.levels.ERROR)
        end
      else
        vim.schedule(function()
          if res_buf and vim.api.nvim_buf_is_valid(res_buf) then
            vim.bo[res_buf].modifiable = true
            local cur_lines = vim.api.nvim_buf_get_lines(res_buf, 0, -1, false)
            if #stdout_data == 0 then
              table.insert(cur_lines, "(0 filas devueltas o comando ejecutado sin salida)")
            end
            table.insert(cur_lines, "")
            table.insert(cur_lines, string.format("--- [Fin de consulta | Código: %d | Cierra con 'q' o <Esc>] ---", exit_code))
            vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, cur_lines)
            vim.bo[res_buf].modifiable = false
          end
        end)
      end
    end,
  })
end

function M.execute_sql_string(query_str, flags, timeout_seconds)
  M.execute_sql(flags or "", query_str, timeout_seconds, false)
end

function M.execute_sql_prompt_timeout(flags, only_paragraph)
  vim.ui.input({
    prompt = "Timeout SQL en segundos (ej. 30, 300, 0 para sin límite): ",
    default = "120",
  }, function(input)
    if input and input ~= "" then
      local t = tonumber(input)
      if t then
        M.execute_sql(flags or "", nil, t, only_paragraph)
      else
        vim.notify("Timeout inválido: debe ser un número entero.", vim.log.levels.ERROR)
      end
    end
  end)
end

return M
