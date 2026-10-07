local keymap = vim.keymap

-- TELESCOPE mappings
keymap.set('n', '<Leader>tf', '<cmd>Telescope find_files<cr>')
keymap.set('n', '<Leader>tg', '<cmd>Telescope live_grep<cr>')
keymap.set('n', '<Leader>tb', '<cmd>Telescope buffers<cr>')
keymap.set('n', '<Leader>th', '<cmd>Telescope help_tags<cr>')
keymap.set('n', '<Leader>ts', '<cmd>Telescope grep_string<cr>')
keymap.set('n', '<Leader>tr', '<cmd>Telescope resume<cr>')

-- PROYECTOS & NOTAS (Sinergia con Documentos\Proyectos y Notes)
keymap.set('n', '<Leader>pp', function() require('config.projects').find_projects() end, { desc = "Proyectos: Selector y cambio de directorio" })
keymap.set('n', '<Leader>nn', function() require('config.projects').open_daily_note() end, { desc = "Notas: Abrir nota diaria de trabajo" })
keymap.set('n', '<Leader>x', function() require('config.projects').toggle_markdown_task() end, { desc = "Notas: Alternar casilla de tarea [ ] / [x]" })
keymap.set('v', '<Leader>x', function()
  local s = math.min(vim.fn.line("v"), vim.fn.line("."))
  local e = math.max(vim.fn.line("v"), vim.fn.line("."))
  require('config.projects').toggle_markdown_task_range(s, e)
  vim.cmd("normal! \27")
end, { desc = "Notas: Alternar casillas de tareas seleccionadas" })
vim.api.nvim_create_user_command("Projects", function() require('config.projects').find_projects() end, { desc = "Selector de proyectos en Telescope" })
vim.api.nvim_create_user_command("DailyNote", function() require('config.projects').open_daily_note() end, { desc = "Abrir nota de trabajo diaria" })
vim.api.nvim_create_user_command("ToggleTask", function() require('config.projects').toggle_markdown_task() end, { desc = "Alternar casilla de tarea Markdown" })

-- SQL SERVER TOOLKIT (Sinergia con módulo 30-sql y motor ADO.NET)
keymap.set({ 'n', 'v' }, '<Leader>qq', function() require('config.sql').execute_sql() end, { desc = "SQL: Ejecutar consulta en split inferior" })
keymap.set({ 'n', 'v' }, '<Leader>qe', function() require('config.sql').execute_sql() end, { desc = "SQL: Ejecutar consulta en split inferior" })
keymap.set('n', '<Leader>qt', function() require('config.sql').toggle_results() end, { desc = "SQL: Alternar/reabrir split de resultados" })
keymap.set({ 'n', 'v' }, '<Leader>qg', function() require('config.sql').execute_sql("-Grid") end, { desc = "SQL: Ejecutar en ventana interactiva Out-GridView" })
keymap.set({ 'n', 'v' }, '<Leader>qc', function() require('config.sql').execute_sql("-Clip") end, { desc = "SQL: Ejecutar y copiar al portapapeles (TSV)" })
keymap.set('n', '<Leader>qx', function() require('config.sql').cancel_running_query() end, { desc = "SQL: Cancelar consulta en ejecución" })

vim.api.nvim_create_user_command("SqlRun", function() require('config.sql').execute_sql() end, { desc = "Ejecutar consulta SQL activa en split" })
vim.api.nvim_create_user_command("SqlToggle", function() require('config.sql').toggle_results() end, { desc = "Alternar/reabrir panel de resultados SQL" })
vim.api.nvim_create_user_command("SqlGrid", function() require('config.sql').execute_sql("-Grid") end, { desc = "Ejecutar SQL con Out-GridView" })
vim.api.nvim_create_user_command("SqlClip", function() require('config.sql').execute_sql("-Clip") end, { desc = "Ejecutar SQL y copiar al portapapeles" })
vim.api.nvim_create_user_command("SqlCancel", function() require('config.sql').cancel_running_query() end, { desc = "Cancelar consulta SQL en ejecución" })
vim.api.nvim_create_user_command("Q", function(opts)
  if opts.args and opts.args ~= "" then
    require('config.sql').execute_sql_string(opts.args)
  else
    require('config.sql').execute_sql()
  end
end, { nargs = "*", desc = "Ejecutar consulta SQL en split inferior" })

