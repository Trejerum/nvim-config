local ui = require("ai.ui")

local M = {}

-- Estado local de la sesión de terminal flotante
local state = {
    buf = nil,
    win = nil,
    job = nil,
}

--- Lanza un comando de terminal en una ventana flotante
--- @param cmd string
--- @param title string
function M.spawn_terminal(cmd, title)
    -- Si la ventana ya está abierta, la cerramos
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
        state.win = nil
    end

    state.buf = vim.api.nvim_create_buf(false, true)
    state.win = ui.open_float_win(state.buf, title)

    state.job = vim.fn.termopen(cmd, {
        on_exit = function()
            state.buf = nil
            state.win = nil
            state.job = nil
        end,
    })

    local opts = { buffer = state.buf, silent = true }
    vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n><cmd>close<CR>]], opts)
    vim.keymap.set("n", "q", "<cmd>close<CR>", opts)

    vim.cmd("startinsert")
end

--- Alterna la ventana flotante con la sesión interactiva de agy
function M.toggle_chat()
    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        ui.toggle_float(state, "Antigravity CLI (agy)")
    else
        M.spawn_terminal("agy", "Antigravity CLI (agy)")
    end
end

--- Reanuda directamente la última conversación activa (agy -c)
function M.continue_last()
    M.spawn_terminal("agy -c", "Antigravity CLI (Continuar sesión)")
end

--- Reanuda una conversación específica por su ID
--- @param id string
function M.resume_conversation(id)
    M.spawn_terminal("agy --conversation " .. id, "Antigravity CLI (" .. id:sub(1, 8) .. ")")
end

--- Obtiene la lista de conversaciones históricas desde ~/.gemini/antigravity-cli/brain/
--- @param limit number|nil
--- @return table
function M.get_conversations(limit)
    local brain_dir = vim.fn.expand("~/.gemini/antigravity-cli/brain")
    if vim.fn.isdirectory(brain_dir) ~= 1 then
        return {}
    end

    local dirs = vim.fn.readdir(brain_dir)
    local convs = {}

    for _, id in ipairs(dirs) do
        local log_path = brain_dir .. "/" .. id .. "/.system_generated/logs/transcript.jsonl"
        if vim.fn.filereadable(log_path) == 1 then
            local stat = (vim.uv or vim.loop).fs_stat(log_path)
            local mtime = stat and stat.mtime.sec or 0

            local lines = vim.fn.readfile(log_path, "", 1)
            local title = "Sin mensaje inicial"

            if #lines > 0 then
                local ok, data = pcall(vim.json.decode, lines[1])
                if ok and data.content then
                    local req = data.content:match("<USER_REQUEST>%s*(.-)%s*</USER_REQUEST>")
                    if req then
                        title = req:gsub("%s+", " "):sub(1, 75)
                    else
                        title = data.content:gsub("%s+", " "):sub(1, 75)
                    end
                end
            end

            table.insert(convs, {
                id = id,
                title = title,
                mtime = mtime,
                date = os.date("%Y-%m-%d %H:%M", mtime),
                log_path = log_path,
            })
        end
    end

    table.sort(convs, function(a, b) return a.mtime > b.mtime end)

    if limit and #convs > limit then
        local sliced = {}
        for i = 1, limit do table.insert(sliced, convs[i]) end
        return sliced
    end

    return convs
end

--- Muestra el historial de conversaciones mediante Telescope (o fallback vim.ui.select)
function M.show_history()
    local convs = M.get_conversations(50)
    if #convs == 0 then
        vim.notify("No se encontraron conversaciones de Antigravity.", vim.log.levels.INFO)
        return
    end

    local has_telescope, pickers = pcall(require, "telescope.pickers")
    if not has_telescope then
        -- Fallback estándar sin Telescope
        local items = {}
        for _, c in ipairs(convs) do
            table.insert(items, string.format("[%s] %s | %s", c.date, c.id:sub(1, 8), c.title))
        end
        vim.ui.select(items, { prompt = "Seleccionar Conversación de Antigravity:" }, function(choice, idx)
            if choice and idx then
                M.resume_conversation(convs[idx].id)
            end
        end)
        return
    end

    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local previewers = require("telescope.previewers")

    local previewer = previewers.new_buffer_previewer({
        title = "Vista Previa del Transcript",
        define_preview = function(self, entry, status)
            local conv = entry.value
            if not conv.log_path or vim.fn.filereadable(conv.log_path) ~= 1 then
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "No hay transcript disponible." })
                return
            end

            local raw_lines = vim.fn.readfile(conv.log_path, "", 60)
            local display = {
                "# Conversación: " .. conv.id,
                "**Fecha:** " .. conv.date,
                "---",
                "",
            }

            for _, l in ipairs(raw_lines) do
                local ok, data = pcall(vim.json.decode, l)
                if ok and data.content then
                    local req = data.content:match("<USER_REQUEST>%s*(.-)%s*</USER_REQUEST>")
                    if req then
                        table.insert(display, "### 👤 Petición del Usuario:")
                        for line in req:gmatch("[^\r\n]+") do
                            table.insert(display, "> " .. line)
                        end
                        table.insert(display, "")
                    elseif data.type == "PLANNER_RESPONSE" or data.source == "MODEL" then
                        table.insert(display, "### 🤖 Asistente:")
                        local count = 0
                        for line in data.content:gmatch("[^\r\n]+") do
                            table.insert(display, line)
                            count = count + 1
                            if count > 15 then
                                table.insert(display, "... [contenido truncado para vista previa]")
                                break
                            end
                        end
                        table.insert(display, "")
                    end
                end
            end

            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, display)
            vim.bo[self.state.bufnr].filetype = "markdown"
        end,
    })

    pickers.new({}, {
        prompt_title = "Historial de Conversaciones (Antigravity)",
        finder = finders.new_table({
            results = convs,
            entry_maker = function(conv)
                local display_str = string.format("%s  │  %-8s  │  %s", conv.date, conv.id:sub(1, 8), conv.title)
                return {
                    value = conv,
                    display = display_str,
                    ordinal = conv.date .. " " .. conv.id .. " " .. conv.title,
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        previewer = previewer,
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if selection and selection.value then
                    M.resume_conversation(selection.value.id)
                end
            end)
            return true
        end,
    }):find()
end

--- Ejecuta una consulta a agy -p y muestra el resultado en un split
--- @param instruction string
--- @param code string
--- @param title string
function M.query(instruction, code, title)
    local ft = vim.bo.filetype
    if ft == "" then ft = "text" end

    local buf, win = ui.open_result_split(title)

    local full_prompt = instruction
    if code and code:match("%S") then
        full_prompt = instruction .. "\n\n```" .. ft .. "\n" .. code .. "\n```"
    end

    local stdout_chunks = {}

    vim.fn.jobstart({ "agy", "-p", full_prompt }, {
        stdout_buffered = true,
        on_stdout = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    table.insert(stdout_chunks, line)
                end
            end
        end,
        on_exit = function(_, exit_code)
            vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(buf) then return end

                local header = {
                    "# " .. title,
                    "",
                    "> Concluido con éxito (código de salida: " .. exit_code .. ")",
                    "",
                    "---",
                    "",
                }

                local final_lines = {}
                for _, h in ipairs(header) do table.insert(final_lines, h) end
                for _, line in ipairs(stdout_chunks) do table.insert(final_lines, line) end

                vim.bo[buf].modifiable = true
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, final_lines)
                vim.bo[buf].modifiable = false
            end)
        end,
    })
end

return M
