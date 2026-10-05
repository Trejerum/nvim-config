local ui = require("ai.ui")

local M = {}

-- Estado local de la sesión de terminal flotante
local state = {
    buf = nil,
    win = nil,
    job = nil,
}

--- Alterna la ventana flotante con la sesión interactiva de agy
function M.toggle_chat()
    ui.toggle_float(state, "Antigravity CLI (agy)", function(buf, win)
        state.job = vim.fn.termopen("agy", {
            on_exit = function()
                state.buf = nil
                state.win = nil
                state.job = nil
            end,
        })

        -- Atajos dentro de la ventana de terminal para ocultar la ventana sin matar la sesión
        local opts = { buffer = buf, silent = true }
        vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n><cmd>close<CR>]], opts)
        vim.keymap.set("n", "q", "<cmd>close<CR>", opts)

        vim.cmd("startinsert")
    end)
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
