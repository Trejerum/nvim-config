-- ==============================================================================
-- MÓDULO DE INTEGRACIÓN CON INTELIGENCIA ARTIFICIAL (DESACOPLADO)
-- ==============================================================================
-- Este módulo aísla por completo las herramientas de IA en Neovim.
-- Por defecto delega en Antigravity CLI ('agy'). Si en el futuro deseas cambiar
-- de proveedor (Codex, Claude, etc.) solo es necesario cambiar el módulo proveedor
-- o comentar la línea `require("ai")` en `init.lua`.
-- ==============================================================================

local M = {}

-- Proveedor activo (actualmente Antigravity 'agy')
local provider = require("ai.agy")

--- Función auxiliar para extraer el rango de código seleccionado o buffer completo
local function extract_code(opts)
    local lines
    if opts.range == 2 then
        -- Selección visual explícita
        lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
    else
        -- Archivo completo
        lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    end
    return table.concat(lines, "\n")
end

-- ==============================================================================
-- COMANDOS DE USUARIO GENÉRICOS (INDEPENDIENTES DEL PROVEEDOR)
-- ==============================================================================

-- 1. Chat interactivo en terminal flotante
vim.api.nvim_create_user_command("AiChat", function()
    provider.toggle_chat()
end, { desc = "Alternar terminal flotante con el asistente de IA" })

-- 2. Explicación de código
vim.api.nvim_create_user_command("AiExplain", function(opts)
    local code = extract_code(opts)
    provider.query(
        "Por favor explica el siguiente código de forma clara, detallando su propósito, entradas, salidas y cualquier punto clave:",
        code,
        "Explicación de Código"
    )
end, { range = "%", desc = "Explicar el código seleccionado o buffer actual con IA" })

-- 3. Revisión y auditoría de código
vim.api.nvim_create_user_command("AiReview", function(opts)
    local code = extract_code(opts)
    provider.query(
        "Realiza una auditoría exhaustiva de este código: busca posibles bugs, vulnerabilidades de seguridad, problemas de rendimiento y buenas prácticas:",
        code,
        "Revisión de Código"
    )
end, { range = "%", desc = "Revisar código con IA" })

-- 4. Refactorización guiada
vim.api.nvim_create_user_command("AiRefactor", function(opts)
    local code = extract_code(opts)
    vim.ui.input({ prompt = "Instrucciones de refactorización: " }, function(input)
        if input and input ~= "" then
            provider.query(
                "Refactoriza el siguiente código siguiendo estas instrucciones:\n" .. input .. "\n\nDevuelve el código refactorizado y explica brevemente los cambios:",
                code,
                "Refactorización de Código"
            )
        end
    end)
end, { range = "%", desc = "Refactorizar código con IA con prompt interactivo" })

-- ==============================================================================
-- ALIAS ESPECÍFICOS DE ANTIGRAVITY (PARA COMODIDAD)
-- ==============================================================================
vim.api.nvim_create_user_command("AgyChat", function() vim.cmd("AiChat") end, {})
vim.api.nvim_create_user_command("AgyExplain", function(opts) vim.cmd(opts.line1 .. "," .. opts.line2 .. "AiExplain") end, { range = "%" })
vim.api.nvim_create_user_command("AgyReview", function(opts) vim.cmd(opts.line1 .. "," .. opts.line2 .. "AiReview") end, { range = "%" })
vim.api.nvim_create_user_command("AgyRefactor", function(opts) vim.cmd(opts.line1 .. "," .. opts.line2 .. "AiRefactor") end, { range = "%" })

-- ==============================================================================
-- ATAJOS DE TECLADO (KEYMAPS)
-- ==============================================================================
local keymap = vim.keymap

-- Abrir / Alternar terminal flotante con agy
keymap.set({ "n", "t" }, "<Leader>ag", function()
    provider.toggle_chat()
end, { desc = "IA: Alternar terminal flotante (agy)", silent = true })

-- Explicar código
keymap.set("n", "<Leader>ae", "<cmd>AiExplain<CR>", { desc = "IA: Explicar archivo completo", silent = true })
keymap.set("v", "<Leader>ae", ":AiExplain<CR>", { desc = "IA: Explicar selección", silent = true })

-- Revisar código
keymap.set("n", "<Leader>ar", "<cmd>AiReview<CR>", { desc = "IA: Revisar archivo completo", silent = true })
keymap.set("v", "<Leader>ar", ":AiReview<CR>", { desc = "IA: Revisar selección", silent = true })

-- Refactorizar código
keymap.set("n", "<Leader>af", "<cmd>AiRefactor<CR>", { desc = "IA: Refactorizar archivo completo", silent = true })
keymap.set("v", "<Leader>af", ":AiRefactor<CR>", { desc = "IA: Refactorizar selección", silent = true })

return M
