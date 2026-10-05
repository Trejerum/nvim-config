-- ==============================================================================
-- MÓDULO DE INTEGRACIÓN CON INTELIGENCIA ARTIFICIAL (DESACOPLADO)
-- ==============================================================================
-- Este módulo centraliza y aísla las herramientas de IA en Neovim.
-- Soporta de forma nativa dos proveedores CLI del sistema:
--   1. Antigravity CLI ('agy')   -> Atajos con prefijo <Leader>a...
--   2. OpenAI Codex CLI ('codex') -> Atajos con prefijo <Leader>c...
--
-- Para desactivar la IA por completo: comentar `require("ai")` en `init.lua`.
-- ==============================================================================

local M = {}

-- Registro de proveedores
local providers = {
    agy = require("ai.agy"),
    codex = require("ai.codex"),
}

-- Proveedor activo por defecto
local active_name = "agy"
local active_provider = providers.agy

--- Cambia el proveedor activo en tiempo de ejecución ('agy' o 'codex')
--- @param name string
function M.set_provider(name)
    if providers[name] then
        active_name = name
        active_provider = providers[name]
        vim.notify("Proveedor de IA activo cambiado a: " .. name:upper(), vim.log.levels.INFO, { title = "AI Assistant" })
    else
        vim.notify("Proveedor no reconocido ('" .. tostring(name) .. "'). Opciones: 'agy', 'codex'", vim.log.levels.WARN)
    end
end

--- Extrae el rango de código seleccionado o el buffer completo
local function extract_code(opts)
    local lines
    if opts.range == 2 then
        lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
    else
        lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    end
    return table.concat(lines, "\n")
end

-- ==============================================================================
-- COMANDOS GENÉRICOS (OPERAN SOBRE EL PROVEEDOR ACTIVO)
-- ==============================================================================

vim.api.nvim_create_user_command("AiProvider", function(opts)
    if opts.args and opts.args ~= "" then
        M.set_provider(opts.args:lower())
    else
        vim.notify("Proveedor actual: " .. active_name:upper() .. ". Usa ':AiProvider [agy|codex]' para cambiarlo.", vim.log.levels.INFO)
    end
end, {
    nargs = "?",
    complete = function() return { "agy", "codex" } end,
    desc = "Consultar o alternar el proveedor de IA activo (agy o codex)"
})

vim.api.nvim_create_user_command("AiChat", function()
    active_provider.toggle_chat()
end, { desc = "Alternar terminal flotante con el asistente de IA activo" })

vim.api.nvim_create_user_command("AiContinue", function()
    active_provider.continue_last()
end, { desc = "Continuar la última conversación de IA activa en terminal flotante" })

vim.api.nvim_create_user_command("AiHistory", function()
    active_provider.show_history()
end, { desc = "Historial y reanudación de conversaciones con Telescope" })

vim.api.nvim_create_user_command("AiExplain", function(opts)
    local code = extract_code(opts)
    active_provider.query(
        "Por favor explica el siguiente código de forma clara, detallando su propósito, entradas, salidas y puntos clave:",
        code,
        "Explicación de Código (" .. active_name:upper() .. ")"
    )
end, { range = "%", desc = "Explicar código con el proveedor activo" })

vim.api.nvim_create_user_command("AiReview", function(opts)
    local code = extract_code(opts)
    active_provider.query(
        "Realiza una auditoría exhaustiva de este código: busca posibles bugs, vulnerabilidades de seguridad, rendimiento y buenas prácticas:",
        code,
        "Revisión de Código (" .. active_name:upper() .. ")"
    )
end, { range = "%", desc = "Revisar código con el proveedor activo" })

vim.api.nvim_create_user_command("AiRefactor", function(opts)
    local code = extract_code(opts)
    vim.ui.input({ prompt = "Instrucciones de refactorización (" .. active_name:upper() .. "): " }, function(input)
        if input and input ~= "" then
            active_provider.query(
                "Refactoriza el siguiente código siguiendo estas instrucciones:\n" .. input .. "\n\nDevuelve el código refactorizado y explica brevemente los cambios:",
                code,
                "Refactorización de Código (" .. active_name:upper() .. ")"
            )
        end
    end)
end, { range = "%", desc = "Refactorizar código con el proveedor activo" })

-- ==============================================================================
-- COMANDOS Y ATAJOS ESPECÍFICOS DE ANTIGRAVITY (AGY)
-- ==============================================================================
vim.api.nvim_create_user_command("Agy", function() vim.cmd("AgyChat") end, {})
vim.api.nvim_create_user_command("AgyChat", function() providers.agy.toggle_chat() end, {})
vim.api.nvim_create_user_command("AgyContinue", function() providers.agy.continue_last() end, {})
vim.api.nvim_create_user_command("AgyResume", function() providers.agy.continue_last() end, {})
vim.api.nvim_create_user_command("AgyHistory", function() providers.agy.show_history() end, {})
vim.api.nvim_create_user_command("AgyExplain", function(opts)
    local code = extract_code(opts)
    providers.agy.query("Por favor explica el siguiente código de forma clara:", code, "Explicación (Antigravity)")
end, { range = "%" })
vim.api.nvim_create_user_command("AgyReview", function(opts)
    local code = extract_code(opts)
    providers.agy.query("Audita este código buscando bugs, seguridad y rendimiento:", code, "Revisión (Antigravity)")
end, { range = "%" })
vim.api.nvim_create_user_command("AgyRefactor", function(opts)
    local code = extract_code(opts)
    vim.ui.input({ prompt = "Instrucciones de refactorización (AGY): " }, function(input)
        if input and input ~= "" then
            providers.agy.query("Refactoriza este código:\n" .. input, code, "Refactorización (Antigravity)")
        end
    end)
end, { range = "%" })

