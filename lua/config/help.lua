local M = {}

local help_win = nil

function M.toggle_help()
  -- Si la ventana ya está abierta y válida, cerrarla (comportamiento toggle)
  if help_win and vim.api.nvim_win_is_valid(help_win) then
    vim.api.nvim_win_close(help_win, true)
    help_win = nil
    return
  end

  local lines = {
    "# ⚡ Centro de Mando: Neovim (:Nhelp / <Leader>?)",
    "> Pulsa [q], [<Esc>] o [<Leader>?] para cerrar esta ventana flotante.",
    "",
    "## 📁 Proyectos & Notas (Sinergia con Documentos)",
    "  <Leader>pp          Selector interactivo de proyectos (~/Documentos/Proyectos)",
    "  <Leader>nn          Abrir nota diaria de trabajo (~/Documentos/Notes/YYYY/MM)",
    "  <Leader>x           Alternar casilla de tarea Markdown (- [ ] <-> - [x])",
    "  :Projects           Comando: selector de proyectos en Telescope",
    "  :DailyNote          Comando: abrir nota de trabajo de hoy",
    "  :ToggleTask         Comando: alternar casilla de tarea actual",
    "",
    "## 🗄️ SQL Server Toolkit (ADO.NET)",
    "  <Leader>qq / <Leader>qe   Ejecutar consulta en split ([count]=timeout en seg)",
    "  <Leader>qo          Ejecutar pidiendo timeout por teclado con prompt",
    "  <Leader>qt          Alternar/reabrir split con resultados de última consulta",
    "  <Leader>qx          Cancelar consulta SQL en curso (:SqlCancel)",
    "  <Leader>qg          Ejecutar consulta con vista interactiva Out-GridView",
    "  <Leader>qc          Ejecutar consulta y copiar resultados al portapapeles",
    "  :SqlRun [seg]       Ejecutar consulta en split (acepta timeout/flags)",
    "  :Q <consulta>       Ejecutar consulta arbitraria en split inferior",
    "",
    "## 🐙 Git & Lazygit",
    "  <Leader>gl / :Lg    Abrir Lazygit en ventana flotante",
    "  <Leader>gg          Panel interactivo Fugitive (:Git)",
    "  <Leader>gd          Diff en split paralelo con Fugitive (:Gdiffsplit)",
    "  <Leader>gp          Push al repositorio remoto (:Git push)",
    "  <Leader>gs          Archivos modificados con Telescope (git_status)",
    "  <Leader>gc          Historial de commits con Telescope (git_commits)",
    "  <Leader>gb          Explorar ramas con Telescope (git_branches)",
    "",
    "## 🔍 Telescope (Buscador Difuso)",
    "  <Leader>tf          Buscar archivos en el proyecto (find_files)",
    "  <Leader>tg          Buscar texto en vivo en el repo con Ripgrep (live_grep)",
    "  <Leader>tb          Lista de buffers abiertos (buffers)",
    "  <Leader>th          Manual y etiquetas de ayuda oficial (help_tags)",
    "  <Leader>ts          Buscar palabra bajo el cursor (grep_string)",
    "  <Leader>tr          Reanudar última búsqueda realizada (resume)",
    "",
    "## 📂 Explorador de Archivos",
    "  <Leader><Tab>       Abrir / cerrar árbol lateral (NERDTreeToggle)",
    "  <Leader>r           Localizar archivo actual en el árbol (NERDTreeFind)",
    "",
    "## 🪟 Splits, Ventanas y Navegación",
    "  <Ctrl-h>            Mover cursor al split de la izquierda",
    "  <Ctrl-j>            Mover cursor al split de abajo",
    "  <Ctrl-k>            Mover cursor al split de arriba",
    "  <Ctrl-l>            Mover cursor al split de la derecha",
    "  <Ctrl-Left/Right>   Redimensionar split horizontalmente (+/- 10)",
    "  <Ctrl-Up/Down>      Redimensionar split verticalmente (+/- 10)",
    "  <Esc>               Limpiar resaltado de búsqueda (:nohlsearch)",
    "  <Leader>v           Volver a seleccionar el texto recién pegado",
    "",
    "## 🤖 Asistente IA (Antigravity & Codex)",
    "  :Agy                Lanzar o interactuar con Antigravity en Neovim",
    "  :Codex              Lanzar o interactuar con Codex CLI en Neovim",
  }

  -- Crear buffer temporal no listado
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"

  -- Llenar buffer y bloquear edición
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  -- Dimensiones de ventana flotante centrada
  local width = math.min(math.floor(vim.o.columns * 0.85), 84)
  local height = math.min(math.floor(vim.o.lines * 0.82), #lines + 2)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  help_win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Neovim Cheatsheet (:Nhelp) ",
    title_pos = "center",
  })

  -- Configuración de ventana
  vim.wo[help_win].cursorline = true
  vim.wo[help_win].number = false
  vim.wo[help_win].relativenumber = false
  vim.wo[help_win].signcolumn = "no"

  -- Mapeos locales al buffer para cerrar la ventana
  local close_fn = function()
    if help_win and vim.api.nvim_win_is_valid(help_win) then
      vim.api.nvim_win_close(help_win, true)
      help_win = nil
    end
  end

  local close_keys = { "q", "<Esc>", "<Leader>?" }
  for _, k in ipairs(close_keys) do
    vim.keymap.set("n", k, close_fn, { buffer = buf, silent = true, nowait = true })
  end

  -- Limpiar referencia si la ventana se cierra por cualquier otra razón
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(help_win),
    once = true,
    callback = function()
      help_win = nil
    end,
  })
end

return M
