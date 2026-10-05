local ui = require("ai.ui")

local M = {}

-- Estado local de la sesión de terminal flotante para Codex
local state = {
    buf = nil,
    win = nil,
    job = nil,
}

--- Lanza un comando de terminal en una ventana flotante
--- @param cmd string
--- @param title string
function M.spawn_terminal(cmd, title)
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

local codex_bin_cache = nil

--- Resuelve la ruta al ejecutable de Codex CLI (codex / codex.exe)
--- Replica la lógica de Get-CodexExe de PowerShell ($PROFILE)
--- @return string
function M.get_codex_bin()
    if codex_bin_cache then
        return codex_bin_cache
    end

    -- 1. Variable de entorno personalizada $CODEX_EXE
    local env_bin = vim.env.CODEX_EXE
    if env_bin and vim.fn.filereadable(env_bin) == 1 then
        codex_bin_cache = env_bin
        return codex_bin_cache
    end

    -- 2. Ejecutable ya disponible en PATH
    if vim.fn.executable("codex") == 1 then
        codex_bin_cache = "codex"
        return codex_bin_cache
    end

    -- 3. Detección automática en extensiones de VS Code (~/.vscode/extensions/openai.chatgpt*)
    local ext_dir = vim.fn.expand("~/.vscode/extensions")
    local dirs = vim.fn.glob(ext_dir .. "/openai.chatgpt*", false, true)
    if #dirs > 0 then
        table.sort(dirs)
        for i = #dirs, 1, -1 do
            local candidate = dirs[i] .. "/bin/windows-x86_64/codex.exe"
            if vim.fn.filereadable(candidate) == 1 then
                codex_bin_cache = candidate

                -- Exponer el directorio al PATH de Neovim para submódulos o comandos hijos
                local bin_dir = vim.fn.fnamemodify(candidate, ":h")
                if not vim.env.PATH:find(bin_dir, 1, true) then
                    vim.env.PATH = bin_dir .. ";" .. vim.env.PATH
                end

                return codex_bin_cache
            end
        end
    end

    -- Fallback por defecto
    codex_bin_cache = "codex"
    return codex_bin_cache
end

--- Construye la línea de comandos de Codex agregando siempre `--no-daemon`
--- para evitar errores cuando no existe el servidor daemon en segundo plano.
--- @param subcmd string|nil
--- @return string
function M.build_cmd(subcmd)
    local bin = M.get_codex_bin()
    if bin:find(" ") then
        bin = '"' .. bin .. '"'
    end

    if subcmd and subcmd ~= "" then
        return string.format("%s --no-daemon %s", bin, subcmd)
    else
        return string.format("%s --no-daemon", bin)
    end
end

--- Alterna la ventana flotante con la sesión interactiva de Codex
function M.toggle_chat()
    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        ui.toggle_float(state, "Codex CLI (OpenAI)")
    else
        M.spawn_terminal(M.build_cmd(), "Codex CLI (OpenAI)")
    end
end

--- Reanuda directamente la última conversación activa (codex --no-daemon resume --last)
function M.continue_last()
    M.spawn_terminal(M.build_cmd("resume --last"), "Codex CLI (Continuar sesión)")
end

--- Reanuda una conversación específica por su UUID
--- @param id string
function M.resume_conversation(id)
    M.spawn_terminal(M.build_cmd("resume " .. id), "Codex CLI (" .. id:sub(1, 8) .. ")")
end

--- Ejecuta codex review en la terminal flotante
function M.review_repo()
    M.spawn_terminal(M.build_cmd("review"), "Codex Review (Git)")
end

--- Aplica el último parche de Codex (codex --no-daemon apply)
--- @param task_id string|nil
function M.apply_patch(task_id)
    local cmd = M.build_cmd(task_id and ("apply " .. task_id) or "apply")
    local output = vim.fn.system(cmd)
    vim.notify(output, vim.log.levels.INFO, { title = "Codex Apply" })
end

--- Ejecuta el diagnóstico de Codex en la terminal flotante
function M.doctor()
    M.spawn_terminal(M.build_cmd("doctor"), "Codex Doctor (Diagnóstico)")
end