-- ==============================================================================
-- COMANDOS Y ATAJOS ESPECÍFICOS DE OPENAI CODEX (CX)
-- ==============================================================================
vim.api.nvim_create_user_command("CodexChat", function() providers.codex.toggle_chat() end, {})
vim.api.nvim_create_user_command("CodexContinue", function() providers.codex.continue_last() end, {})
vim.api.nvim_create_user_command("CodexResume", function() providers.codex.continue_last() end, {})
vim.api.nvim_create_user_command("CodexHistory", function() providers.codex.show_history() end, {})
vim.api.nvim_create_user_command("CodexReview", function() providers.codex.review_repo() end, {})
vim.api.nvim_create_user_command("CodexDoctor", function() providers.codex.doctor() end, {})
vim.api.nvim_create_user_command("CodexApply", function(opts)
    providers.codex.apply_patch(opts.args ~= "" and opts.args or nil)
end, { nargs = "?" })
vim.api.nvim_create_user_command("CodexExplain", function(opts)
    local code = extract_code(opts)
    providers.codex.query("Por favor explica el siguiente código de forma clara:", code, "Explicación (Codex)")
end, { range = "%" })
vim.api.nvim_create_user_command("CodexRefactor", function(opts)
    local code = extract_code(opts)
    vim.ui.input({ prompt = "Instrucciones de refactorización (Codex): " }, function(input)
        if input and input ~= "" then
            providers.codex.query("Refactoriza este código:\n" .. input, code, "Refactorización (Codex)")
        end
    end)
end, { range = "%" })

-- Alias tipo PowerShell (cx...)
vim.api.nvim_create_user_command("Cx", function() vim.cmd("CodexChat") end, {})
vim.api.nvim_create_user_command("CxChat", function() vim.cmd("CodexChat") end, {})
vim.api.nvim_create_user_command("CxContinue", function() vim.cmd("CodexContinue") end, {})
vim.api.nvim_create_user_command("CxResume", function() vim.cmd("CodexResume") end, {})
vim.api.nvim_create_user_command("CxChats", function() vim.cmd("CodexHistory") end, {})
vim.api.nvim_create_user_command("CxReview", function() vim.cmd("CodexReview") end, {})
vim.api.nvim_create_user_command("CxDoctor", function() vim.cmd("CodexDoctor") end, {})
vim.api.nvim_create_user_command("CxApply", function(opts)
    providers.codex.apply_patch(opts.args ~= "" and opts.args or nil)
end, { nargs = "?" })

-- ==============================================================================
-- ATAJOS DE TECLADO (KEYMAPS)
-- ==============================================================================
local keymap = vim.keymap

-- 1. Atajos de Antigravity (<Leader>a...)
keymap.set({ "n", "t" }, "<Leader>ag", function() providers.agy.toggle_chat() end, { desc = "AGY: Alternar terminal flotante", silent = true })
keymap.set({ "n", "t" }, "<Leader>ac", function() providers.agy.continue_last() end, { desc = "AGY: Continuar última conversación", silent = true })
keymap.set("n", "<Leader>ah", function() providers.agy.show_history() end, { desc = "AGY: Historial con Telescope", silent = true })
keymap.set("n", "<Leader>ae", "<cmd>AgyExplain<CR>", { desc = "AGY: Explicar archivo completo", silent = true })
keymap.set("v", "<Leader>ae", ":AgyExplain<CR>", { desc = "AGY: Explicar selección", silent = true })
keymap.set("n", "<Leader>ar", "<cmd>AgyReview<CR>", { desc = "AGY: Revisar archivo completo", silent = true })
keymap.set("v", "<Leader>ar", ":AgyReview<CR>", { desc = "AGY: Revisar selección", silent = true })
keymap.set("n", "<Leader>af", "<cmd>AgyRefactor<CR>", { desc = "AGY: Refactorizar archivo completo", silent = true })
keymap.set("v", "<Leader>af", ":AgyRefactor<CR>", { desc = "AGY: Refactorizar selección", silent = true })

-- 2. Atajos de OpenAI Codex (<Leader>c... / <Leader>cx...)
keymap.set({ "n", "t" }, "<Leader>cx", function() providers.codex.toggle_chat() end, { desc = "Codex: Alternar terminal flotante (cx)", silent = true })
keymap.set({ "n", "t" }, "<Leader>cg", function() providers.codex.toggle_chat() end, { desc = "Codex: Alternar terminal flotante", silent = true })
keymap.set({ "n", "t" }, "<Leader>cc", function() providers.codex.continue_last() end, { desc = "Codex: Continuar última sesión (--last)", silent = true })
keymap.set("n", "<Leader>ch", function() providers.codex.show_history() end, { desc = "Codex: Historial con Telescope (VS Code / CLI)", silent = true })
keymap.set("n", "<Leader>cr", function() providers.codex.review_repo() end, { desc = "Codex: Revisión de código de repo Git", silent = true })
keymap.set("n", "<Leader>ce", "<cmd>CodexExplain<CR>", { desc = "Codex: Explicar archivo completo", silent = true })
keymap.set("v", "<Leader>ce", ":CodexExplain<CR>", { desc = "Codex: Explicar selección", silent = true })
keymap.set("n", "<Leader>cf", "<cmd>CodexRefactor<CR>", { desc = "Codex: Refactorizar archivo completo", silent = true })
keymap.set("v", "<Leader>cf", ":CodexRefactor<CR>", { desc = "Codex: Refactorizar selección", silent = true })

return M
