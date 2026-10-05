local M = {}

--- Crea o alterna una ventana flotante centrada
--- @param state table { win = number|nil, buf = number|nil }
--- @param title string
--- @param on_create function(buf: number, win: number)
function M.toggle_float(state, title, on_create)
    -- Si la ventana ya está abierta y es válida, la cerramos (ocultamos)
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
        state.win = nil
        return
    end

    local width = math.floor(vim.o.columns * 0.85)
    local height = math.floor(vim.o.lines * 0.85)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)

    local is_new_buf = false
    if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
        state.buf = vim.api.nvim_create_buf(false, true)
        is_new_buf = true
    end

    state.win = vim.api.nvim_open_win(state.buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
        title = " " .. title .. " ",
        title_pos = "center",
    })

    if is_new_buf and on_create then
        on_create(state.buf, state.win)
    else
        vim.cmd("startinsert")
    end
end

--- Abre un buffer scratch tipo split vertical para mostrar respuestas de la IA
--- @param title string
--- @return number buf, number win
function M.open_result_split(title)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false

    -- Abrir división vertical a la derecha
    vim.cmd("botright vsplit")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)

    local target_width = math.max(45, math.floor(vim.o.columns * 0.40))
    vim.api.nvim_win_set_width(win, target_width)

    -- Atajo para cerrar la ventana rápida con 'q'
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true, nowait = true })

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "# " .. title,
        "",
        "> ⏳ *Consultando a Antigravity (agy)...*",
        "",
        "---",
        "",
    })

    return buf, win
end

return M