--- Obtiene la lista de conversaciones históricas desde ~/.codex/session_index.jsonl
--- @param limit number|nil
--- @return table
function M.get_conversations(limit)
    local index_path = vim.fn.expand("~/.codex/session_index.jsonl")
    if vim.fn.filereadable(index_path) ~= 1 then
        return {}
    end

    local lines = vim.fn.readfile(index_path)
    local convs = {}

    -- Recorrer en orden inverso (más reciente primero)
    for i = #lines, 1, -1 do
        local line = lines[i]
        if line:match("%S") then
            local ok, data = pcall(vim.json.decode, line)
            if ok and data.id and data.thread_name then
                local date_str = "Desconocida"
                if data.updated_at then
                    date_str = data.updated_at:sub(1, 16):gsub("T", " ")
                end

                table.insert(convs, {
                    id = data.id,
                    title = data.thread_name:gsub("%s+", " "),
                    date = date_str,
                })
            end
        end
        if limit and #convs >= limit then
            break
        end
    end

    return convs
end

--- Muestra el historial de conversaciones de Codex mediante Telescope (o fallback)
function M.show_history()
    local convs = M.get_conversations(100)
    if #convs == 0 then
        vim.notify("No se encontraron conversaciones previas de Codex en ~/.codex.", vim.log.levels.INFO)
        return
    end

    local has_telescope, pickers = pcall(require, "telescope.pickers")
    if not has_telescope then
        local items = {}
        for _, c in ipairs(convs) do
            table.insert(items, string.format("[%s] %s | %s", c.date, c.id:sub(1, 8), c.title))
        end
        vim.ui.select(items, { prompt = "Seleccionar Conversación de Codex:" }, function(choice, idx)
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
        title = "Detalles del Hilo de Codex",
        define_preview = function(self, entry, status)
            local conv = entry.value

            -- Buscar archivo de rollout si existe para extraer mensajes
            local pattern = vim.fn.expand("~/.codex/sessions/**/rollout-*" .. conv.id .. ".jsonl")
            local matches = vim.fn.glob(pattern, true, true)

            local display = {
                "# Hilo de Codex: " .. conv.title,
                "",
                "**ID:** `" .. conv.id .. "`",
                "**Fecha de actualización:** " .. conv.date,
                "",
                "---",
                "",
            }

            if #matches > 0 and vim.fn.filereadable(matches[1]) == 1 then
                local raw_lines = vim.fn.readfile(matches[1], "", 60)
                for _, l in ipairs(raw_lines) do
                    local ok, data = pcall(vim.json.decode, l)
                    if ok and data.payload and data.payload.role and data.payload.content then
                        local role = data.payload.role
                        if role == "user" then
                            table.insert(display, "### 👤 Usuario:")
                            for _, item in ipairs(data.payload.content) do
                                if item.text then
                                    for line in item.text:gmatch("[^\r\n]+") do
                                        table.insert(display, "> " .. line)
                                    end
                                end
                            end
                            table.insert(display, "")
                        elseif role == "assistant" then
                            table.insert(display, "### 🤖 Codex:")
                            for _, item in ipairs(data.payload.content) do
                                if item.text then
                                    local count = 0
                                    for line in item.text:gmatch("[^\r\n]+") do
                                        table.insert(display, line)
                                        count = count + 1
                                        if count > 15 then
                                            table.insert(display, "... [contenido abreviado]")
                                            break
                                        end
                                    end
                                end
                            end
                            table.insert(display, "")
                        end
                    end
                end
            else
                table.insert(display, "> *Presiona <Enter> para reanudar esta conversación en la terminal flotante.*")
            end

            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, display)
            vim.bo[self.state.bufnr].filetype = "markdown"
        end,
    })

    pickers.new({}, {
        prompt_title = "Historial de Conversaciones (Codex / VS Code)",
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

--- Ejecuta una consulta no interactiva con codex exec y muestra el resultado en un split
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
    local bin = M.get_codex_bin()

    local job = vim.fn.jobstart({ bin, "--no-daemon", "exec", full_prompt }, {
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
                    "# " .. title .. " (Codex)",
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

    -- Cerrar stdin para que codex exec proceda de inmediato
    vim.fn.chanclose(job, "stdin")
end

return M