-- GIT MAPPINGS (Telescope Git, Fugitive & Lazygit)
keymap.set('n', '<Leader>gs', '<cmd>Telescope git_status<cr>', { desc = "Git: Archivos modificados (Telescope)" })
keymap.set('n', '<Leader>gc', '<cmd>Telescope git_commits<cr>', { desc = "Git: Historial de commits (Telescope)" })
keymap.set('n', '<Leader>gb', '<cmd>Telescope git_branches<cr>', { desc = "Git: Explorar y cambiar ramas (Telescope)" })
keymap.set('n', '<Leader>gg', '<cmd>Git<cr>', { desc = "Git: Panel interactivo Fugitive (:Git)" })
keymap.set('n', '<Leader>gd', '<cmd>Gdiffsplit<cr>', { desc = "Git: Diff en split Fugitive" })
keymap.set('n', '<Leader>gp', '<cmd>Git push<cr>', { desc = "Git: Push al repositorio remoto" })
keymap.set('n', '<Leader>gl', '<cmd>LazyGit<cr>', { desc = "Git: Abrir Lazygit flotante" })

-- Alias tipo PowerShell (lg -> LazyGit)
vim.api.nvim_create_user_command("Lg", function() vim.cmd("LazyGit") end, { desc = "Alias tipo PowerShell para LazyGit" })

-- NERDTree mappings
keymap.set('n', '<Leader><TAB>', '<cmd>NERDTreeToggle<cr>')
keymap.set('n', '<Leader>r', '<cmd>NERDTreeFind<cr>')

-- Disable shift + K
keymap.set('n', '<S-k>', '')

-- Clear search highlighting with ESC
keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = "Limpiar resaltado de busqueda", silent = true })


-- Reselect the text that has just been pasted, see also https://stackoverflow.com/a/4317090/6064933.
keymap.set("n", "<leader>v", "printf('`[%s`]', getregtype()[0])", {
  expr = true,
  desc = "reselect last pasted area",
})

-- Replace visual selection with text in register, but not contaminate the register,
-- see also https://stackoverflow.com/q/10723700/6064933.
keymap.set("x", "p", '"_c<Esc>p')

-- Move current line up and down
-- keymap.set({ "n", "v" }, "<A-j>", ':m+1<CR>==', { desc = "move line up" })
-- keymap.set({ "n", "v" }, "<A-k>", ':m-2<CR>==', { desc = "move line up" })

vim.api.nvim_set_keymap('v', '<A-j>', ":<C-U>execute 'normal! '<Down>m`>-'<CR>", { noremap = true, silent = true })

-- Map ctrl-[hjkl] to move through split
keymap.set('n', '<c-k>', ':wincmd k<CR>', { noremap = true, silent = true })
keymap.set('n', '<c-j>', ':wincmd j<CR>', { noremap = true, silent = true })
keymap.set('n', '<c-h>', ':wincmd h<CR>', { noremap = true, silent = true })
keymap.set('n', '<c-l>', ':wincmd l<CR>', { noremap = true, silent = true })

-- Expand split to the right
keymap.set('n', '<C-Right>', ':vertical resize +10<CR>', { noremap = true, silent = true })

-- Expand split downwards 
keymap.set('n', '<C-Down>', ':resize +10<CR>', { noremap = true, silent = true })

-- Expand split to the left 
keymap.set('n', '<C-Left>', ':vertical resize -10<CR>', { noremap = true, silent = true })

-- Expand split upwards 
keymap.set('n', '<C-Up>', ':resize -10<CR>', { noremap = true, silent = true })

-- AYUDA & CENTRO DE MANDO (:Nhelp / <Leader>?)
keymap.set('n', '<Leader>?', function() require('config.help').toggle_help() end, { desc = "Ayuda: Cheatsheet y centro de mando de Neovim" })
vim.api.nvim_create_user_command("Nhelp", function() require('config.help').toggle_help() end, { desc = "Centro de mando y cheatsheet de Neovim" })
vim.api.nvim_create_user_command("HelpKeymaps", function() require('config.help').toggle_help() end, { desc = "Cheatsheet de atajos de Neovim" })
