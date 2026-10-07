local M = {}

local active_job_id = nil
local results_buf = nil
local results_win = nil

local function get_sql_content()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    -- Obtener marcas de selección visual
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
  else
    -- Modo normal: buffer completo
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
  -- Si tenemos la ventana de resultados registrada y sigue abierta
  if results_win and vim.api.nvim_win_is_valid(results_win) then
    local wins = vim.api.nvim_tabpage_list_wins(0)
    if #wins > 1 then
      pcall(vim.api.nvim_win_close, results_win, true)
      results_win = nil
      return
    end
  end

  -- Si por algún motivo era la única ventana, salimos de este buffer de resultados
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
  -- Si el buffer de resultados existe y es válido, lo reutilizamos
  if not (results_buf and vim.api.nvim_buf_is_valid(results_buf)) then
    results_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(results_buf, "SQL_RESULTS")
    vim.bo[results_buf].buftype = "nofile"
    vim.bo[results_buf].bufhidden = "hide"
    vim.bo[results_buf].swapfile = false
    vim.bo[results_buf].filetype = "text"

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
        table.insert(lines, "[CANCELADO] Ejecución abortada por el usuario.")
        vim.bo[results_buf].modifiable = true
        vim.api.nvim_buf_set_lines(results_buf, 0, -1, false, lines)
        vim.bo[results_buf].modifiable = false
      end
    end, { buffer = results_buf, nowait = true, silent = true, desc = "Cancelar consulta SQL activa" })
  end

  -- Si la ventana ya está abierta, la reutilizamos; si no, creamos un split inferior
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
  -- Si la ventana ya está abierta y es válida, la cerramos
  if results_win and vim.api.nvim_win_is_valid(results_win) then
    close_sql_window()
    return
  end

  -- Si no hay buffer con resultados previos
  if not (results_buf and vim.api.nvim_buf_is_valid(results_buf)) then
    vim.notify("No hay resultados de consultas previas para mostrar.", vim.log.levels.INFO)
    return
  end

  -- Si el buffer existe, volvemos a abrir el split con el contenido intacto
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

function M.execute_sql(flags, query_str, timeout_seconds)
  flags = flags or ""
  local sql = query_str or get_sql_content()
  if not sql or sql:match("^%s*$") then
    vim.notify("No hay consulta SQL seleccionada o el buffer está vacío.", vim.log.levels.WARN)
    return
  end

  local timeout_flag = ""
  local timeout_desc = ""
  if timeout_seconds and tonumber(timeout_seconds) then
    local t = tonumber(timeout_seconds)
    timeout_flag = string.format(" -Timeout %d", t)
    timeout_desc = string.format(" (Timeout: %ds)", t)
  end

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
    -- Abrir ventana de resultados de inmediato con feedback visible
    res_buf, res_win = get_or_create_results_window()
    vim.bo[res_buf].modifiable = true
    vim.api.nvim_buf_set_lines(res_buf, 0, -1, false, {
      string.format("--- [SQL Runner] Ejecutando consulta contra SQL Server%s... ---", timeout_desc),
      "Tip: Pulsa <C-c> para cancelar o 'q' / <Esc> para cerrar este panel.",
      ""
    })
    vim.bo[res_buf].modifiable = false
    -- Mover el cursor a la ventana de resultados para que 'q' o '<C-c>' respondan al instante
    vim.api.nvim_set_current_win(res_win)
  else
    vim.notify(string.format("Ejecutando SQL contra base de datos%s...", timeout_desc), vim.log.levels.INFO)
  end

  local shell = vim.fn.executable("pwsh") == 1 and "pwsh.exe" or "powershell.exe"
  local cmd = string.format("%s -Command \"[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; q %s%s -QueryOrPath '%s'\"", shell, flags, timeout_flag, temp_file)
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

      -- Auto-scroll al final del buffer si la ventana está abierta
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
            local formatted = "[ERR] " .. clean_line
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
  M.execute_sql(flags or "", query_str, timeout_seconds)
end

function M.execute_sql_prompt_timeout(flags)
  vim.ui.input({
    prompt = "Timeout SQL en segundos (ej. 30, 300, 0 para sin límite): ",
    default = "120",
  }, function(input)
    if input and input ~= "" then
      local t = tonumber(input)
      if t then
        M.execute_sql(flags or "", nil, t)
      else
        vim.notify("Timeout inválido: debe ser un número entero.", vim.log.levels.ERROR)
      end
    end
  end)
end

return M
