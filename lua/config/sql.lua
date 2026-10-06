local M = {}

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

local function show_results_buffer(output_lines)
  local buf_name = "[SQL Results]"
  local existing_buf = vim.fn.bufnr(buf_name)
  local buf
  if existing_buf ~= -1 and vim.api.nvim_buf_is_valid(existing_buf) then
    buf = existing_buf
  else
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, buf_name)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "text"
  end

  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    vim.cmd("botright 14split")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output_lines)
  vim.bo[buf].modifiable = false

  -- Atajo 'q' para cerrar la ventana de resultados
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true, silent = true })
end

function M.execute_sql(flags, query_str)
  flags = flags or ""
  local sql = query_str or get_sql_content()
  if not sql or sql:match("^%s*$") then
    vim.notify("No hay consulta SQL seleccionada o el buffer está vacío.", vim.log.levels.WARN)
    return
  end

  local temp_dir = vim.fn.expand("$TEMP"):gsub("/", "\\")
  local temp_file = temp_dir .. "\\nvim_query_" .. os.date("%H%M%S") .. ".sql"

  local f = io.open(temp_file, "w")
  if not f then
    vim.notify("No se pudo crear archivo temporal SQL: " .. temp_file, vim.log.levels.ERROR)
    return
  end
  f:write(sql)
  f:close()

  local is_special = flags:match("-Grid") or flags:match("-Clip")
  if not is_special then
    vim.notify("Ejecutando SQL contra base de datos...", vim.log.levels.INFO)
  end

  local cmd = string.format("powershell.exe -Command \"q %s -QueryOrPath '%s'\"", flags, temp_file)
  local stdout_data = {}

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stdout_data, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line:match("%S") then
            table.insert(stdout_data, "[ERR] " .. line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      os.remove(temp_file)
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
          if #stdout_data == 0 then
            table.insert(stdout_data, "(0 filas devueltas o comando ejecutado sin salida)")
          end
          show_results_buffer(stdout_data)
        end)
      end
    end,
  })
end

function M.execute_sql_string(query_str, flags)
  M.execute_sql(flags or "", query_str)
end

return M
